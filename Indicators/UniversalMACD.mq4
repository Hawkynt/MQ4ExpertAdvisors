//+------------------------------------------------------------------+
//|                                                  UniversalMACD.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal MACD indicator using 55+ MA types                      |
//| Allows any MA combination for Fast, Slow, and Signal lines       |
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
#property indicator_color4 Red
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2
#property indicator_level1 0
#property indicator_levelcolor Silver
#property indicator_levelstyle STYLE_DOT

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ Fast MA ══════";  // ─────────────────
input ENUM_MA_TYPE      Fast_Type = MA_EMA;          // MA Type
input int               Fast_Period = 12;            // Period
input ENUM_APPLIED_PRICE Fast_Price = PRICE_CLOSE;  // Applied Price

input string            _sep2_ = "══════ Slow MA ══════"; // ─────────────────
input ENUM_MA_TYPE      Slow_Type = MA_EMA;          // MA Type
input int               Slow_Period = 26;            // Period
input ENUM_APPLIED_PRICE Slow_Price = PRICE_CLOSE;  // Applied Price

input string            _sep3_ = "══════ Signal Line ══════"; // ─────────────────
input ENUM_MA_TYPE      Signal_Type = MA_EMA;        // MA Type
input int               Signal_Period = 9;           // Period

input string            _sep4_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep5_ = "══════ Display ══════"; // ─────────────────
input bool              ShowHistogram = true;        // Show Histogram
input color             HistogramUpColor = Lime;     // Histogram Up Color
input color             HistogramDownColor = Red;    // Histogram Down Color
input bool              ColorHistogramByDirection = true; // Color by Direction Change

input string            _sep6_ = "══════ Alerts ══════"; // ─────────────────
input bool              AlertOnSignalCross = false;  // Alert on Signal Line Cross
input bool              AlertOnZeroCross = false;    // Alert on Zero Line Cross
input bool              EnableSound = false;         // Enable Sound
input string            SoundFile = "alert.wav";     // Sound File
input bool              EnablePush = false;          // Enable Push Notifications

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double MACD_Buffer[];
double Signal_Buffer[];
double HistogramUp_Buffer[];
double HistogramDown_Buffer[];

// Internal buffers for MA calculations
double FastMA_Values[];
double SlowMA_Values[];

datetime lastAlertTime = 0;
int lastAlertBar = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // MACD line
  SetIndexBuffer(0, MACD_Buffer);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, DodgerBlue);
  SetIndexLabel(0, "MACD");

  // Signal line
  SetIndexBuffer(1, Signal_Buffer);
  SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, Red);
  SetIndexLabel(1, "Signal");

  // Histogram (up)
  SetIndexBuffer(2, HistogramUp_Buffer);
  if (ShowHistogram) {
    SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 2, HistogramUpColor);
    SetIndexLabel(2, "Histogram+");
  } else {
    SetIndexStyle(2, DRAW_NONE);
    SetIndexLabel(2, NULL);
  }

  // Histogram (down)
  SetIndexBuffer(3, HistogramDown_Buffer);
  if (ShowHistogram) {
    SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID, 2, HistogramDownColor);
    SetIndexLabel(3, "Histogram-");
  } else {
    SetIndexStyle(3, DRAW_NONE);
    SetIndexLabel(3, NULL);
  }

  // Set indicator name
  string fastName = MovingAverages::GetTypeName(Fast_Type);
  string slowName = MovingAverages::GetTypeName(Slow_Type);
  string signalName = MovingAverages::GetTypeName(Signal_Type);

  string shortName = "MACD(" + fastName + IntegerToString(Fast_Period) + "," +
                     slowName + IntegerToString(Slow_Period) + "," +
                     signalName + IntegerToString(Signal_Period) + ")";
  IndicatorShortName(shortName);

  // Set accuracy
  IndicatorDigits(_Digits + 1);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Send alerts                                                       |
//+------------------------------------------------------------------+
void SendAlert(string message, int barIndex) {
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string fullMessage = _Symbol + " " + PeriodToString() + ": " + message;

  Alert(fullMessage);

  if (EnableSound)
    PlaySound(SoundFile);

  if (EnablePush)
    SendNotification(fullMessage);

  Print(fullMessage);
}

//+------------------------------------------------------------------+
//| Convert period to string                                          |
//+------------------------------------------------------------------+
string PeriodToString() {
  switch (_Period) {
    case PERIOD_M1:  return "M1";
    case PERIOD_M5:  return "M5";
    case PERIOD_M15: return "M15";
    case PERIOD_M30: return "M30";
    case PERIOD_H1:  return "H1";
    case PERIOD_H4:  return "H4";
    case PERIOD_D1:  return "D1";
    case PERIOD_W1:  return "W1";
    case PERIOD_MN1: return "MN1";
    default:         return "M" + IntegerToString(_Period);
  }
}

