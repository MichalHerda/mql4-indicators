#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Green
#property indicator_color2 Orange
#property indicator_width1 2
#property indicator_width2 2

input int    MA_Period    = 50;
input int    ATR_Period   = 500;
input ENUM_MA_METHOD MA_Method     = MODE_EMA;
input int    Applied_Price = PRICE_CLOSE;
input double ZScoreLimit  = 5.0;

double DeviationBuffer[];
double LimitBuffer[];

//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, DeviationBuffer);
   SetIndexStyle(0, DRAW_HISTOGRAM);
   SetIndexLabel(0, "ZScore normal");

   SetIndexBuffer(1, LimitBuffer);
   SetIndexStyle(1, DRAW_HISTOGRAM);
   SetIndexLabel(1, "ZScore limit");

   IndicatorShortName("ZScoreLimit (ATR)");

   IndicatorSetInteger(INDICATOR_LEVELS, 1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0.0);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrGray);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int min_bars = MathMax(MA_Period, ATR_Period);
   if(rates_total <= min_bars)
      return(0);

   int start;
   if(prev_calculated == 0)
      start = rates_total - min_bars;
   else
      start = rates_total - prev_calculated;

   if(start > rates_total - min_bars)
      start = rates_total - min_bars;

   for(int i = start; i >= 0; i--)
   {
      double ma  = iMA(NULL, 0, MA_Period, 0, MA_Method, Applied_Price, i);
      double atr = iATR(NULL, 0, ATR_Period, i);
      double zscore = 0;

      if(atr != 0)
         zscore = (close[i] - ma) / atr;

      if(MathAbs(zscore) > ZScoreLimit)
      {
         LimitBuffer[i]     = zscore;
         DeviationBuffer[i] = EMPTY_VALUE;
      }
      else
      {
         DeviationBuffer[i] = zscore;
         LimitBuffer[i]     = EMPTY_VALUE;
      }
   }

   return(rates_total);
}