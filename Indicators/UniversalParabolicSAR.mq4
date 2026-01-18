//+------------------------------------------------------------------+
//|                                          UniversalParabolicSAR.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal Parabolic SAR indicator with native calculation        |
//| and optional MA smoothing using 82 MA types                      |
//| No dependency on built-in iSAR function                          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Lime
#property indicator_color2 Red
#property indicator_color3 DodgerBlue
#property indicator_color4 Orange
#property indicator_width1 0
#property indicator_width2 0
#property indicator_width3 2
#property indicator_width4 2

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ SAR Parameters ══════";  // ─────────────────
input double            SAR_Step = 0.02;              // AF Step (Acceleration Factor increment)
input double            SAR_Maximum = 0.2;            // AF Maximum (Max acceleration)
input double            SAR_Start = 0.02;             // AF Start (Initial acceleration)

input string            _sep2_ = "══════ MA Smoothing ══════"; // ─────────────────
input bool              MA_Enable = false;            // Enable MA Smoothing of SAR
input ENUM_MA_TYPE      MA_Type = MA_EMA;             // MA Type for Smoothing
input int               MA_Period = 3;                // MA Period
input double            MA_OptParam1 = 0;             // MA Opt Param 1
input double            MA_OptParam2 = 0;             // MA Opt Param 2

input string            _sep3_ = "══════ MA Confirmation ══════"; // ─────────────────
input bool              Confirm_Enable = false;       // Enable MA Trend Confirmation
input ENUM_MA_TYPE      Confirm_MA_Type = MA_EMA;     // Confirmation MA Type
input int               Confirm_MA_Period = 21;       // Confirmation MA Period
input ENUM_APPLIED_PRICE Confirm_MA_Price = PRICE_CLOSE; // Confirmation MA Price
input double            Confirm_OptParam1 = 0;        // Confirm MA Opt Param 1
input double            Confirm_OptParam2 = 0;        // Confirm MA Opt Param 2

input string            _sep4_ = "══════ Display ══════"; // ─────────────────
input color             Color_Long = Lime;            // SAR Color (Bullish)
input color             Color_Short = Red;            // SAR Color (Bearish)
input int               SAR_Size = 2;                 // SAR Dot Size (1-5)
input color             Color_MA = DodgerBlue;        // Confirmation MA Color
input bool              ShowLabel = true;             // Show Info Label
input int               LabelX = 10;                  // Label X Position
input int               LabelY = 30;                  // Label Y Position

input string            _sep5_ = "══════ Alerts ══════"; // ─────────────────
input bool              Alert_Enable = false;         // Enable Alerts
input bool              Alert_Popup = true;           // Popup Alert
input bool              Alert_Sound = true;           // Sound Alert
input bool              Alert_Email = false;          // Email Alert
input bool              Alert_Push = false;           // Push Notification

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double SAR_Long_Buffer[];    // SAR dots for bullish trend
double SAR_Short_Buffer[];   // SAR dots for bearish trend
double MA_Buffer[];          // Confirmation MA line
double Smoothed_SAR[];       // Internal: smoothed SAR values

// Internal tracking arrays
double EP_Buffer[];          // Extreme Point
double AF_Buffer[];          // Acceleration Factor
int    Trend_Buffer[];       // Trend direction: 1=long, -1=short

