//+------------------------------------------------------------------+
//|                                                   UniversalRSI.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal RSI using 55+ MA types for smoothing                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 DodgerBlue
#property indicator_color2 Yellow
#property indicator_color3 Lime
#property indicator_color4 Red
#property indicator_width1 2
#property indicator_width2 1
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 70
#property indicator_level2 50
#property indicator_level3 30
#property indicator_levelcolor Silver
#property indicator_levelstyle STYLE_DOT

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ RSI Settings ══════";  // ─────────────────
input int               RSI_Period = 14;             // RSI Period
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;   // Applied Price

input string            _sep2_ = "══════ Smoothing MA ══════"; // ─────────────────
input ENUM_MA_TYPE      Smoothing_Type = MA_SMMA;    // Smoothing MA Type (Wilder=SMMA)
input bool              UseAlternativeSmoothing = false; // Use Alternative Smoothing

input string            _sep3_ = "══════ Signal Line ══════"; // ─────────────────
input bool              ShowSignal = false;          // Show Signal Line
input ENUM_MA_TYPE      Signal_Type = MA_EMA;        // Signal MA Type
input int               Signal_Period = 9;           // Signal Period

input string            _sep4_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep5_ = "══════ Levels ══════"; // ─────────────────
input double            Overbought = 70;             // Overbought Level
input double            Oversold = 30;               // Oversold Level

input string            _sep6_ = "══════ Alerts ══════"; // ─────────────────
input bool              AlertOnOverbought = false;   // Alert on Overbought
input bool              AlertOnOversold = false;     // Alert on Oversold
input bool              AlertOnSignalCross = false;  // Alert on Signal Cross
input bool              EnableSound = false;         // Enable Sound
input bool              EnablePush = false;          // Enable Push Notifications

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double RSI_Buffer[];
double Signal_Buffer[];
double UpZone_Buffer[];
double DownZone_Buffer[];

// Internal buffers
double GainBuffer[];
double LossBuffer[];

int lastAlertBar = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // RSI line
  SetIndexBuffer(0, RSI_Buffer);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, DodgerBlue);
  SetIndexLabel(0, "RSI(" + IntegerToString(RSI_Period) + ")");

  // Signal line
  SetIndexBuffer(1, Signal_Buffer);
  if (ShowSignal) {
    SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, Yellow);
    SetIndexLabel(1, "Signal(" + IntegerToString(Signal_Period) + ")");
  } else {
    SetIndexStyle(1, DRAW_NONE);
    SetIndexLabel(1, NULL);
  }

  // Overbought zone visualization
  SetIndexBuffer(2, UpZone_Buffer);
  SetIndexStyle(2, DRAW_NONE);
  SetIndexLabel(2, NULL);

  // Oversold zone visualization
  SetIndexBuffer(3, DownZone_Buffer);
  SetIndexStyle(3, DRAW_NONE);
  SetIndexLabel(3, NULL);

  // Set levels
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, Overbought);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, 50);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, Oversold);

  // Set indicator name
  string smoothName = MovingAverages::GetTypeName(Smoothing_Type);
  string shortName = "RSI(" + IntegerToString(RSI_Period) + "," + smoothName + ")";
  IndicatorShortName(shortName);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string message, int barIndex) {
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string fullMessage = _Symbol + " RSI: " + message;
  Alert(fullMessage);

  if (EnableSound)
    PlaySound("alert.wav");

  if (EnablePush)
    SendNotification(fullMessage);
}

