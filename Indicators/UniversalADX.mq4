//+------------------------------------------------------------------+
//|                                                   UniversalADX.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal ADX using 55+ MA types for smoothing                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1 DodgerBlue
#property indicator_color2 Lime
#property indicator_color3 Red
#property indicator_color4 Yellow
#property indicator_color5 Magenta
#property indicator_width1 2
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 25
#property indicator_level2 50
#property indicator_levelcolor Silver
#property indicator_levelstyle STYLE_DOT

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ ADX Settings ══════";  // ─────────────────
input int               ADX_Period = 14;             // ADX Period

input string            _sep2_ = "══════ Smoothing ══════"; // ─────────────────
input ENUM_MA_TYPE      MA_Type = MA_SMMA;           // Smoothing MA Type (Wilder=SMMA)

input string            _sep3_ = "══════ Signal Line ══════"; // ─────────────────
input bool              ShowSignal = false;          // Show ADX Signal Line
input ENUM_MA_TYPE      Signal_Type = MA_EMA;        // Signal MA Type
input int               Signal_Period = 9;           // Signal Period

input string            _sep4_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep5_ = "══════ Display ══════"; // ─────────────────
input bool              ShowDIPlus = true;           // Show +DI
input bool              ShowDIMinus = true;          // Show -DI
input color             ADX_Color = DodgerBlue;      // ADX Color
input color             DIPlus_Color = Lime;         // +DI Color
input color             DIMinus_Color = Red;         // -DI Color

input string            _sep6_ = "══════ Levels ══════"; // ─────────────────
input double            WeakTrend = 25;              // Weak Trend Threshold
input double            StrongTrend = 50;            // Strong Trend Threshold

input string            _sep7_ = "══════ Alerts ══════"; // ─────────────────
input bool              AlertOnDICross = false;      // Alert on +DI/-DI Cross
input bool              AlertOnTrendChange = false;  // Alert on Trend Strength Change
input bool              EnableSound = false;         // Enable Sound
input bool              EnablePush = false;          // Enable Push Notifications

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double ADX_Buffer[];
double DIPlus_Buffer[];
double DIMinus_Buffer[];
double Signal_Buffer[];
double DX_Buffer[];

// Internal buffers
double PlusDM_Buffer[];
double MinusDM_Buffer[];
double TR_Buffer[];

int lastAlertBar = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // ADX line
  SetIndexBuffer(0, ADX_Buffer);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, ADX_Color);
  SetIndexLabel(0, "ADX(" + IntegerToString(ADX_Period) + ")");

  // +DI line
  SetIndexBuffer(1, DIPlus_Buffer);
  if (ShowDIPlus) {
    SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, DIPlus_Color);
    SetIndexLabel(1, "+DI");
  } else {
    SetIndexStyle(1, DRAW_NONE);
    SetIndexLabel(1, NULL);
  }

  // -DI line
  SetIndexBuffer(2, DIMinus_Buffer);
  if (ShowDIMinus) {
    SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, DIMinus_Color);
    SetIndexLabel(2, "-DI");
  } else {
    SetIndexStyle(2, DRAW_NONE);
    SetIndexLabel(2, NULL);
  }

  // Signal line
  SetIndexBuffer(3, Signal_Buffer);
  if (ShowSignal) {
    SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 1, Yellow);
    SetIndexLabel(3, "Signal(" + IntegerToString(Signal_Period) + ")");
  } else {
    SetIndexStyle(3, DRAW_NONE);
    SetIndexLabel(3, NULL);
  }

  // DX buffer (internal, for data window)
  SetIndexBuffer(4, DX_Buffer);
  SetIndexStyle(4, DRAW_NONE);
  SetIndexLabel(4, "DX");

  // Set levels
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, WeakTrend);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, StrongTrend);

  // Set indicator name
  string maName = MovingAverages::GetTypeName(MA_Type);
  string shortName = "ADX(" + IntegerToString(ADX_Period) + "," + maName + ")";
  IndicatorShortName(shortName);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string message, int barIndex) {
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string fullMessage = _Symbol + " ADX: " + message;
  Alert(fullMessage);

  if (EnableSound)
    PlaySound("alert.wav");

  if (EnablePush)
    SendNotification(fullMessage);
}

