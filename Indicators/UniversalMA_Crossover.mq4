//+------------------------------------------------------------------+
//|                                          UniversalMA_Crossover.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal MA Crossover indicator with signals and alerts         |
//| Supports 30+ MA types for both fast and slow MAs                 |
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
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ Fast MA ══════";  // ─────────────────
input ENUM_MA_TYPE      Fast_Type = MA_EMA;          // MA Type
input int               Fast_Period = 8;             // Period
input ENUM_APPLIED_PRICE Fast_Price = PRICE_CLOSE;  // Applied Price
input color             Fast_Color = Lime;           // Line Color

input string            _sep2_ = "══════ Slow MA ══════"; // ─────────────────
input ENUM_MA_TYPE      Slow_Type = MA_EMA;          // MA Type
input int               Slow_Period = 21;            // Period
input ENUM_APPLIED_PRICE Slow_Price = PRICE_CLOSE;  // Applied Price
input color             Slow_Color = Red;            // Line Color

input string            _sep3_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (type-specific)
input double            OptParam2 = 0;               // Opt Param 2 (type-specific)

input string            _sep4_ = "══════ Signals ══════"; // ─────────────────
input bool              ShowArrows = true;           // Show Crossover Arrows
input int               ArrowSize = 2;               // Arrow Size (1-5)
input color             BuyArrowColor = Lime;        // Buy Arrow Color
input color             SellArrowColor = Red;        // Sell Arrow Color
input int               ArrowOffset = 10;            // Arrow Offset (pips from price)

input string            _sep5_ = "══════ Alerts ══════"; // ─────────────────
input bool              EnableAlerts = false;        // Enable Alerts
input bool              EnableSound = false;         // Enable Sound
input string            SoundFile = "alert.wav";     // Sound File
input bool              EnablePush = false;          // Enable Push Notifications
input bool              EnableEmail = false;         // Enable Email

input string            _sep6_ = "══════ Display ══════"; // ─────────────────
input bool              ShowLabel = true;            // Show Info Label
input bool              FillCloud = false;           // Fill Area Between MAs
input color             BullishCloud = C'50,205,50,80';  // Bullish Cloud Color
input color             BearishCloud = C'255,69,0,80';   // Bearish Cloud Color

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double FastMA_Buffer[];
double SlowMA_Buffer[];
double BuySignal_Buffer[];
double SellSignal_Buffer[];

datetime lastAlertTime = 0;
int lastAlertBar = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // Fast MA line
  SetIndexBuffer(0, FastMA_Buffer);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, Fast_Color);
  SetIndexLabel(0, MovingAverages::GetTypeName(Fast_Type) + "(" + IntegerToString(Fast_Period) + ")");

  // Slow MA line
  SetIndexBuffer(1, SlowMA_Buffer);
  SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, Slow_Color);
  SetIndexLabel(1, MovingAverages::GetTypeName(Slow_Type) + "(" + IntegerToString(Slow_Period) + ")");

  // Buy signals
  SetIndexBuffer(2, BuySignal_Buffer);
  if (ShowArrows) {
    SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, ArrowSize, BuyArrowColor);
    SetIndexArrow(2, 233);  // Up arrow
  } else {
    SetIndexStyle(2, DRAW_NONE);
  }
  SetIndexLabel(2, "Buy Signal");

  // Sell signals
  SetIndexBuffer(3, SellSignal_Buffer);
  if (ShowArrows) {
    SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, ArrowSize, SellArrowColor);
    SetIndexArrow(3, 234);  // Down arrow
  } else {
    SetIndexStyle(3, DRAW_NONE);
  }
  SetIndexLabel(3, "Sell Signal");

  // Set indicator name
  string shortName = MovingAverages::GetTypeName(Fast_Type) + "(" + IntegerToString(Fast_Period) + ") x " +
                     MovingAverages::GetTypeName(Slow_Type) + "(" + IntegerToString(Slow_Period) + ")";
  IndicatorShortName(shortName);

  if (ShowLabel)
    CreateInfoLabel();

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  ObjectDelete("UMAC_InfoLabel");
  ObjectDelete("UMAC_TrendLabel");

  // Delete cloud objects
  for (int i = ObjectsTotal() - 1; i >= 0; --i) {
    string name = ObjectName(i);
    if (StringFind(name, "UMAC_Cloud_") >= 0)
      ObjectDelete(name);
  }
}

