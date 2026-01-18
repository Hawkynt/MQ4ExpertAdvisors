//+------------------------------------------------------------------+
//|                                       UniversalMovingAverage.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Universal Moving Average indicator with 30+ MA types             |
//| Drop onto any chart to visualize different MA algorithms         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 DodgerBlue
#property indicator_color2 Orange
#property indicator_width1 2
#property indicator_width2 2
#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep1_ = "══════ Primary MA ══════";  // ─────────────────
input ENUM_MA_TYPE      MA1_Type = MA_EMA;           // MA Type
input int               MA1_Period = 21;             // Period
input ENUM_APPLIED_PRICE MA1_Price = PRICE_CLOSE;   // Applied Price
input color             MA1_Color = DodgerBlue;      // Line Color
input int               MA1_Width = 2;               // Line Width
input ENUM_LINE_STYLE   MA1_Style = STYLE_SOLID;     // Line Style

input string            _sep2_ = "══════ Secondary MA ══════"; // ─────────────────
input bool              MA2_Enable = false;          // Enable Second MA
input ENUM_MA_TYPE      MA2_Type = MA_SMA;           // MA Type
input int               MA2_Period = 50;             // Period
input ENUM_APPLIED_PRICE MA2_Price = PRICE_CLOSE;   // Applied Price
input color             MA2_Color = Orange;          // Line Color
input int               MA2_Width = 2;               // Line Width
input ENUM_LINE_STYLE   MA2_Style = STYLE_SOLID;     // Line Style

input string            _sep3_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1 (T3:vFactor, ALMA:offset, KAMA:fast, JMA:phase, Gauss:poles, Laguerre:gamma)
input double            OptParam2 = 0;               // Opt Param 2 (ALMA:sigma, KAMA:slow)

input string            _sep4_ = "══════ Display ══════"; // ─────────────────
input bool              ShowLabel = true;            // Show MA Label on Chart
input int               LabelX = 10;                 // Label X Position
input int               LabelY = 30;                 // Label Y Position

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double MA1_Buffer[];
double MA2_Buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // Set up buffer 1
  SetIndexBuffer(0, MA1_Buffer);
  SetIndexStyle(0, DRAW_LINE, MA1_Style, MA1_Width, MA1_Color);
  SetIndexLabel(0, GetMALabel(MA1_Type, MA1_Period));

  // Set up buffer 2
  SetIndexBuffer(1, MA2_Buffer);
  if (MA2_Enable) {
    SetIndexStyle(1, DRAW_LINE, MA2_Style, MA2_Width, MA2_Color);
    SetIndexLabel(1, GetMALabel(MA2_Type, MA2_Period));
  } else {
    SetIndexStyle(1, DRAW_NONE);
    SetIndexLabel(1, NULL);
  }

  // Set indicator name
  string shortName = MovingAverages::GetTypeName(MA1_Type) + "(" + IntegerToString(MA1_Period) + ")";
  if (MA2_Enable)
    shortName += " / " + MovingAverages::GetTypeName(MA2_Type) + "(" + IntegerToString(MA2_Period) + ")";
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
  ObjectDelete("UMA_Label1");
  ObjectDelete("UMA_Label2");
  ObjectDelete("UMA_LabelBG");
}

//+------------------------------------------------------------------+
//| Get MA label string                                               |
//+------------------------------------------------------------------+
string GetMALabel(ENUM_MA_TYPE maType, int period) {
  return MovingAverages::GetTypeName(maType) + "(" + IntegerToString(period) + ")";
}

//+------------------------------------------------------------------+
//| Create on-chart labels                                            |
//+------------------------------------------------------------------+
void CreateLabels() {
  string label1 = MovingAverages::GetTypeName(MA1_Type) + "(" + IntegerToString(MA1_Period) + ")";

  ObjectCreate("UMA_Label1", OBJ_LABEL, 0, 0, 0);
  ObjectSet("UMA_Label1", OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("UMA_Label1", OBJPROP_XDISTANCE, LabelX);
  ObjectSet("UMA_Label1", OBJPROP_YDISTANCE, LabelY);
  ObjectSetText("UMA_Label1", label1, 10, "Arial Bold", MA1_Color);

  if (MA2_Enable) {
    string label2 = MovingAverages::GetTypeName(MA2_Type) + "(" + IntegerToString(MA2_Period) + ")";
    ObjectCreate("UMA_Label2", OBJ_LABEL, 0, 0, 0);
    ObjectSet("UMA_Label2", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSet("UMA_Label2", OBJPROP_XDISTANCE, LabelX);
    ObjectSet("UMA_Label2", OBJPROP_YDISTANCE, LabelY + 15);
    ObjectSetText("UMA_Label2", label2, 10, "Arial Bold", MA2_Color);
  }
}

//+------------------------------------------------------------------+
//| Update label values                                               |
//+------------------------------------------------------------------+
void UpdateLabels() {
  if (!ShowLabel) return;

  string label1 = MovingAverages::GetTypeName(MA1_Type) + "(" + IntegerToString(MA1_Period) + "): " + DoubleToStr(MA1_Buffer[0], _Digits);
  ObjectSetText("UMA_Label1", label1, 10, "Arial Bold", MA1_Color);

  if (MA2_Enable) {
    string label2 = MovingAverages::GetTypeName(MA2_Type) + "(" + IntegerToString(MA2_Period) + "): " + DoubleToStr(MA2_Buffer[0], _Digits);
    ObjectSetText("UMA_Label2", label2, 10, "Arial Bold", MA2_Color);
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

  if (rates_total < MA1_Period) return 0;

  int limit;
  if (prev_calculated == 0)
    limit = rates_total - 1;
  else
    limit = rates_total - prev_calculated + 1;

  // Ensure we don't exceed bounds
  if (limit > rates_total - MathMax(MA1_Period, MA2_Period) - 1)
    limit = rates_total - MathMax(MA1_Period, MA2_Period) - 1;

  // Calculate MA values
  for (int i = limit; i >= 0; --i) {
    MA1_Buffer[i] = MovingAverages::Calculate(
      MA1_Type,
      _Symbol,
      _Period,
      MA1_Period,
      i,
      MA1_Price,
      OptParam1,
      OptParam2
    );

    if (MA2_Enable) {
      MA2_Buffer[i] = MovingAverages::Calculate(
        MA2_Type,
        _Symbol,
        _Period,
        MA2_Period,
        i,
        MA2_Price,
        OptParam1,
        OptParam2
      );
    }
  }

  // Update labels with current values
  if (prev_calculated > 0)
    UpdateLabels();

  return rates_total;
}
//+------------------------------------------------------------------+
