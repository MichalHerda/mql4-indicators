#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 DeepSkyBlue
#property indicator_color2 Orange
#property indicator_width1 2
#property indicator_width2 2

//====================================================
// Inputs
//====================================================

input int MA_Period = 50;
input int ATR_Period = 500;
input int Delta_Bars = 3;

input double Delta_Threshold = 1.5;

input color Normal_Color = DeepSkyBlue;
input color Extreme_Color = Orange;

input ENUM_MA_METHOD MA_Method = MODE_EMA;
input int Applied_Price = PRICE_CLOSE;

//====================================================
// Buffers
//====================================================

double NormalBuffer[];
double ExtremeBuffer[];

//====================================================
// Init
//====================================================

int OnInit()
{
    // Normal bars
   SetIndexBuffer(0, NormalBuffer);
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2, Normal_Color);
   SetIndexLabel(0, "Delta ZScore Normal");

   // Extreme bars
   SetIndexBuffer(1, ExtremeBuffer);
   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 2, Extreme_Color);
   SetIndexLabel(1, "Delta ZScore Extreme");

   IndicatorShortName("Delta ZScore ATR");

   // Zero line
   IndicatorSetInteger(INDICATOR_LEVELS, 1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0.0);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrGray);

   return(INIT_SUCCEEDED);
}

//====================================================
// Main
//====================================================

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
   int min_bars = MathMax(MA_Period, ATR_Period) + Delta_Bars;

   if(rates_total <= min_bars)
      return(0);

   int start;

   if(prev_calculated == 0)
      start = rates_total - min_bars;
   else
      start = rates_total - prev_calculated;

   if(start > rates_total - min_bars)
      start = rates_total - min_bars;

   //====================================================
   // Calculation
   //====================================================

   for(int i = start; i >= 0; i--)
   {
      NormalBuffer[i] = EMPTY_VALUE;
      ExtremeBuffer[i] = EMPTY_VALUE;

      // Current Z-score
      double ma_current = iMA(NULL, 0, MA_Period, 0, MA_Method, Applied_Price, i);
      double atr_current = iATR(NULL, 0, ATR_Period, i);

      double z_current = 0;

      if(atr_current != 0)
         z_current = (close[i] - ma_current) / atr_current;

      // Past Z-score
      int past_index = i + Delta_Bars;

      double ma_past = iMA(NULL, 0, MA_Period, 0, MA_Method, Applied_Price, past_index);
      double atr_past = iATR(NULL, 0, ATR_Period, past_index);

      double z_past = 0;

      if(atr_past != 0)
         z_past = (close[past_index] - ma_past) / atr_past;

      // Delta Z-score
      double delta_z = z_current - z_past;

      //====================================================
      // Threshold coloring
      //====================================================

      if(MathAbs(delta_z) >= Delta_Threshold)
         ExtremeBuffer[i] = delta_z;
      else
         NormalBuffer[i] = delta_z;
   }

   return(rates_total);
}