//+------------------------------------------------------------------+
//|                                       UniversalBollingerBands.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal Bollinger Bands using 55+ MA types for middle band     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_color1 DodgerBlue
#property indicator_color2 LimeGreen
#property indicator_color3 Red
#property indicator_color4 Silver
#property indicator_color5 Silver
#property indicator_color6 Aqua
#property indicator_color7 Aqua
#property indicator_width1 2
#property indicator_width2 1
#property indicator_width3 1
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
#property indicator_style4 STYLE_DOT
#property indicator_style5 STYLE_DOT

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ Middle Band (MA) ══════";  // ─────────────────
input ENUM_MA_TYPE      MA_Type = MA_SMA;            // MA Type
input int               MA_Period = 20;              // Period
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE;    // Applied Price

input string            _sep2_ = "══════ Bands ══════"; // ─────────────────
input double            Deviation = 2.0;             // Standard Deviation Multiplier
input double            Deviation2 = 0;              // Second Deviation (0=disabled)
input bool              ShowMiddle = true;           // Show Middle Band

input string            _sep3_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep4_ = "══════ Display ══════"; // ─────────────────
input color             MiddleColor = DodgerBlue;    // Middle Band Color
input color             UpperColor = LimeGreen;      // Upper Band Color
input color             LowerColor = Red;            // Lower Band Color
input color             Band2Color = Silver;         // Second Band Color
input bool              FillBands = false;           // Fill Between Bands

input string            _sep5_ = "══════ Alerts ══════"; // ─────────────────
input bool              AlertOnBandTouch = false;    // Alert on Band Touch
input bool              AlertOnBandBreak = false;    // Alert on Band Break
input bool              EnableSound = false;         // Enable Sound
input bool              EnablePush = false;          // Enable Push Notifications

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double Middle_Buffer[];
double Upper_Buffer[];
double Lower_Buffer[];
double Upper2_Buffer[];
double Lower2_Buffer[];
double BandWidth_Buffer[];
double PercentB_Buffer[];

int lastAlertBar = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // Middle band
  SetIndexBuffer(0, Middle_Buffer);
  if (ShowMiddle) {
    SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, MiddleColor);
    SetIndexLabel(0, MovingAverages::GetTypeName(MA_Type) + "(" + IntegerToString(MA_Period) + ")");
  } else {
    SetIndexStyle(0, DRAW_NONE);
    SetIndexLabel(0, NULL);
  }

  // Upper band
  SetIndexBuffer(1, Upper_Buffer);
  SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, UpperColor);
  SetIndexLabel(1, "Upper(" + DoubleToStr(Deviation, 1) + ")");

  // Lower band
  SetIndexBuffer(2, Lower_Buffer);
  SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, LowerColor);
  SetIndexLabel(2, "Lower(" + DoubleToStr(Deviation, 1) + ")");

  // Second upper band
  SetIndexBuffer(3, Upper2_Buffer);
  if (Deviation2 > 0) {
    SetIndexStyle(3, DRAW_LINE, STYLE_DOT, 1, Band2Color);
    SetIndexLabel(3, "Upper(" + DoubleToStr(Deviation2, 1) + ")");
  } else {
    SetIndexStyle(3, DRAW_NONE);
    SetIndexLabel(3, NULL);
  }

  // Second lower band
  SetIndexBuffer(4, Lower2_Buffer);
  if (Deviation2 > 0) {
    SetIndexStyle(4, DRAW_LINE, STYLE_DOT, 1, Band2Color);
    SetIndexLabel(4, "Lower(" + DoubleToStr(Deviation2, 1) + ")");
  } else {
    SetIndexStyle(4, DRAW_NONE);
    SetIndexLabel(4, NULL);
  }

  // Bandwidth (for data window)
  SetIndexBuffer(5, BandWidth_Buffer);
  SetIndexStyle(5, DRAW_NONE);
  SetIndexLabel(5, "BandWidth");

  // %B (for data window)
  SetIndexBuffer(6, PercentB_Buffer);
  SetIndexStyle(6, DRAW_NONE);
  SetIndexLabel(6, "%B");

  // Set indicator name
  string shortName = "BB(" + MovingAverages::GetTypeName(MA_Type) + "," +
                     IntegerToString(MA_Period) + "," + DoubleToStr(Deviation, 1) + ")";
  IndicatorShortName(shortName);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                      |
//+------------------------------------------------------------------+
double CalculateStdDev(const string symbol, const int timeframe, const int period,
                       const int shift, const int priceType, const double ma) {
  double sumSq = 0;

  for (int i = 0; i < period; ++i) {
    double price = MovingAverages::GetPrice(symbol, timeframe, priceType, shift + i);
    double diff = price - ma;
    sumSq += diff * diff;
  }

  return MathSqrt(sumSq / period);
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string message, int barIndex) {
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string fullMessage = _Symbol + " BB: " + message;
  Alert(fullMessage);

  if (EnableSound)
    PlaySound("alert.wav");

  if (EnablePush)
    SendNotification(fullMessage);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
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
                const int &spread[]) {

  if (rates_total < MA_Period + 1) return 0;

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - MA_Period - 1;
  else
    limit = rates_total - prev_calculated + 1;

  if (limit > rates_total - MA_Period - 1)
    limit = rates_total - MA_Period - 1;

  for (int i = limit; i >= 0; --i) {
    // Calculate middle band using selected MA type
    double ma = MovingAverages::Calculate(
      MA_Type, _Symbol, _Period, MA_Period, i, MA_Price, OptParam1, OptParam2
    );

    // Calculate standard deviation
    double stdDev = CalculateStdDev(_Symbol, _Period, MA_Period, i, MA_Price, ma);

    Middle_Buffer[i] = ma;
    Upper_Buffer[i] = ma + Deviation * stdDev;
    Lower_Buffer[i] = ma - Deviation * stdDev;

    // Second bands if enabled
    if (Deviation2 > 0) {
      Upper2_Buffer[i] = ma + Deviation2 * stdDev;
      Lower2_Buffer[i] = ma - Deviation2 * stdDev;
    } else {
      Upper2_Buffer[i] = EMPTY_VALUE;
      Lower2_Buffer[i] = EMPTY_VALUE;
    }

    // Calculate BandWidth and %B
    double bandWidth = Upper_Buffer[i] - Lower_Buffer[i];
    BandWidth_Buffer[i] = (ma > 0) ? bandWidth / ma * 100 : 0;

    double price = MovingAverages::GetPrice(_Symbol, _Period, MA_Price, i);
    PercentB_Buffer[i] = (bandWidth > 0) ? (price - Lower_Buffer[i]) / bandWidth * 100 : 50;

    // Check for alerts
    if (i == 1 && prev_calculated > 0) {
      double closePrice = iClose(_Symbol, _Period, i);
      double prevClose = iClose(_Symbol, _Period, i + 1);

      if (AlertOnBandTouch) {
        if (closePrice >= Upper_Buffer[i] && prevClose < Upper_Buffer[i + 1])
          SendAlert("Price touched UPPER band", i);
        else if (closePrice <= Lower_Buffer[i] && prevClose > Lower_Buffer[i + 1])
          SendAlert("Price touched LOWER band", i);
      }

      if (AlertOnBandBreak) {
        if (closePrice > Upper_Buffer[i] && prevClose <= Upper_Buffer[i + 1])
          SendAlert("Price BROKE ABOVE upper band", i);
        else if (closePrice < Lower_Buffer[i] && prevClose >= Lower_Buffer[i + 1])
          SendAlert("Price BROKE BELOW lower band", i);
      }
    }
  }

  return rates_total;
}
//+------------------------------------------------------------------+