//+------------------------------------------------------------------+
//| Calculate Signal line using MA of MACD values                    |
//+------------------------------------------------------------------+
double CalculateSignal(int shift, int period, ENUM_MA_TYPE maType) {
  // For the signal line, we need to calculate MA of MACD values
  // This requires a different approach since MACD isn't a price series

  if (period <= 0) return 0;

  switch (maType) {
    case MA_SMA: {
      double sum = 0;
      for (int i = 0; i < period; ++i)
        sum += MACD_Buffer[shift + i];
      return sum / period;
    }

    case MA_EMA: {
      double k = 2.0 / (period + 1);
      // Initialize with SMA
      double ema = 0;
      for (int i = 0; i < period; ++i)
        ema += MACD_Buffer[shift + period * 3 + i];
      ema /= period;

      // Calculate EMA forward
      for (int i = period * 3 - 1; i >= 0; --i)
        ema = MACD_Buffer[shift + i] * k + ema * (1 - k);
      return ema;
    }

    case MA_WMA: {
      double sum = 0;
      double weightSum = 0;
      for (int i = 0; i < period; ++i) {
        double weight = period - i;
        sum += MACD_Buffer[shift + i] * weight;
        weightSum += weight;
      }
      return (weightSum > 0) ? sum / weightSum : 0;
    }

    case MA_SMMA: {
      double smma = 0;
      for (int i = 0; i < period; ++i)
        smma += MACD_Buffer[shift + period * 3 + i];
      smma /= period;

      for (int i = period * 3 - 1; i >= 0; --i)
        smma = (smma * (period - 1) + MACD_Buffer[shift + i]) / period;
      return smma;
    }

    case MA_TMA: {
      int halfPeriod = (int)MathCeil((period + 1) / 2.0);
      double sum = 0;
      for (int i = 0; i < halfPeriod; ++i) {
        double innerSum = 0;
        for (int j = 0; j < halfPeriod; ++j)
          innerSum += MACD_Buffer[shift + i + j];
        sum += innerSum / halfPeriod;
      }
      return sum / halfPeriod;
    }

    case MA_DEMA: {
      double k = 2.0 / (period + 1);
      double ema1 = 0, ema2 = 0;
      for (int i = 0; i < period; ++i)
        ema1 += MACD_Buffer[shift + period * 3 + i];
      ema1 /= period;
      ema2 = ema1;

      for (int i = period * 3 - 1; i >= 0; --i) {
        ema1 = MACD_Buffer[shift + i] * k + ema1 * (1 - k);
        ema2 = ema1 * k + ema2 * (1 - k);
      }
      return 2 * ema1 - ema2;
    }

    case MA_TEMA: {
      double k = 2.0 / (period + 1);
      double ema1 = 0, ema2 = 0, ema3 = 0;
      for (int i = 0; i < period; ++i)
        ema1 += MACD_Buffer[shift + period * 3 + i];
      ema1 /= period;
      ema2 = ema1;
      ema3 = ema1;

      for (int i = period * 3 - 1; i >= 0; --i) {
        ema1 = MACD_Buffer[shift + i] * k + ema1 * (1 - k);
        ema2 = ema1 * k + ema2 * (1 - k);
        ema3 = ema2 * k + ema3 * (1 - k);
      }
      return 3 * ema1 - 3 * ema2 + ema3;
    }

    default:
      // Fall back to EMA for other types
      return CalculateSignal(shift, period, MA_EMA);
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

  int maxPeriod = MathMax(Fast_Period, Slow_Period);
  if (rates_total < maxPeriod + Signal_Period + 10) return 0;

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - maxPeriod - Signal_Period - 10;
  else
    limit = rates_total - prev_calculated + 1;

  // Ensure we don't exceed bounds
  if (limit > rates_total - maxPeriod - Signal_Period - 10)
    limit = rates_total - maxPeriod - Signal_Period - 10;

  // Calculate MACD line (Fast MA - Slow MA)
  for (int i = limit; i >= 0; --i) {
    double fastMA = MovingAverages::Calculate(
      Fast_Type, _Symbol, _Period, Fast_Period, i, Fast_Price, OptParam1, OptParam2
    );

    double slowMA = MovingAverages::Calculate(
      Slow_Type, _Symbol, _Period, Slow_Period, i, Slow_Price, OptParam1, OptParam2
    );

    MACD_Buffer[i] = fastMA - slowMA;
  }

  // Calculate Signal line (MA of MACD)
  for (int i = limit; i >= 0; --i)
    Signal_Buffer[i] = CalculateSignal(i, Signal_Period, Signal_Type);

  // Calculate Histogram
  for (int i = limit; i >= 0; --i) {
    double histogram = MACD_Buffer[i] - Signal_Buffer[i];

    HistogramUp_Buffer[i] = EMPTY_VALUE;
    HistogramDown_Buffer[i] = EMPTY_VALUE;

    if (ShowHistogram) {
      if (ColorHistogramByDirection) {
        // Color by direction change (rising/falling)
        double prevHistogram = MACD_Buffer[i + 1] - Signal_Buffer[i + 1];
        if (histogram > prevHistogram)
          HistogramUp_Buffer[i] = histogram;
        else
          HistogramDown_Buffer[i] = histogram;
      } else {
        // Color by positive/negative
        if (histogram >= 0)
          HistogramUp_Buffer[i] = histogram;
        else
          HistogramDown_Buffer[i] = histogram;
      }
    }

    // Check for alerts on just-closed bar
    if (i == 1 && prev_calculated > 0) {
      // Signal line cross
      if (AlertOnSignalCross) {
        double macdPrev = MACD_Buffer[i + 1];
        double signalPrev = Signal_Buffer[i + 1];
        double macdCurr = MACD_Buffer[i];
        double signalCurr = Signal_Buffer[i];

        if (macdPrev <= signalPrev && macdCurr > signalCurr)
          SendAlert("MACD crossed ABOVE Signal line (Bullish)", i);
        else if (macdPrev >= signalPrev && macdCurr < signalCurr)
          SendAlert("MACD crossed BELOW Signal line (Bearish)", i);
      }

      // Zero line cross
      if (AlertOnZeroCross) {
        double macdPrev = MACD_Buffer[i + 1];
        double macdCurr = MACD_Buffer[i];

        if (macdPrev <= 0 && macdCurr > 0)
          SendAlert("MACD crossed ABOVE zero line (Bullish)", i);
        else if (macdPrev >= 0 && macdCurr < 0)
          SendAlert("MACD crossed BELOW zero line (Bearish)", i);
      }
    }
  }

  return rates_total;
}
//+------------------------------------------------------------------+
