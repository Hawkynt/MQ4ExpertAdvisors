#include "AExistingOrdersManager.mqh"

class OrderManagers__VolatilityAdjustedStopLoss : public OrderManagers__AExistingOrdersManager {
private:
  int _atrPeriod;
  int _timeframe;
  double _atrMultiplier;
  double _baseATR;
  double _minStopPips;
  double _maxStopPips;

  double _GetCurrentATR(string symbol) {
    return iATR(symbol, this._timeframe, this._atrPeriod, 0);
  }

public:
  OrderManagers__VolatilityAdjustedStopLoss(
    int atrPeriod = 14,
    int timeframe = PERIOD_H1,
    double atrMultiplier = 2.0,
    double baseATR = 0.001,
    double minStopPips = 10.0,
    double maxStopPips = 100.0,
    string symbolName = ""
  ) : OrderManagers__AExistingOrdersManager() {
    this.SymbolNameFilter(symbolName);
    this._atrPeriod = atrPeriod;
    this._timeframe = timeframe;
    this._atrMultiplier = atrMultiplier;
    this._baseATR = baseATR;
    this._minStopPips = minStopPips;
    this._maxStopPips = maxStopPips;
  }

  int ATRPeriod() { return this._atrPeriod; }
  void ATRPeriod(int value) { this._atrPeriod = value; }
  int Timeframe() { return this._timeframe; }
  void Timeframe(int value) { this._timeframe = value; }
  double ATRMultiplier() { return this._atrMultiplier; }
  void ATRMultiplier(double value) { this._atrMultiplier = value; }
  double BaseATR() { return this._baseATR; }
  void BaseATR(double value) { this._baseATR = value; }
  double MinStopPips() { return this._minStopPips; }
  void MinStopPips(double value) { this._minStopPips = value; }
  double MaxStopPips() { return this._maxStopPips; }
  void MaxStopPips(double value) { this._maxStopPips = value; }

  virtual void _ManageSingleOrder(Order* order) {
    if (!order.IsMarket())
      return;

    string symbol = order.SymbolName();
    double currentATR = _GetCurrentATR(symbol);
    if (currentATR <= 0)
      return;

    double volatilityRatio = currentATR / this._baseATR;
    double pipSize = MarketInfo(symbol, MODE_POINT) * 10;
    double stopDistancePips = this._atrMultiplier * (currentATR / pipSize);

    stopDistancePips = MathMax(stopDistancePips, this._minStopPips);
    stopDistancePips = MathMin(stopDistancePips, this._maxStopPips);

    double stopDistance = stopDistancePips * pipSize;
    double newStopLoss;

    if (order.IsBuy()) {
      double currentPrice = MarketInfo(symbol, MODE_BID);
      newStopLoss = currentPrice - stopDistance;
      if (order.StopLoss() == 0 || newStopLoss > order.StopLoss())
        order.StopLoss(newStopLoss);
    } else {
      double currentPrice = MarketInfo(symbol, MODE_ASK);
      newStopLoss = currentPrice + stopDistance;
      if (order.StopLoss() == 0 || newStopLoss < order.StopLoss())
        order.StopLoss(newStopLoss);
    }
  }
};