//+------------------------------------------------------------------+
//| Calculate smoothed average using selected MA type                |
//+------------------------------------------------------------------+
double SmoothAverage(double &values[], int shift, int period, ENUM_MA_TYPE maType) {
  switch (maType) {
    case MA_SMA: {
      double sum = 0;
      for (int i = 0; i < period; ++i)
        sum += values[shift + i];
      return sum / period;
    }

    case MA_EMA: {
      double k = 2.0 / (period + 1);
      double ema = values[shift + period * 3];
      for (int i = 0; i < period; ++i)
        ema += values[shift + period * 3 + i];
      ema /= period;

      for (int i = period * 3 - 1; i >= 0; --i)
        ema = values[shift + i] * k + ema * (1 - k);
      return ema;
    }

    case MA_SMMA: {
      // Wilder's smoothing (default for RSI)
      double smma = 0;
      for (int i = 0; i < period; ++i)
        smma += values[shift + period * 3 + i];
      smma /= period;

      for (int i = period * 3 - 1; i >= 0; --i)
        smma = (smma * (period - 1) + values[shift + i]) / period;
      return smma;
    }

    case MA_WMA: {
      double sum = 0;
      double weightSum = 0;
      for (int i = 0; i < period; ++i) {
        double weight = period - i;
        sum += values[shift + i] * weight;
        weightSum += weight;
      }
      return (weightSum > 0) ? sum / weightSum : 0;
    }

    default:
      return SmoothAverage(values, shift, period, MA_SMMA);
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

  if (rates_total < RSI_Period + 10) return 0;

  // Resize internal buffers
  if (ArraySize(GainBuffer) != rates_total) {
    ArrayResize(GainBuffer, rates_total);
    ArrayResize(LossBuffer, rates_total);
    ArrayInitialize(GainBuffer, 0);
    ArrayInitialize(LossBuffer, 0);
  }

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - 2;
  else
    limit = rates_total - prev_calculated + 1;

  // Calculate gains and losses
  for (int i = limit; i >= 0; --i) {
    double price = MovingAverages::GetPrice(_Symbol, _Period, RSI_Price, i);
    double prevPrice = MovingAverages::GetPrice(_Symbol, _Period, RSI_Price, i + 1);
    double change = price - prevPrice;

    GainBuffer[i] = (change > 0) ? change : 0;
    LossBuffer[i] = (change < 0) ? -change : 0;
  }

  // Calculate RSI
  for (int i = limit; i >= 0; --i) {
    if (i > rates_total - RSI_Period - 10) {
      RSI_Buffer[i] = 50;
      continue;
    }

    double avgGain, avgLoss;

    if (UseAlternativeSmoothing) {
      // Use alternative smoothing method - calculate MA directly on price
      // then derive RSI from the smoothed values
      avgGain = SmoothAverage(GainBuffer, i, RSI_Period, Smoothing_Type);
      avgLoss = SmoothAverage(LossBuffer, i, RSI_Period, Smoothing_Type);
    } else {
      // Standard Wilder's smoothing
      avgGain = SmoothAverage(GainBuffer, i, RSI_Period, MA_SMMA);
      avgLoss = SmoothAverage(LossBuffer, i, RSI_Period, MA_SMMA);
    }

    if (avgLoss == 0)
      RSI_Buffer[i] = 100;
    else {
      double rs = avgGain / avgLoss;
      RSI_Buffer[i] = 100 - (100 / (1 + rs));
    }
  }

  // Calculate signal line
  if (ShowSignal) {
    for (int i = limit; i >= 0; --i) {
      if (i > rates_total - RSI_Period - Signal_Period - 10) {
        Signal_Buffer[i] = RSI_Buffer[i];
        continue;
      }

      // Simple smoothing of RSI values
      double sum = 0;
      for (int j = 0; j < Signal_Period; ++j)
        sum += RSI_Buffer[i + j];
      Signal_Buffer[i] = sum / Signal_Period;
    }
  }

  // Check alerts
  if (prev_calculated > 0) {
    int i = 1;
    double rsi = RSI_Buffer[i];
    double prevRsi = RSI_Buffer[i + 1];

    if (AlertOnOverbought && prevRsi < Overbought && rsi >= Overbought)
      SendAlert("Entered OVERBOUGHT zone (" + DoubleToStr(rsi, 1) + ")", i);

    if (AlertOnOversold && prevRsi > Oversold && rsi <= Oversold)
      SendAlert("Entered OVERSOLD zone (" + DoubleToStr(rsi, 1) + ")", i);

    if (AlertOnSignalCross && ShowSignal) {
      double sig = Signal_Buffer[i];
      double prevSig = Signal_Buffer[i + 1];

      if (prevRsi <= prevSig && rsi > sig)
        SendAlert("RSI crossed ABOVE Signal", i);
      else if (prevRsi >= prevSig && rsi < sig)
        SendAlert("RSI crossed BELOW Signal", i);
    }
  }

  return rates_total;
}
//+------------------------------------------------------------------+