//+------------------------------------------------------------------+
//| Calculate smoothed MA of buffer                                   |
//+------------------------------------------------------------------+
double CalculateSmoothedMA(double &buffer[], int shift, int period, ENUM_MA_TYPE maType) {
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
      // Wilder's smoothing (default for ADX)
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
      return CalculateSmoothedMA(buffer, shift, period, MA_SMMA);
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

  if (rates_total < ADX_Period * 2 + Signal_Period + 10) return 0;

  // Resize internal buffers
  if (ArraySize(PlusDM_Buffer) != rates_total) {
    ArrayResize(PlusDM_Buffer, rates_total);
    ArrayResize(MinusDM_Buffer, rates_total);
    ArrayResize(TR_Buffer, rates_total);
    ArrayInitialize(PlusDM_Buffer, 0);
    ArrayInitialize(MinusDM_Buffer, 0);
    ArrayInitialize(TR_Buffer, 0);
  }

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - 2;
  else
    limit = rates_total - prev_calculated + 1;

  // Calculate +DM, -DM, and True Range
  for (int i = limit; i >= 0; --i) {
    double high_val = iHigh(_Symbol, _Period, i);
    double low_val = iLow(_Symbol, _Period, i);
    double prevHigh = iHigh(_Symbol, _Period, i + 1);
    double prevLow = iLow(_Symbol, _Period, i + 1);
    double prevClose = iClose(_Symbol, _Period, i + 1);

    // Directional Movement
    double plusDM = high_val - prevHigh;
    double minusDM = prevLow - low_val;

    if (plusDM < 0) plusDM = 0;
    if (minusDM < 0) minusDM = 0;

    if (plusDM > minusDM)
      minusDM = 0;
    else if (minusDM > plusDM)
      plusDM = 0;
    else {
      plusDM = 0;
      minusDM = 0;
    }

    PlusDM_Buffer[i] = plusDM;
    MinusDM_Buffer[i] = minusDM;

    // True Range
    double tr1 = high_val - low_val;
    double tr2 = MathAbs(high_val - prevClose);
    double tr3 = MathAbs(low_val - prevClose);
    TR_Buffer[i] = MathMax(tr1, MathMax(tr2, tr3));
  }

  // Calculate smoothed values and DI
  for (int i = limit; i >= 0; --i) {
    if (i > rates_total - ADX_Period - 10) {
      DIPlus_Buffer[i] = 0;
      DIMinus_Buffer[i] = 0;
      DX_Buffer[i] = 0;
      ADX_Buffer[i] = 0;
      continue;
    }

    double smoothedPlusDM = CalculateSmoothedMA(PlusDM_Buffer, i, ADX_Period, MA_Type);
    double smoothedMinusDM = CalculateSmoothedMA(MinusDM_Buffer, i, ADX_Period, MA_Type);
    double smoothedTR = CalculateSmoothedMA(TR_Buffer, i, ADX_Period, MA_Type);

    // Calculate +DI and -DI
    DIPlus_Buffer[i] = (smoothedTR > 0) ? (smoothedPlusDM / smoothedTR) * 100 : 0;
    DIMinus_Buffer[i] = (smoothedTR > 0) ? (smoothedMinusDM / smoothedTR) * 100 : 0;

    // Calculate DX
    double diSum = DIPlus_Buffer[i] + DIMinus_Buffer[i];
    double diDiff = MathAbs(DIPlus_Buffer[i] - DIMinus_Buffer[i]);
    DX_Buffer[i] = (diSum > 0) ? (diDiff / diSum) * 100 : 0;
  }

  // Calculate ADX (smoothed DX)
  for (int i = limit; i >= 0; --i) {
    if (i > rates_total - ADX_Period * 2 - 10) {
      ADX_Buffer[i] = DX_Buffer[i];
      continue;
    }

    ADX_Buffer[i] = CalculateSmoothedMA(DX_Buffer, i, ADX_Period, MA_Type);
  }

  // Calculate Signal line
  if (ShowSignal) {
    for (int i = limit; i >= 0; --i) {
      if (i > rates_total - ADX_Period * 2 - Signal_Period - 10) {
        Signal_Buffer[i] = ADX_Buffer[i];
        continue;
      }
      Signal_Buffer[i] = CalculateSmoothedMA(ADX_Buffer, i, Signal_Period, Signal_Type);
    }
  }

  // Check alerts
  if (prev_calculated > 0) {
    int i = 1;

    if (AlertOnDICross) {
      double diPlus = DIPlus_Buffer[i];
      double diMinus = DIMinus_Buffer[i];
      double prevDIPlus = DIPlus_Buffer[i + 1];
      double prevDIMinus = DIMinus_Buffer[i + 1];

      if (prevDIPlus <= prevDIMinus && diPlus > diMinus)
        SendAlert("Bullish cross - +DI crossed above -DI", i);
      else if (prevDIPlus >= prevDIMinus && diPlus < diMinus)
        SendAlert("Bearish cross - +DI crossed below -DI", i);
    }

    if (AlertOnTrendChange) {
      double adx = ADX_Buffer[i];
      double prevADX = ADX_Buffer[i + 1];

      if (prevADX < WeakTrend && adx >= WeakTrend)
        SendAlert("Trend EMERGING (ADX > " + DoubleToStr(WeakTrend, 0) + ")", i);
      else if (prevADX < StrongTrend && adx >= StrongTrend)
        SendAlert("STRONG TREND (ADX > " + DoubleToStr(StrongTrend, 0) + ")", i);
      else if (prevADX >= WeakTrend && adx < WeakTrend)
        SendAlert("Trend WEAKENING (ADX < " + DoubleToStr(WeakTrend, 0) + ")", i);
    }
  }

  return rates_total;
}
//+------------------------------------------------------------------+