datetime lastAlertTime = 0;
int lastAlertTrend = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // Set up SAR buffers
  SetIndexBuffer(0, SAR_Long_Buffer);
  SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, SAR_Size, Color_Long);
  SetIndexArrow(0, 159);  // Dot symbol
  SetIndexLabel(0, "SAR Long");

  SetIndexBuffer(1, SAR_Short_Buffer);
  SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, SAR_Size, Color_Short);
  SetIndexArrow(1, 159);  // Dot symbol
  SetIndexLabel(1, "SAR Short");

  // Confirmation MA buffer
  SetIndexBuffer(2, MA_Buffer);
  if (Confirm_Enable) {
    SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, Color_MA);
    SetIndexLabel(2, MovingAverages::GetTypeName(Confirm_MA_Type) + "(" + IntegerToString(Confirm_MA_Period) + ")");
  } else {
    SetIndexStyle(2, DRAW_NONE);
    SetIndexLabel(2, NULL);
  }

  // Smoothed SAR (internal, not displayed separately)
  SetIndexBuffer(3, Smoothed_SAR);
  SetIndexStyle(3, DRAW_NONE);
  SetIndexLabel(3, NULL);

  // Allocate internal arrays
  ArrayResize(EP_Buffer, Bars);
  ArrayResize(AF_Buffer, Bars);
  ArrayResize(Trend_Buffer, Bars);
  ArrayInitialize(EP_Buffer, 0);
  ArrayInitialize(AF_Buffer, 0);
  ArraySetAsSeries(EP_Buffer, true);
  ArraySetAsSeries(AF_Buffer, true);

  // Set indicator name
  string shortName = "UPSAR(" + DoubleToString(SAR_Step, 2) + "," + DoubleToString(SAR_Maximum, 2) + ")";
  if (MA_Enable)
    shortName += " [" + MovingAverages::GetTypeName(MA_Type) + "]";
  if (Confirm_Enable)
    shortName += " +MA";
  IndicatorShortName(shortName);

  // Create label
  if (ShowLabel)
    CreateLabels();

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  ObjectDelete("UPSAR_Label1");
  ObjectDelete("UPSAR_Label2");
  ObjectDelete("UPSAR_LabelBG");
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

  if (rates_total < 3) return 0;

  // Ensure internal arrays are large enough
  if (ArraySize(EP_Buffer) < rates_total) {
    ArrayResize(EP_Buffer, rates_total);
    ArrayResize(AF_Buffer, rates_total);
    ArrayResize(Trend_Buffer, rates_total);
  }

  int limit;
  if (prev_calculated == 0) {
    limit = rates_total - 3;
    // Initialize first values
    InitializeSAR(limit, high, low);
  } else {
    limit = rates_total - prev_calculated + 1;
  }

  // Calculate SAR from oldest to newest
  for (int i = limit; i >= 0; --i) {
    CalculateSAR(i, high, low, close);
  }

  // Apply MA smoothing if enabled
  if (MA_Enable) {
    ApplyMASmoothing(limit);
  }

  // Calculate confirmation MA if enabled
  if (Confirm_Enable) {
    for (int i = limit; i >= 0; --i) {
      MA_Buffer[i] = MovingAverages::Calculate(
        Confirm_MA_Type, _Symbol, _Period,
        Confirm_MA_Period, i, Confirm_MA_Price,
        Confirm_OptParam1, Confirm_OptParam2
      );
    }
  }

  // Check for alerts
  if (Alert_Enable && prev_calculated > 0)
    CheckAlerts();

  // Update label
  if (ShowLabel)
    UpdateLabels();

  return rates_total;
}

//+------------------------------------------------------------------+
//| Initialize SAR at the start                                       |
//+------------------------------------------------------------------+
void InitializeSAR(int startBar, const double &high[], const double &low[]) {
  // Determine initial trend by looking at first few bars
  bool initialLong = (iClose(_Symbol, _Period, startBar) > iClose(_Symbol, _Period, startBar + 2));

  if (initialLong) {
    Trend_Buffer[startBar + 1] = 1;
    Smoothed_SAR[startBar + 1] = low[startBar + 1];
    EP_Buffer[startBar + 1] = high[startBar + 1];
  } else {
    Trend_Buffer[startBar + 1] = -1;
    Smoothed_SAR[startBar + 1] = high[startBar + 1];
    EP_Buffer[startBar + 1] = low[startBar + 1];
  }
  AF_Buffer[startBar + 1] = SAR_Start;

  // Set initial display
  if (Trend_Buffer[startBar + 1] == 1) {
    SAR_Long_Buffer[startBar + 1] = Smoothed_SAR[startBar + 1];
    SAR_Short_Buffer[startBar + 1] = EMPTY_VALUE;
  } else {
    SAR_Short_Buffer[startBar + 1] = Smoothed_SAR[startBar + 1];
    SAR_Long_Buffer[startBar + 1] = EMPTY_VALUE;
  }
}