//+------------------------------------------------------------------+
//| Create info label                                                 |
//+------------------------------------------------------------------+
void CreateInfoLabel() {
  ObjectCreate("UMAC_InfoLabel", OBJ_LABEL, 0, 0, 0);
  ObjectSet("UMAC_InfoLabel", OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("UMAC_InfoLabel", OBJPROP_XDISTANCE, 10);
  ObjectSet("UMAC_InfoLabel", OBJPROP_YDISTANCE, 30);
  ObjectSetText("UMAC_InfoLabel", "Initializing...", 9, "Arial", clrWhite);

  ObjectCreate("UMAC_TrendLabel", OBJ_LABEL, 0, 0, 0);
  ObjectSet("UMAC_TrendLabel", OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("UMAC_TrendLabel", OBJPROP_XDISTANCE, 10);
  ObjectSet("UMAC_TrendLabel", OBJPROP_YDISTANCE, 45);
}

//+------------------------------------------------------------------+
//| Update info label                                                 |
//+------------------------------------------------------------------+
void UpdateInfoLabel() {
  if (!ShowLabel) return;

  string fastName = MovingAverages::GetTypeName(Fast_Type);
  string slowName = MovingAverages::GetTypeName(Slow_Type);

  string info = fastName + "(" + IntegerToString(Fast_Period) + "): " + DoubleToStr(FastMA_Buffer[0], _Digits) +
                "  |  " + slowName + "(" + IntegerToString(Slow_Period) + "): " + DoubleToStr(SlowMA_Buffer[0], _Digits);

  ObjectSetText("UMAC_InfoLabel", info, 9, "Arial", clrWhite);

  // Trend info
  string trend;
  color trendColor;
  if (FastMA_Buffer[0] > SlowMA_Buffer[0]) {
    trend = "▲ BULLISH";
    trendColor = Lime;
  } else {
    trend = "▼ BEARISH";
    trendColor = Red;
  }

  double diff = MathAbs(FastMA_Buffer[0] - SlowMA_Buffer[0]) / _Point / 10;
  trend += "  (Spread: " + DoubleToStr(diff, 1) + " pips)";

  ObjectSetText("UMAC_TrendLabel", trend, 10, "Arial Bold", trendColor);
}

//+------------------------------------------------------------------+
//| Draw cloud between MAs                                            |
//+------------------------------------------------------------------+
void DrawCloud(int barIndex, datetime time1, double price1, double price2, bool bullish) {
  if (!FillCloud) return;

  string name = "UMAC_Cloud_" + IntegerToString(barIndex);

  if (ObjectFind(name) < 0) {
    ObjectCreate(name, OBJ_TREND, 0, time1, price1, time1, price2);
    ObjectSet(name, OBJPROP_RAY, false);
    ObjectSet(name, OBJPROP_WIDTH, 3);
    ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
  }

  ObjectSet(name, OBJPROP_PRICE1, price1);
  ObjectSet(name, OBJPROP_PRICE2, price2);
  ObjectSet(name, OBJPROP_COLOR, bullish ? BullishCloud : BearishCloud);
}

//+------------------------------------------------------------------+
//| Send alerts                                                       |
//+------------------------------------------------------------------+
void SendSignalAlert(bool isBuy, int barIndex) {
  // Only alert once per bar
  if (barIndex == lastAlertBar) return;
  lastAlertBar = barIndex;

  string direction = isBuy ? "BUY" : "SELL";
  string fastName = MovingAverages::GetTypeName(Fast_Type);
  string slowName = MovingAverages::GetTypeName(Slow_Type);

  string message = _Symbol + " " + PeriodToString() + ": " + direction + " Signal - " +
                   fastName + "(" + IntegerToString(Fast_Period) + ") crossed " +
                   slowName + "(" + IntegerToString(Slow_Period) + ")";

  if (EnableAlerts)
    Alert(message);

  if (EnableSound)
    PlaySound(SoundFile);

  if (EnablePush)
    SendNotification(message);

  if (EnableEmail)
    SendMail("MA Crossover Signal", message);

  Print(message);
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
  if (rates_total < maxPeriod + 2) return 0;

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - maxPeriod - 2;
  else
    limit = rates_total - prev_calculated + 1;

  // Ensure we don't exceed bounds
  if (limit > rates_total - maxPeriod - 2)
    limit = rates_total - maxPeriod - 2;

  double pipSize = _Point * 10;
  double arrowOffsetPrice = ArrowOffset * pipSize;

  // Calculate MA values and detect crossovers
  for (int i = limit; i >= 0; --i) {
    // Calculate current bar MAs
    FastMA_Buffer[i] = MovingAverages::Calculate(
      Fast_Type, _Symbol, _Period, Fast_Period, i, Fast_Price, OptParam1, OptParam2
    );

    SlowMA_Buffer[i] = MovingAverages::Calculate(
      Slow_Type, _Symbol, _Period, Slow_Period, i, Slow_Price, OptParam1, OptParam2
    );

    // Initialize signal buffers
    BuySignal_Buffer[i] = EMPTY_VALUE;
    SellSignal_Buffer[i] = EMPTY_VALUE;

    // Detect crossovers (need previous bar values)
    if (i < rates_total - maxPeriod - 2) {
      double fastPrev = FastMA_Buffer[i + 1];
      double slowPrev = SlowMA_Buffer[i + 1];
      double fastCurr = FastMA_Buffer[i];
      double slowCurr = SlowMA_Buffer[i];

      // Bullish crossover: fast crosses above slow
      if (fastPrev <= slowPrev && fastCurr > slowCurr) {
        BuySignal_Buffer[i] = low[i] - arrowOffsetPrice;
        if (i == 1)  // Just closed bar
          SendSignalAlert(true, i);
      }

      // Bearish crossover: fast crosses below slow
      if (fastPrev >= slowPrev && fastCurr < slowCurr) {
        SellSignal_Buffer[i] = high[i] + arrowOffsetPrice;
        if (i == 1)  // Just closed bar
          SendSignalAlert(false, i);
      }

      // Draw cloud if enabled
      if (FillCloud && i > 0) {
        bool bullish = fastCurr > slowCurr;
        DrawCloud(i, time[i], fastCurr, slowCurr, bullish);
      }
    }
  }

  // Update labels
  if (ShowLabel && prev_calculated > 0)
    UpdateInfoLabel();

  return rates_total;
}
//+------------------------------------------------------------------+
