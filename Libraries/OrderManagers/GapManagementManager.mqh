#include "AExistingOrdersManager.mqh"

class OrderManagers__GapManagementManager : public OrderManagers__AExistingOrdersManager {
private:
  double _maxGapPips;
  bool _closeOnGap;
  bool _adjustStopOnGap;
  double _stopAdjustmentPips;
  double _lastFridayClose[];
  string _lastSymbols[];

  double _GetLastFridayClose(string symbol) {
    for (int i = ArraySize(this._lastSymbols) - 1; i >= 0; --i)
      if (this._lastSymbols[i] == symbol)
        return this._lastFridayClose[i];
    return 0;
  }

  void _StoreFridayClose(string symbol, double price) {
    for (int i = ArraySize(this._lastSymbols) - 1; i >= 0; --i) {
      if (this._lastSymbols[i] == symbol) {
        this._lastFridayClose[i] = price;
        return;
      }
    }

    int size = ArraySize(this._lastSymbols);
    ArrayResize(this._lastSymbols, size + 1);
    ArrayResize(this._lastFridayClose, size + 1);
    this._lastSymbols[size] = symbol;
    this._lastFridayClose[size] = price;
  }

  bool _IsMarketJustOpened() {
    int dayOfWeek = TimeDayOfWeek(TimeCurrent());
    int hour = TimeHour(TimeCurrent());
    return (dayOfWeek == 1 && hour < 1);
  }

public:
  OrderManagers__GapManagementManager(
    double maxGapPips = 50.0,
    bool closeOnGap = true,
    bool adjustStopOnGap = true,
    double stopAdjustmentPips = 10.0,
    string symbolName = ""
  ) : OrderManagers__AExistingOrdersManager() {
    this.SymbolNameFilter(symbolName);
    this._maxGapPips = maxGapPips;
    this._closeOnGap = closeOnGap;
    this._adjustStopOnGap = adjustStopOnGap;
    this._stopAdjustmentPips = stopAdjustmentPips;
  }

  ~OrderManagers__GapManagementManager() {
    ArrayResize(this._lastFridayClose, 0);
    ArrayResize(this._lastSymbols, 0);
  }

  double MaxGapPips() { return this._maxGapPips; }
  void MaxGapPips(double value) { this._maxGapPips = value; }
  bool CloseOnGap() { return this._closeOnGap; }
  void CloseOnGap(bool value) { this._closeOnGap = value; }
  bool AdjustStopOnGap() { return this._adjustStopOnGap; }
  void AdjustStopOnGap(bool value) { this._adjustStopOnGap = value; }
  double StopAdjustmentPips() { return this._stopAdjustmentPips; }
  void StopAdjustmentPips(double value) { this._stopAdjustmentPips = value; }

  void StoreFridayCloses() {
    int dayOfWeek = TimeDayOfWeek(TimeCurrent());
    if (dayOfWeek != 5)
      return;

    int hour = TimeHour(TimeCurrent());
    if (hour < 21)
      return;

    OrderCollection* orders = OrderCollection::GetOpenOrders();
    for (int i = orders.Count() - 1; i >= 0; --i) {
      Order* order = orders.Item(i);
      string symbol = order.SymbolName();
      double closePrice = MarketInfo(symbol, MODE_BID);
      _StoreFridayClose(symbol, closePrice);
    }
    delete orders;
  }

  virtual void _ManageSingleOrder(Order* order) {
    if (!order.IsMarket())
      return;

    if (!_IsMarketJustOpened())
      return;

    string symbol = order.SymbolName();
    double fridayClose = _GetLastFridayClose(symbol);
    if (fridayClose == 0)
      return;

    double currentPrice = (order.IsBuy()) ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);
    double pipSize = MarketInfo(symbol, MODE_POINT) * 10;
    double gapPips = MathAbs(currentPrice - fridayClose) / pipSize;

    if (gapPips < this._maxGapPips)
      return;

    bool gapAgainstOrder = false;
    if (order.IsBuy() && currentPrice < fridayClose)
      gapAgainstOrder = true;
    else if (order.IsSell() && currentPrice > fridayClose)
      gapAgainstOrder = true;

    if (!gapAgainstOrder)
      return;

    if (this._closeOnGap) {
      order.Close();
      return;
    }

    if (this._adjustStopOnGap && order.StopLoss() != 0) {
      double adjustment = this._stopAdjustmentPips * pipSize;
      double newStop;

      if (order.IsBuy())
        newStop = order.StopLoss() - adjustment;
      else
        newStop = order.StopLoss() + adjustment;

      order.StopLoss(newStop);
    }
  }
};