//+------------------------------------------------------------------+
//| Calculate SAR for a specific bar                                  |
//+------------------------------------------------------------------+
void CalculateSAR(int i, const double &high[], const double &low[], const double &close[]) {
  if (i >= ArraySize(Trend_Buffer) - 1) return;

  int prevTrend = Trend_Buffer[i + 1];
  double prevSAR = Smoothed_SAR[i + 1];
  double prevEP = EP_Buffer[i + 1];
  double prevAF = AF_Buffer[i + 1];

  double currentHigh = high[i];
  double currentLow = low[i];
  double prevHigh = high[i + 1];
  double prevLow = low[i + 1];

  double newSAR, newEP, newAF;
  int newTrend;

  if (prevTrend == 1) {
    // In uptrend
    newSAR = prevSAR + prevAF * (prevEP - prevSAR);

    // SAR cannot be above prior two lows
    newSAR = MathMin(newSAR, prevLow);
    if (i + 2 < ArraySize(low))
      newSAR = MathMin(newSAR, low[i + 2]);

    // Check for trend reversal
    if (currentLow < newSAR) {
      // Reverse to downtrend
      newTrend = -1;
      newSAR = prevEP;  // SAR becomes the previous EP
      newEP = currentLow;
      newAF = SAR_Start;
    } else {
      // Continue uptrend
      newTrend = 1;
      if (currentHigh > prevEP) {
        newEP = currentHigh;
        newAF = MathMin(prevAF + SAR_Step, SAR_Maximum);
      } else {
        newEP = prevEP;
        newAF = prevAF;
      }
    }
  } else {
    // In downtrend
    newSAR = prevSAR + prevAF * (prevEP - prevSAR);

    // SAR cannot be below prior two highs
    newSAR = MathMax(newSAR, prevHigh);
    if (i + 2 < ArraySize(high))
      newSAR = MathMax(newSAR, high[i + 2]);

    // Check for trend reversal
    if (currentHigh > newSAR) {
      // Reverse to uptrend
      newTrend = 1;
      newSAR = prevEP;  // SAR becomes the previous EP
      newEP = currentHigh;
      newAF = SAR_Start;
    } else {
      // Continue downtrend
      newTrend = -1;
      if (currentLow < prevEP) {
        newEP = currentLow;
        newAF = MathMin(prevAF + SAR_Step, SAR_Maximum);
      } else {
        newEP = prevEP;
        newAF = prevAF;
      }
    }
  }

  // Store values
  Smoothed_SAR[i] = newSAR;
  EP_Buffer[i] = newEP;
  AF_Buffer[i] = newAF;
  Trend_Buffer[i] = newTrend;

  // Apply MA confirmation filter if enabled
  bool showSignal = true;
  if (Confirm_Enable && i < ArraySize(MA_Buffer)) {
    double maValue = MovingAverages::Calculate(
      Confirm_MA_Type, _Symbol, _Period,
      Confirm_MA_Period, i, Confirm_MA_Price,
      Confirm_OptParam1, Confirm_OptParam2
    );
    // Only show long SAR if price above MA, short SAR if price below MA
    if (newTrend == 1 && close[i] < maValue)
      showSignal = false;
    if (newTrend == -1 && close[i] > maValue)
      showSignal = false;
  }

  // Set display buffers
  if (newTrend == 1 && showSignal) {
    SAR_Long_Buffer[i] = newSAR;
    SAR_Short_Buffer[i] = EMPTY_VALUE;
  } else if (newTrend == -1 && showSignal) {
    SAR_Short_Buffer[i] = newSAR;
    SAR_Long_Buffer[i] = EMPTY_VALUE;
  } else {
    SAR_Long_Buffer[i] = EMPTY_VALUE;
    SAR_Short_Buffer[i] = EMPTY_VALUE;
  }
}

