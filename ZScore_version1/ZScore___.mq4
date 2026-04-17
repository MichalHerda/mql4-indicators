#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 White
#property indicator_width1 2

//---- input parameters
input int MA_Period = 50;
input int ATR_Period = 24;
input int MA_Method = MODE_EMA; // MODE_SMA, MODE_EMA, MODE_SMMA, MODE_LWMA
input int Applied_Price = PRICE_CLOSE;

//---- buffer
double DeviationBuffer[];

//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, DeviationBuffer);
   SetIndexStyle(0, DRAW_LINE);
   SetIndexLabel(0, "EMA Deviation (ATR normalized)");

   IndicatorShortName("EMA Deviation / ATR");

   // poziom 0
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
   int start = MathMax(MA_Period, ATR_Period);

   for(int i = start; i < rates_total; i++)
   {
      double ma = iMA(NULL, 0, MA_Period, 0, MA_Method, Applied_Price, i);
      double atr = iATR(NULL, 0, ATR_Period, i);

      if(atr != 0)
         DeviationBuffer[i] = (close[i] - ma) / atr;
      else
         DeviationBuffer[i] = 0;
   }

   return(rates_total);
}