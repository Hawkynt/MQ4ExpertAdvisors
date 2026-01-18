//+------------------------------------------------------------------+
//|                                            MA_TypeComparison.mq4 |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Compare up to 6 different MA types with the same period          |
//| Useful for visualizing lag, smoothness, and responsiveness       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1 DodgerBlue
#property indicator_color2 Lime
#property indicator_color3 Orange
#property indicator_color4 Magenta
#property indicator_color5 Yellow
#property indicator_color6 Aqua
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2
#property indicator_width5 2
#property indicator_width6 2

#include "../Libraries/Indicators/MovingAverages.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string            _sep0_ = "══════ Common Settings ══════";  // ─────────────────
input int               MA_Period = 21;              // Period (applied to all)
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE;    // Applied Price

input string            _sep1_ = "══════ MA 1 ══════";  // ─────────────────
input bool              MA1_Enable = true;           // Enable
input ENUM_MA_TYPE      MA1_Type = MA_SMA;           // Type
input color             MA1_Color = DodgerBlue;      // Color

input string            _sep2_ = "══════ MA 2 ══════";  // ─────────────────
input bool              MA2_Enable = true;           // Enable
input ENUM_MA_TYPE      MA2_Type = MA_EMA;           // Type
input color             MA2_Color = Lime;            // Color

input string            _sep3_ = "══════ MA 3 ══════";  // ─────────────────
input bool              MA3_Enable = true;           // Enable
input ENUM_MA_TYPE      MA3_Type = MA_HMA;           // Type
input color             MA3_Color = Orange;          // Color

input string            _sep4_ = "══════ MA 4 ══════";  // ─────────────────
input bool              MA4_Enable = true;           // Enable
input ENUM_MA_TYPE      MA4_Type = MA_TEMA;          // Type
input color             MA4_Color = Magenta;         // Color

input string            _sep5_ = "══════ MA 5 ══════";  // ─────────────────
input bool              MA5_Enable = false;          // Enable
input ENUM_MA_TYPE      MA5_Type = MA_KAMA;          // Type
input color             MA5_Color = Yellow;          // Color

input string            _sep6_ = "══════ MA 6 ══════";  // ─────────────────
input bool              MA6_Enable = false;          // Enable
input ENUM_MA_TYPE      MA6_Type = MA_ALMA;          // Type
input color             MA6_Color = Aqua;            // Color

input string            _sep7_ = "══════ Optional Parameters ══════"; // ─────────────────
input double            OptParam1 = 0;               // Opt Param 1
input double            OptParam2 = 0;               // Opt Param 2

input string            _sep8_ = "══════ Display ══════"; // ─────────────────
input bool              ShowLegend = true;           // Show Legend
input int               LegendX = 10;                // Legend X Position
input int               LegendY = 30;                // Legend Y Position