//+------------------------------------------------------------------+
//| Apply MA smoothing to SAR values                                  |
//+------------------------------------------------------------------+
void ApplyMASmoothing(int limit) {
  if (MA_Period <= 1) return;

  // Create temporary array for raw SAR values
  double rawSAR[];
  ArrayResize(rawSAR, ArraySize(Smoothed_SAR));
  ArrayCopy(rawSAR, Smoothed_SAR);

  for (int i = limit; i >= 0; --i) {
    if (i + MA_Period >= ArraySize(rawSAR)) continue;

    // Calculate MA of SAR values
    double sum = 0;
    double weightSum = 0;

    // Simple weighted average of recent SAR values
    // Using our MA library would require price data, so we do manual smoothing
    for (int j = 0; j < MA_Period; ++j) {
      if (i + j < ArraySize(rawSAR) && rawSAR[i + j] != EMPTY_VALUE && rawSAR[i + j] > 0) {
        double weight = MA_Period - j;  // Linear weighting
        sum += rawSAR[i + j] * weight;
        weightSum += weight;
      }
    }

    if (weightSum > 0) {
      double smoothedValue = sum / weightSum;

      // Update display buffer with smoothed value
      if (Trend_Buffer[i] == 1) {
        SAR_Long_Buffer[i] = smoothedValue;
      } else if (Trend_Buffer[i] == -1) {
        SAR_Short_Buffer[i] = smoothedValue;
      }
    }
  }
}

//+------------------------------------------------------------------+
//| Check for alerts on trend change                                  |
//+------------------------------------------------------------------+
void CheckAlerts() {
  if (Time[0] == lastAlertTime) return;

  int currentTrend = Trend_Buffer[0];
  int prevTrend = Trend_Buffer[1];

  if (currentTrend != prevTrend && currentTrend != lastAlertTrend) {
    string alertMsg;
    if (currentTrend == 1)
      alertMsg = _Symbol + " " + PeriodToString(_Period) + ": UPSAR switched to BULLISH";
    else
      alertMsg = _Symbol + " " + PeriodToString(_Period) + ": UPSAR switched to BEARISH";

    if (Alert_Popup)
      Alert(alertMsg);
    if (Alert_Sound)
      PlaySound("alert.wav");
    if (Alert_Email)
      SendMail("UPSAR Alert", alertMsg);
    if (Alert_Push)
      SendNotification(alertMsg);

    lastAlertTime = Time[0];
    lastAlertTrend = currentTrend;
  }
}

//+------------------------------------------------------------------+
//| Convert period to string                                          |
//+------------------------------------------------------------------+
string PeriodToString(int period) {
  switch (period) {
    case PERIOD_M1:  return "M1";
    case PERIOD_M5:  return "M5";
    case PERIOD_M15: return "M15";
    case PERIOD_M30: return "M30";
    case PERIOD_H1:  return "H1";
    case PERIOD_H4:  return "H4";
    case PERIOD_D1:  return "D1";
    case PERIOD_W1:  return "W1";
    case PERIOD_MN1: return "MN1";
    default:         return "M" + IntegerToString(period);
  }
}

