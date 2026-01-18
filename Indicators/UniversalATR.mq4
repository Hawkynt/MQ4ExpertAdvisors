//+------------------------------------------------------------------+
//|                                                   UniversalATR.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal ATR using 55+ MA types for smoothing                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 DodgerBlue
#property indicator_color2 Lime
#property indicator_color3 Yellow
#property indicator_color4 Red
#property indicator_width1 2
#property indicator_width2 1
#property indicator_width3 1
#property indicator_minimum 0

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ ATR Settings ══════";  // ─────────────────
input int               ATR_Period = 14;             // ATR Period

input string            _sep2_ = "══════ Smoothing ══════"; // ─────────────────
input ENUM_MA_TYPE      MA_Type = MA_SMMA;           // Smoothing MA Type (Wilder=SMMA)

input string            _sep3_ = "══════ Signal Line ══════"; // ─────────────────
input bool              ShowSignal = false;          // Show Signal Line (MA of ATR)
input ENUM_MA_TYPE      Signal_Type = MA_EMA;        // Signal MA Type
input int               Signal_Period = 9;           // Signal Period

input string            _sep4_ = "══════ ATR Bands (Chart) ══════"; // ─────────────────
input bool              ShowBandsOnChart = false;    // Show ATR Bands on Chart
input double            BandMultiplier = 1.5;        // Band Multiplier
input color             UpperBandColor = Lime;       // Upper Band Color
input color             LowerBandColor = Red;        // Lower Band Color

input string            _sep5_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep6_ = "══════ Display ══════"; // ─────────────────
input bool              ShowAsPercent = false;       // Show ATR as Percentage
input bool              ShowAsPips = true;           // Show ATR in Pips
input color             ATR_Color = DodgerBlue;      // ATR Color

input string            _sep7_ = "══════ Alerts ══════"; // ─────────────────
input bool              AlertOnHighVolatility = false; // Alert on High Volatility
input double            HighVolatilityThreshold = 0; // High Volatility Threshold (0=auto)
input bool              EnableSound = false;         // Enable Sound
input bool              EnablePush = false;          // Enable Push Notifications

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double ATR_Buffer[];
double Signal_Buffer[];
double UpperBand_Buffer[];
double LowerBand_Buffer[];

// Internal buffer
double TR_Buffer[];

int lastAlertBar = -1;
double avgATR = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // ATR line
  SetIndexBuffer(0, ATR_Buffer);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, ATR_Color);
  SetIndexLabel(0, "ATR(" + IntegerToString(ATR_Period) + ")");

  // Signal line
  SetIndexBuffer(1, Signal_Buffer);
  if (ShowSignal) {
    SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, Lime);
    SetIndexLabel(1, "Signal(" + IntegerToString(Signal_Period) + ")");
  } else {
    SetIndexStyle(1, DRAW_NONE);
    SetIndexLabel(1, NULL);
  }

  // ATR bands (in separate window, just for data)
  SetIndexBuffer(2, UpperBand_Buffer);
  SetIndexStyle(2, DRAW_NONE);
  SetIndexLabel(2, "Upper Band");

  SetIndexBuffer(3, LowerBand_Buffer);
  SetIndexStyle(3, DRAW_NONE);
  SetIndexLabel(3, "Lower Band");

  // Set indicator name
  string maName = MovingAverages::GetTypeName(MA_Type);
  string shortName = "ATR(" + IntegerToString(ATR_Period) + "," + maName + ")";
  if (ShowAsPips) shortName += " [pips]";
  if (ShowAsPercent) shortName += " [%]";
  IndicatorShortName(shortName);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  // Delete chart bands if created
  for (int i = ObjectsTotal() - 1; i >= 0; --i) {
    string name = ObjectName(i);
    if (StringFind(name, "UATR_Band_") >= 0)
      ObjectDelete(name);
  }
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string message, int barIndex) {
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string fullMessage = _Symbol + " ATR: " + message;
  Alert(fullMessage);

  if (EnableSound)
    PlaySound("alert.wav");

  if (EnablePush)
    SendNotification(fullMessage);
}

