//+------------------------------------------------------------------+
//|                                                   UniversalCCI.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal CCI using 55+ MA types for mean calculation            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 DodgerBlue
#property indicator_color2 Yellow
#property indicator_color3 Magenta
#property indicator_width1 2
#property indicator_width2 1
#property indicator_level1 100
#property indicator_level2 0
#property indicator_level3 -100
#property indicator_levelcolor Silver
#property indicator_levelstyle STYLE_DOT

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ CCI Settings ══════";  // ─────────────────
input int               CCI_Period = 20;             // CCI Period
input ENUM_APPLIED_PRICE CCI_Price = PRICE_TYPICAL; // Applied Price

input string            _sep2_ = "══════ Mean Calculation ══════"; // ─────────────────
input ENUM_MA_TYPE      MA_Type = MA_SMA;            // MA Type for Mean
input double            Constant = 0.015;            // CCI Constant (default 0.015)

input string            _sep3_ = "══════ Signal Line ══════"; // ─────────────────
input bool              ShowSignal = false;          // Show Signal Line
input ENUM_MA_TYPE      Signal_Type = MA_EMA;        // Signal MA Type
input int               Signal_Period = 9;           // Signal Period

input string            _sep4_ = "══════ Turbo CCI ══════"; // ─────────────────
input bool              ShowTurboCCI = false;        // Show Turbo CCI
input int               Turbo_Period = 6;            // Turbo CCI Period

input string            _sep5_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep6_ = "══════ Levels ══════"; // ─────────────────
input double            Overbought = 100;            // Overbought Level
input double            Oversold = -100;             // Oversold Level
input double            ExtremeHigh = 200;           // Extreme High Level
input double            ExtremeLow = -200;           // Extreme Low Level

input string            _sep7_ = "══════ Alerts ══════"; // ─────────────────
input bool              AlertOnLevelCross = false;   // Alert on Level Cross
input bool              AlertOnZeroCross = false;    // Alert on Zero Cross
input bool              EnableSound = false;         // Enable Sound
input bool              EnablePush = false;          // Enable Push Notifications

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double CCI_Buffer[];
double Signal_Buffer[];
double Turbo_Buffer[];

int lastAlertBar = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // CCI line
  SetIndexBuffer(0, CCI_Buffer);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, DodgerBlue);
  SetIndexLabel(0, "CCI(" + IntegerToString(CCI_Period) + ")");

  // Signal line
  SetIndexBuffer(1, Signal_Buffer);
  if (ShowSignal) {
    SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, Yellow);
    SetIndexLabel(1, "Signal(" + IntegerToString(Signal_Period) + ")");
  } else {
    SetIndexStyle(1, DRAW_NONE);
    SetIndexLabel(1, NULL);
  }

  // Turbo CCI
  SetIndexBuffer(2, Turbo_Buffer);
  if (ShowTurboCCI) {
    SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, Magenta);
    SetIndexLabel(2, "Turbo(" + IntegerToString(Turbo_Period) + ")");
  } else {
    SetIndexStyle(2, DRAW_NONE);
    SetIndexLabel(2, NULL);
  }

  // Set levels
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, Overbought);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, 0);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, Oversold);

  // Set indicator name
  string maName = MovingAverages::GetTypeName(MA_Type);
  string shortName = "CCI(" + IntegerToString(CCI_Period) + "," + maName + ")";
  IndicatorShortName(shortName);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string message, int barIndex) {
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string fullMessage = _Symbol + " CCI: " + message;
  Alert(fullMessage);

  if (EnableSound)
    PlaySound("alert.wav");

  if (EnablePush)
    SendNotification(fullMessage);
}

//+------------------------------------------------------------------+
//| Calculate CCI for given period                                    |
//+------------------------------------------------------------------+
double CalculateCCI(int shift, int period) {
  // Calculate typical price MA
  double ma = MovingAverages::Calculate(
    MA_Type, _Symbol, _Period, period, shift, CCI_Price, OptParam1, OptParam2
  );

  // Calculate mean deviation
  double sumDev = 0;
  for (int i = 0; i < period; ++i) {
    double tp = MovingAverages::GetPrice(_Symbol, _Period, CCI_Price, shift + i);
    sumDev += MathAbs(tp - ma);
  }
  double meanDev = sumDev / period;

  // Calculate CCI
  double tp = MovingAverages::GetPrice(_Symbol, _Period, CCI_Price, shift);

  if (meanDev == 0) return 0;

  return (tp - ma) / (Constant * meanDev);
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

  int maxPeriod = MathMax(CCI_Period, Turbo_Period);
  if (rates_total < maxPeriod + Signal_Period + 10) return 0;

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - maxPeriod - Signal_Period - 10;
  else
    limit = rates_total - prev_calculated + 1;

  if (limit > rates_total - maxPeriod - 10)
    limit = rates_total - maxPeriod - 10;

  // Calculate CCI
  for (int i = limit; i >= 0; --i)
    CCI_Buffer[i] = CalculateCCI(i, CCI_Period);

  // Calculate Turbo CCI
  if (ShowTurboCCI) {
    for (int i = limit; i >= 0; --i)
      Turbo_Buffer[i] = CalculateCCI(i, Turbo_Period);
  }

  // Calculate Signal line
  if (ShowSignal) {
    for (int i = limit; i >= 0; --i)
      Signal_Buffer[i] = CalculateBufferMA(CCI_Buffer, i, Signal_Period, Signal_Type);
  }

  // Check alerts
  if (prev_calculated > 0) {
    int i = 1;
    double cci = CCI_Buffer[i];
    double prevCCI = CCI_Buffer[i + 1];

    if (AlertOnZeroCross) {
      if (prevCCI <= 0 && cci > 0)
        SendAlert("Crossed ABOVE zero line (Bullish)", i);
      else if (prevCCI >= 0 && cci < 0)
        SendAlert("Crossed BELOW zero line (Bearish)", i);
    }

    if (AlertOnLevelCross) {
      if (prevCCI < Overbought && cci >= Overbought)
        SendAlert("Entered OVERBOUGHT zone (" + DoubleToStr(cci, 0) + ")", i);
      else if (prevCCI > Oversold && cci <= Oversold)
        SendAlert("Entered OVERSOLD zone (" + DoubleToStr(cci, 0) + ")", i);
      else if (prevCCI < ExtremeHigh && cci >= ExtremeHigh)
        SendAlert("EXTREME HIGH (" + DoubleToStr(cci, 0) + ")", i);
      else if (prevCCI > ExtremeLow && cci <= ExtremeLow)
        SendAlert("EXTREME LOW (" + DoubleToStr(cci, 0) + ")", i);
    }
  }

  return rates_total;
}
//+------------------------------------------------------------------+