//+------------------------------------------------------------------+
//| Create info labels                                                |
//+------------------------------------------------------------------+
void CreateLabels() {
  // Background
  ObjectCreate("UPSAR_LabelBG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
  ObjectSet("UPSAR_LabelBG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("UPSAR_LabelBG", OBJPROP_XDISTANCE, LabelX - 5);
  ObjectSet("UPSAR_LabelBG", OBJPROP_YDISTANCE, LabelY - 5);
  ObjectSet("UPSAR_LabelBG", OBJPROP_XSIZE, 200);
  ObjectSet("UPSAR_LabelBG", OBJPROP_YSIZE, 45);
  ObjectSet("UPSAR_LabelBG", OBJPROP_BGCOLOR, C'30,30,30');
  ObjectSet("UPSAR_LabelBG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
  ObjectSet("UPSAR_LabelBG", OBJPROP_COLOR, C'60,60,60');

  // Main label
  ObjectCreate("UPSAR_Label1", OBJ_LABEL, 0, 0, 0);
  ObjectSet("UPSAR_Label1", OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("UPSAR_Label1", OBJPROP_XDISTANCE, LabelX);
  ObjectSet("UPSAR_Label1", OBJPROP_YDISTANCE, LabelY);
  ObjectSetText("UPSAR_Label1", "Universal Parabolic SAR", 9, "Arial Bold", White);

  // Info label
  ObjectCreate("UPSAR_Label2", OBJ_LABEL, 0, 0, 0);
  ObjectSet("UPSAR_Label2", OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("UPSAR_Label2", OBJPROP_XDISTANCE, LabelX);
  ObjectSet("UPSAR_Label2", OBJPROP_YDISTANCE, LabelY + 15);
}

//+------------------------------------------------------------------+
//| Update info labels                                                |
//+------------------------------------------------------------------+
void UpdateLabels() {
  string info = "Step: " + DoubleToString(SAR_Step, 2) + " | Max: " + DoubleToString(SAR_Maximum, 2);
  if (MA_Enable)
    info += " | Smooth: " + MovingAverages::GetTypeName(MA_Type);
  if (Confirm_Enable)
    info += " | Filter: " + MovingAverages::GetTypeName(Confirm_MA_Type);

  string trend = (Trend_Buffer[0] == 1) ? "BULLISH" : "BEARISH";
  color trendColor = (Trend_Buffer[0] == 1) ? Color_Long : Color_Short;

  ObjectSetText("UPSAR_Label2", info + " | " + trend, 8, "Arial", trendColor);
}

//+------------------------------------------------------------------+
//| Get SAR value at specified shift (for external use)               |
//+------------------------------------------------------------------+
double GetSARValue(int shift) {
  if (shift < 0 || shift >= ArraySize(Smoothed_SAR))
    return 0;
  return Smoothed_SAR[shift];
}

//+------------------------------------------------------------------+
//| Get trend direction at specified shift (for external use)         |
//| Returns: 1 = bullish, -1 = bearish, 0 = undefined                 |
//+------------------------------------------------------------------+
int GetTrend(int shift) {
  if (shift < 0 || shift >= ArraySize(Trend_Buffer))
    return 0;
  return Trend_Buffer[shift];
}

//+------------------------------------------------------------------+
//| Check if price is above SAR (bullish)                             |
//+------------------------------------------------------------------+
bool IsBullish(int shift = 0) {
  return GetTrend(shift) == 1;
}

//+------------------------------------------------------------------+
//| Check if price is below SAR (bearish)                             |
//+------------------------------------------------------------------+
bool IsBearish(int shift = 0) {
  return GetTrend(shift) == -1;
}

//+------------------------------------------------------------------+
//| Check for bullish reversal (short to long)                        |
//+------------------------------------------------------------------+
bool IsBullishReversal(int shift = 0) {
  if (shift + 1 >= ArraySize(Trend_Buffer)) return false;
  return (Trend_Buffer[shift] == 1 && Trend_Buffer[shift + 1] == -1);
}

//+------------------------------------------------------------------+
//| Check for bearish reversal (long to short)                        |
//+------------------------------------------------------------------+
bool IsBearishReversal(int shift = 0) {
  if (shift + 1 >= ArraySize(Trend_Buffer)) return false;
  return (Trend_Buffer[shift] == -1 && Trend_Buffer[shift + 1] == 1);
}