//+------------------------------------------------------------------+
//| Calculate MA of buffer values                                     |
//+------------------------------------------------------------------+
double CalculateBufferMA(double &buffer[], int shift, int period, ENUM_MA_TYPE maType) {
  switch (maType) {
    case MA_SMA: {
      double sum = 0;
      for (int i = 0; i < period; ++i)
        sum += buffer[shift + i];
      return sum / period;
    }

    case MA_EMA: {
      double k = 2.0 / (period + 1);
      double ema = buffer[shift + period];
      for (int i = period - 1; i >= 0; --i)
        ema = buffer[shift + i] * k + ema * (1 - k);
      return ema;
    }

    case MA_SMMA: {
      // Wilder's smoothing (default for ATR)
      double smma = buffer[shift + period];
      for (int i = period - 1; i >= 0; --i)
        smma = (smma * (period - 1) + buffer[shift + i]) / period;
      return smma;
    }

    case MA_WMA: {
      double sum = 0;
      double weightSum = 0;
      for (int i = 0; i < period; ++i) {
        double weight = period - i;
        sum += buffer[shift + i] * weight;
        weightSum += weight;
      }
      return (weightSum > 0) ? sum / weightSum : 0;
    }

    case MA_DEMA: {
      double k = 2.0 / (period + 1);
      double ema1 = buffer[shift + period];
      double ema2 = ema1;
      for (int i = period - 1; i >= 0; --i) {
        ema1 = buffer[shift + i] * k + ema1 * (1 - k);
        ema2 = ema1 * k + ema2 * (1 - k);
      }
      return 2 * ema1 - ema2;
    }

    default:
      return CalculateBufferMA(buffer, shift, period, MA_SMMA);
  }
}

//+------------------------------------------------------------------+
//| Draw ATR bands on chart                                           |
//+------------------------------------------------------------------+
void DrawBandsOnChart(int shift, datetime time, double atr) {
  if (!ShowBandsOnChart) return;

  double closePrice = iClose(_Symbol, _Period, shift);
  double upperBand = closePrice + BandMultiplier * atr;
  double lowerBand = closePrice - BandMultiplier * atr;

  UpperBand_Buffer[shift] = upperBand;
  LowerBand_Buffer[shift] = lowerBand;
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

  if (rates_total < ATR_Period + Signal_Period + 10) return 0;

  // Resize internal buffer
  if (ArraySize(TR_Buffer) != rates_total) {
    ArrayResize(TR_Buffer, rates_total);
    ArrayInitialize(TR_Buffer, 0);
  }

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - 2;
  else
    limit = rates_total - prev_calculated + 1;

  double pipValue = _Point * 10;
  if (_Digits == 3 || _Digits == 5)
    pipValue = _Point * 10;
  else
    pipValue = _Point;

  // Calculate True Range
  for (int i = limit; i >= 0; --i) {
    double high_val = iHigh(_Symbol, _Period, i);
    double low_val = iLow(_Symbol, _Period, i);
    double prevClose = iClose(_Symbol, _Period, i + 1);

    double tr1 = high_val - low_val;
    double tr2 = MathAbs(high_val - prevClose);
    double tr3 = MathAbs(low_val - prevClose);

    TR_Buffer[i] = MathMax(tr1, MathMax(tr2, tr3));
  }

  // Calculate ATR
  for (int i = limit; i >= 0; --i) {
    if (i > rates_total - ATR_Period - 10) {
      ATR_Buffer[i] = TR_Buffer[i];
      continue;
    }

    double atr = CalculateBufferMA(TR_Buffer, i, ATR_Period, MA_Type);

    // Convert to pips or percentage if requested
    if (ShowAsPips)
      ATR_Buffer[i] = atr / pipValue;
    else if (ShowAsPercent) {
      double price = iClose(_Symbol, _Period, i);
      ATR_Buffer[i] = (price > 0) ? (atr / price) * 100 : 0;
    } else
      ATR_Buffer[i] = atr;

    // Draw bands
    DrawBandsOnChart(i, time[i], atr);
  }

  // Calculate Signal line
  if (ShowSignal) {
    for (int i = limit; i >= 0; --i) {
      if (i > rates_total - ATR_Period - Signal_Period - 10) {
        Signal_Buffer[i] = ATR_Buffer[i];
        continue;
      }
      Signal_Buffer[i] = CalculateBufferMA(ATR_Buffer, i, Signal_Period, Signal_Type);
    }
  }

  // Calculate average ATR for threshold
  if (prev_calculated == 0 || avgATR == 0) {
    double sum = 0;
    int count = MathMin(100, rates_total - ATR_Period - 10);
    for (int i = 0; i < count; ++i)
      sum += ATR_Buffer[i];
    avgATR = sum / count;
  }

  // Check alerts
  if (AlertOnHighVolatility && prev_calculated > 0) {
    int i = 1;
    double threshold = (HighVolatilityThreshold > 0) ? HighVolatilityThreshold : avgATR * 1.5;

    if (ATR_Buffer[i] >= threshold && ATR_Buffer[i + 1] < threshold)
      SendAlert("HIGH VOLATILITY detected (ATR: " + DoubleToStr(ATR_Buffer[i], 1) + ")", i);
  }

  return rates_total;
}
//+------------------------------------------------------------------+
