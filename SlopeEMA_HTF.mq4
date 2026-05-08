//+------------------------------------------------------------------+
//|                    HTF_TrendStrength.mq4                         |
//|         Higher Timeframe Normalized Slope Regime Filter          |
//+------------------------------------------------------------------+
#property strict
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4

//--- UP
#property indicator_label1  "UP"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrLime
#property indicator_width1  3

//--- DOWN
#property indicator_label2  "DOWN"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrTomato
#property indicator_width2  3

//--- RANGE
#property indicator_label3  "RANGE"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrGray
#property indicator_width3  2

//--- SIGNAL
#property indicator_label4  "SIGNAL"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrWhite
#property indicator_width4  1

//====================================================
// INPUTS
//====================================================

input ENUM_TIMEFRAMES SourceTF = PERIOD_H1;

input ENUM_MA_METHOD MA_Method = MODE_EMA;
input int            MA_Period = 200;

input int            SlopePeriod = 20;
input int            ATR_Period = 14;
input int            SmoothPeriod = 5;

input double         TrendThreshold = 0.25;

input ENUM_APPLIED_PRICE PriceType = PRICE_CLOSE;

//====================================================
// BUFFERS
//====================================================

double UpBuffer[];
double DownBuffer[];
double RangeBuffer[];
double SignalBuffer[];

//====================================================
// INIT
//====================================================

int OnInit()
{
   IndicatorShortName("HTF TrendStrength");

   SetIndexBuffer(0, UpBuffer);
   SetIndexBuffer(1, DownBuffer);
   SetIndexBuffer(2, RangeBuffer);
   SetIndexBuffer(3, SignalBuffer);

   ArraySetAsSeries(UpBuffer, true);
   ArraySetAsSeries(DownBuffer, true);
   ArraySetAsSeries(RangeBuffer, true);
   ArraySetAsSeries(SignalBuffer, true);

   SetLevelValue(0, TrendThreshold);
   SetLevelValue(1, -TrendThreshold);

   return(INIT_SUCCEEDED);
}

//====================================================
// CALC
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
   int start = rates_total - prev_calculated;

   if(prev_calculated == 0)
      start = rates_total - 1;

   for(int i = start; i >= 0; i--)
   {
      //------------------------------------------------
      // MAP CURRENT BAR -> HTF BAR
      //------------------------------------------------

      int htfShift = iBarShift(
                        NULL,
                        SourceTF,
                        time[i],
                        false);

      if(htfShift < 0)
         continue;

      //------------------------------------------------
      // USE ONLY CLOSED HTF BAR
      //------------------------------------------------

      htfShift += 1;

      //------------------------------------------------
      // COLLECT MA VALUES
      //------------------------------------------------

      double maValues[];
      ArrayResize(maValues, SlopePeriod);

      bool valid = true;

      for(int k = 0; k < SlopePeriod; k++)
      {
         int shift = htfShift + k;

         double ma =
            iMA(NULL,
                SourceTF,
                MA_Period,
                0,
                MA_Method,
                PriceType,
                shift);

         if(ma == EMPTY_VALUE || ma == 0)
         {
            valid = false;
            break;
         }

         maValues[k] = ma;
      }

      if(!valid)
         continue;

      //------------------------------------------------
      // SLOPE
      //------------------------------------------------

      double slope = CalcSlope(maValues, SlopePeriod);

      //------------------------------------------------
      // ATR NORMALIZATION
      //------------------------------------------------

      double atr =
         iATR(NULL,
              SourceTF,
              ATR_Period,
              htfShift);

      if(atr > 0)
         slope = slope / atr;
      else
         slope = 0;

      //------------------------------------------------
      // SCALE
      //------------------------------------------------

      slope *= 100.0;

      //------------------------------------------------
      // SMOOTHING
      //------------------------------------------------

      SignalBuffer[i] = slope;

      //------------------------------------------------
      // RESET
      //------------------------------------------------

      UpBuffer[i] = EMPTY_VALUE;
      DownBuffer[i] = EMPTY_VALUE;
      RangeBuffer[i] = EMPTY_VALUE;

      //------------------------------------------------
      // REGIME DETECTION
      //------------------------------------------------

      if(MathAbs(slope) < TrendThreshold)
      {
         RangeBuffer[i] = slope;
      }
      else if(slope > 0)
      {
         UpBuffer[i] = slope;
      }
      else
      {
         DownBuffer[i] = slope;
      }
   }

   return(rates_total);
}

//====================================================
// LINEAR REGRESSION SLOPE
//====================================================

double CalcSlope(double &values[], int n)
{
   double sumX = 0;
   double sumY = 0;
   double sumXY = 0;
   double sumX2 = 0;

   for(int i = 0; i < n; i++)
   {
      double x = i;
      double y = values[n - 1 - i];

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
   }

   double denominator =
      n * sumX2 - sumX * sumX;

   if(denominator == 0)
      return(0);

   return(
      (n * sumXY - sumX * sumY)
      / denominator
   );
}
//+------------------------------------------------------------------+