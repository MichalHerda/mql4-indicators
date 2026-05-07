//+------------------------------------------------------------------+
//|                                         Kauffman_ER_MTF.mq4      |
//|                    Efficiency Ratio (Kaufman) - fixed timeframe  |
//+------------------------------------------------------------------+
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 clrNavy
#property indicator_width1 2

//--- histogram
#property indicator_type1 DRAW_HISTOGRAM

//--- input parameters
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1; // Timeframe ER
input int             InpPeriod    = 10;        // ER Period

//--- buffer
double ERBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorShortName("Kaufman Efficiency Ratio (" + EnumToString(InpTimeframe) + ")");
   
   SetIndexBuffer(0, ERBuffer);
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2, clrNavy);
   SetIndexLabel(0, "ER");

   IndicatorDigits(4);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Kaufman Efficiency Ratio                                         |
//+------------------------------------------------------------------+
double CalculateER(int shift)
{
   // shift na wybranym timeframe
   double currentClose = iClose(Symbol(), InpTimeframe, shift);
   double pastClose    = iClose(Symbol(), InpTimeframe, shift + InpPeriod);

   if(currentClose == 0 || pastClose == 0)
      return(0);

   // Direction
   double direction = MathAbs(currentClose - pastClose);

   // Volatility
   double volatility = 0.0;

   for(int i = 0; i < InpPeriod; i++)
   {
      double c1 = iClose(Symbol(), InpTimeframe, shift + i);
      double c2 = iClose(Symbol(), InpTimeframe, shift + i + 1);

      volatility += MathAbs(c1 - c2);
   }

   if(volatility == 0.0)
      return(0);

   // ER = Direction / Volatility
   return(direction / volatility);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration                                       |
//+------------------------------------------------------------------+
int OnCalculate(
   const int rates_total,
   const int prev_calculated,
   const datetime &time[],
   const double &open[],
   const double &high[],
   const double &low[],
   const double &close[],
   const long &tick_volume[],
   const long &volume[],
   const int &spread[]
)
{
   if(rates_total <= InpPeriod)
      return(0);

   int limit = rates_total - prev_calculated;

   if(prev_calculated == 0)
      limit = rates_total - 1;

   for(int i = limit; i >= 0; i--)
   {
      // mapowanie czasu aktualnego wykresu
      int tfShift = iBarShift(Symbol(), InpTimeframe, time[i], true);

      if(tfShift < 0)
      {
         ERBuffer[i] = EMPTY_VALUE;
         continue;
      }

      ERBuffer[i] = CalculateER(tfShift);
   }

   return(rates_total);
}
//+------------------------------------------------------------------+