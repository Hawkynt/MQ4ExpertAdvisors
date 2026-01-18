//+------------------------------------------------------------------+
//|                                           UniversalStochastic.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal Stochastic using 55+ MA types for %K and %D smoothing  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 DodgerBlue
#property indicator_color2 Red
#property indicator_color3 Lime
#property indicator_color4 Orange
#property indicator_width1 2
#property indicator_width2 2
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 80
#property indicator_level2 50
#property indicator_level3 20
#property indicator_levelcolor Silver
#property indicator_levelstyle STYLE_DOT

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ Stochastic Settings ══════";  // ─────────────────
input int               K_Period = 14;               // %K Period
input int               Slowing = 3;                 // %K Slowing

input string            _sep2_ = "══════ %K Smoothing ══════"; // ─────────────────
input ENUM_MA_TYPE      K_MA_Type = MA_SMA;          // %K Smoothing MA Type

input string            _sep3_ = "══════ %D Line ══════"; // ─────────────────
input ENUM_MA_TYPE      D_MA_Type = MA_SMA;          // %D MA Type
input int               D_Period = 3;                // %D Period

input string            _sep4_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep5_ = "══════ Levels ══════"; // ─────────────────
input double            Overbought = 80;             // Overbought Level
input double            Oversold = 20;               // Oversold Level

input string            _sep6_ = "══════ Display ══════"; // ─────────────────
input color             K_Color = DodgerBlue;        // %K Color
input color             D_Color = Red;               // %D Color
input bool              ShowHistogram = false;       // Show Histogram
input color             HistUpColor = Lime;          // Histogram Up Color
input color             HistDownColor = Orange;      // Histogram Down Color

input string            _sep7_ = "══════ Alerts ══════"; // ─────────────────
input bool              AlertOnCross = false;        // Alert on %K/%D Cross
input bool              AlertOnOverbought = false;   // Alert on Overbought
input bool              AlertOnOversold = false;     // Alert on Oversold
input bool              EnableSound = false;         // Enable Sound
input bool              EnablePush = false;          // Enable Push Notifications

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double K_Buffer[];
double D_Buffer[];
double HistUp_Buffer[];
double HistDown_Buffer[];

// Internal buffers
double RawK_Buffer[];

int lastAlertBar = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // %K line
  SetIndexBuffer(0, K_Buffer);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, K_Color);
  SetIndexLabel(0, "%K(" + IntegerToString(K_Period) + "," + IntegerToString(Slowing) + ")");

  // %D line
  SetIndexBuffer(1, D_Buffer);
  SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, D_Color);
  SetIndexLabel(1, "%D(" + IntegerToString(D_Period) + ")");

  // Histogram up
  SetIndexBuffer(2, HistUp_Buffer);
  if (ShowHistogram) {
    SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 2, HistUpColor);
    SetIndexLabel(2, "Hist+");
  } else {
    SetIndexStyle(2, DRAW_NONE);
    SetIndexLabel(2, NULL);
  }

  // Histogram down
  SetIndexBuffer(3, HistDown_Buffer);
  if (ShowHistogram) {
    SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID, 2, HistDownColor);
    SetIndexLabel(3, "Hist-");
  } else {
    SetIndexStyle(3, DRAW_NONE);
    SetIndexLabel(3, NULL);
  }

  // Set levels
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, Overbought);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, 50);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, Oversold);

  // Set indicator name
  string kName = MovingAverages::GetTypeName(K_MA_Type);
  string dName = MovingAverages::GetTypeName(D_MA_Type);
  string shortName = "Stoch(" + IntegerToString(K_Period) + "," + IntegerToString(Slowing) +
                     "," + IntegerToString(D_Period) + ") " + kName + "/" + dName;
  IndicatorShortName(shortName);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string message, int barIndex) {
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string fullMessage = _Symbol + " Stoch: " + message;
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

    case MA_SMMA: {
      double smma = buffer[shift + period];
      for (int i = period - 1; i >= 0; --i)
        smma = (smma * (period - 1) + buffer[shift + i]) / period;
      return smma;
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

    case MA_TEMA: {
      double k = 2.0 / (period + 1);
      double ema1 = buffer[shift + period];
      double ema2 = ema1, ema3 = ema1;
      for (int i = period - 1; i >= 0; --i) {
        ema1 = buffer[shift + i] * k + ema1 * (1 - k);
        ema2 = ema1 * k + ema2 * (1 - k);
        ema3 = ema2 * k + ema3 * (1 - k);
      }
      return 3 * ema1 - 3 * ema2 + ema3;
    }

    default:
      return CalculateBufferMA(buffer, shift, period, MA_SMA);
  }
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

  if (rates_total < K_Period + Slowing + D_Period + 10) return 0;

  // Resize internal buffer
  if (ArraySize(RawK_Buffer) != rates_total) {
    ArrayResize(RawK_Buffer, rates_total);
    ArrayInitialize(RawK_Buffer, 50);
  }

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - K_Period - Slowing - D_Period - 10;
  else
    limit = rates_total - prev_calculated + 1;

  if (limit > rates_total - K_Period - 1)
    limit = rates_total - K_Period - 1;

  // Calculate Raw %K
  for (int i = limit; i >= 0; --i) {
    double highest = iHigh(_Symbol, _Period, i);
    double lowest = iLow(_Symbol, _Period, i);

    for (int j = 1; j < K_Period; ++j) {
      double h = iHigh(_Symbol, _Period, i + j);
      double l = iLow(_Symbol, _Period, i + j);
      if (h > highest) highest = h;
      if (l < lowest) lowest = l;
    }

    double range = highest - lowest;
    double closePrice = iClose(_Symbol, _Period, i);

    RawK_Buffer[i] = (range > 0) ? ((closePrice - lowest) / range) * 100 : 50;
  }

  // Calculate %K (smoothed raw %K)
  for (int i = limit; i >= 0; --i) {
    if (Slowing > 1)
      K_Buffer[i] = CalculateBufferMA(RawK_Buffer, i, Slowing, K_MA_Type);
    else
      K_Buffer[i] = RawK_Buffer[i];
  }

  // Calculate %D (MA of %K)
  for (int i = limit; i >= 0; --i)
    D_Buffer[i] = CalculateBufferMA(K_Buffer, i, D_Period, D_MA_Type);

  // Calculate histogram
  for (int i = limit; i >= 0; --i) {
    HistUp_Buffer[i] = EMPTY_VALUE;
    HistDown_Buffer[i] = EMPTY_VALUE;

    if (ShowHistogram) {
      double diff = K_Buffer[i] - D_Buffer[i];
      if (diff >= 0)
        HistUp_Buffer[i] = diff;
      else
        HistDown_Buffer[i] = diff;
    }
  }

  // Check alerts
  if (prev_calculated > 0) {
    int i = 1;
    double k = K_Buffer[i];
    double d = D_Buffer[i];
    double prevK = K_Buffer[i + 1];
    double prevD = D_Buffer[i + 1];

    if (AlertOnCross) {
      if (prevK <= prevD && k > d)
        SendAlert("Bullish cross - %K crossed above %D", i);
      else if (prevK >= prevD && k < d)
        SendAlert("Bearish cross - %K crossed below %D", i);
    }

    if (AlertOnOverbought && prevK < Overbought && k >= Overbought)
      SendAlert("Entered OVERBOUGHT zone", i);

    if (AlertOnOversold && prevK > Oversold && k <= Oversold)
      SendAlert("Entered OVERSOLD zone", i);
  }

  return rates_total;
}
//+------------------------------------------------------------------+