//+------------------------------------------------------------------+
//| Indicator Buffers                                                 |
//+------------------------------------------------------------------+
double MA_Buffer1[];
double MA_Buffer2[];
double MA_Buffer3[];
double MA_Buffer4[];
double MA_Buffer5[];
double MA_Buffer6[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit() {
  // Set up all 6 buffers
  SetupBuffer(0, MA_Buffer1, MA1_Enable, MA1_Type, MA1_Color);
  SetupBuffer(1, MA_Buffer2, MA2_Enable, MA2_Type, MA2_Color);
  SetupBuffer(2, MA_Buffer3, MA3_Enable, MA3_Type, MA3_Color);
  SetupBuffer(3, MA_Buffer4, MA4_Enable, MA4_Type, MA4_Color);
  SetupBuffer(4, MA_Buffer5, MA5_Enable, MA5_Type, MA5_Color);
  SetupBuffer(5, MA_Buffer6, MA6_Enable, MA6_Type, MA6_Color);

  // Build short name
  string shortName = "MA Compare(" + IntegerToString(MA_Period) + "): ";
  if (MA1_Enable) shortName += MovingAverages::GetTypeName(MA1_Type) + " ";
  if (MA2_Enable) shortName += MovingAverages::GetTypeName(MA2_Type) + " ";
  if (MA3_Enable) shortName += MovingAverages::GetTypeName(MA3_Type) + " ";
  if (MA4_Enable) shortName += MovingAverages::GetTypeName(MA4_Type) + " ";
  if (MA5_Enable) shortName += MovingAverages::GetTypeName(MA5_Type) + " ";
  if (MA6_Enable) shortName += MovingAverages::GetTypeName(MA6_Type) + " ";
  IndicatorShortName(shortName);

  if (ShowLegend)
    CreateLegend();

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Setup indicator buffer                                            |
//+------------------------------------------------------------------+
void SetupBuffer(int index, double &buffer[], bool enable, ENUM_MA_TYPE maType, color clr) {
  SetIndexBuffer(index, buffer);
  if (enable) {
    SetIndexStyle(index, DRAW_LINE, STYLE_SOLID, 2, clr);
    SetIndexLabel(index, MovingAverages::GetTypeName(maType) + "(" + IntegerToString(MA_Period) + ")");
  } else {
    SetIndexStyle(index, DRAW_NONE);
    SetIndexLabel(index, NULL);
  }
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  for (int i = 1; i <= 6; ++i) {
    ObjectDelete("MATC_Legend" + IntegerToString(i));
    ObjectDelete("MATC_Value" + IntegerToString(i));
  }
  ObjectDelete("MATC_Header");
}

//+------------------------------------------------------------------+
//| Create legend                                                     |
//+------------------------------------------------------------------+
void CreateLegend() {
  int y = LegendY;

  ObjectCreate("MATC_Header", OBJ_LABEL, 0, 0, 0);
  ObjectSet("MATC_Header", OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("MATC_Header", OBJPROP_XDISTANCE, LegendX);
  ObjectSet("MATC_Header", OBJPROP_YDISTANCE, y);
  ObjectSetText("MATC_Header", "MA Comparison (Period: " + IntegerToString(MA_Period) + ")", 9, "Arial Bold", clrWhite);

  y += 18;
  if (MA1_Enable) { CreateLegendEntry(1, MA1_Type, MA1_Color, y); y += 15; }
  if (MA2_Enable) { CreateLegendEntry(2, MA2_Type, MA2_Color, y); y += 15; }
  if (MA3_Enable) { CreateLegendEntry(3, MA3_Type, MA3_Color, y); y += 15; }
  if (MA4_Enable) { CreateLegendEntry(4, MA4_Type, MA4_Color, y); y += 15; }
  if (MA5_Enable) { CreateLegendEntry(5, MA5_Type, MA5_Color, y); y += 15; }
  if (MA6_Enable) { CreateLegendEntry(6, MA6_Type, MA6_Color, y); y += 15; }
}

//+------------------------------------------------------------------+
//| Create legend entry                                               |
//+------------------------------------------------------------------+
void CreateLegendEntry(int index, ENUM_MA_TYPE maType, color clr, int y) {
  string name = MovingAverages::GetTypeName(maType);

  ObjectCreate("MATC_Legend" + IntegerToString(index), OBJ_LABEL, 0, 0, 0);
  ObjectSet("MATC_Legend" + IntegerToString(index), OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("MATC_Legend" + IntegerToString(index), OBJPROP_XDISTANCE, LegendX);
  ObjectSet("MATC_Legend" + IntegerToString(index), OBJPROP_YDISTANCE, y);
  ObjectSetText("MATC_Legend" + IntegerToString(index), "■ " + name + ":", 9, "Arial", clr);

  ObjectCreate("MATC_Value" + IntegerToString(index), OBJ_LABEL, 0, 0, 0);
  ObjectSet("MATC_Value" + IntegerToString(index), OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet("MATC_Value" + IntegerToString(index), OBJPROP_XDISTANCE, LegendX + 100);
  ObjectSet("MATC_Value" + IntegerToString(index), OBJPROP_YDISTANCE, y);
}

//+------------------------------------------------------------------+
//| Update legend values                                              |
//+------------------------------------------------------------------+
void UpdateLegend() {
  if (!ShowLegend) return;

  if (MA1_Enable) ObjectSetText("MATC_Value1", DoubleToStr(MA_Buffer1[0], _Digits), 9, "Arial", MA1_Color);
  if (MA2_Enable) ObjectSetText("MATC_Value2", DoubleToStr(MA_Buffer2[0], _Digits), 9, "Arial", MA2_Color);
  if (MA3_Enable) ObjectSetText("MATC_Value3", DoubleToStr(MA_Buffer3[0], _Digits), 9, "Arial", MA3_Color);
  if (MA4_Enable) ObjectSetText("MATC_Value4", DoubleToStr(MA_Buffer4[0], _Digits), 9, "Arial", MA4_Color);
  if (MA5_Enable) ObjectSetText("MATC_Value5", DoubleToStr(MA_Buffer5[0], _Digits), 9, "Arial", MA5_Color);
  if (MA6_Enable) ObjectSetText("MATC_Value6", DoubleToStr(MA_Buffer6[0], _Digits), 9, "Arial", MA6_Color);
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

  // Calculate all enabled MAs
  for (int i = limit; i >= 0; --i) {
    if (MA1_Enable)
      MA_Buffer1[i] = MovingAverages::Calculate(MA1_Type, _Symbol, _Period, MA_Period, i, MA_Price, OptParam1, OptParam2);

    if (MA2_Enable)
      MA_Buffer2[i] = MovingAverages::Calculate(MA2_Type, _Symbol, _Period, MA_Period, i, MA_Price, OptParam1, OptParam2);

    if (MA3_Enable)
      MA_Buffer3[i] = MovingAverages::Calculate(MA3_Type, _Symbol, _Period, MA_Period, i, MA_Price, OptParam1, OptParam2);

    if (MA4_Enable)
      MA_Buffer4[i] = MovingAverages::Calculate(MA4_Type, _Symbol, _Period, MA_Period, i, MA_Price, OptParam1, OptParam2);

    if (MA5_Enable)
      MA_Buffer5[i] = MovingAverages::Calculate(MA5_Type, _Symbol, _Period, MA_Period, i, MA_Price, OptParam1, OptParam2);

    if (MA6_Enable)
      MA_Buffer6[i] = MovingAverages::Calculate(MA6_Type, _Symbol, _Period, MA_Period, i, MA_Price, OptParam1, OptParam2);
  }

  if (prev_calculated > 0)
    UpdateLegend();

  return rates_total;
}
//+------------------------------------------------------------------+
