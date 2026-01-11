#include "AExistingOrdersManager.mqh"

class OrderManagers__ATRTrailingStop : public OrderManagers__AExistingOrdersManager {
private:
  int _atrPeriod;
  double _atrMultiplier;
  int _timeframe;
  float _minProfitToActivate;

  double _GetATRPips(string symbolName) {
    Instrument* inst = Instrument::FromName(symbolName);
    double atr = iATR(symbolName, this._timeframe, this._atrPeriod, 0);
    double pips = atr / inst.PipSize();
    delete inst;
    return pips;
  }

public:
  OrderManagers__ATRTrailingStop(int atrPeriod = 14, double atrMultiplier = 2.0, int timeframe = PERIOD_H1, float minProfitToActivate = 0, string symbolName = NULL, bool manageBuy = true, bool manageSell = true) {
    this.SymbolNameFilter(symbolName);
    this.IsManagingBuyOrders(manageBuy);
    this.IsManagingSellOrders(manageSell);
    this._atrPeriod = atrPeriod;
    this._atrMultiplier = atrMultiplier;
    this._timeframe = timeframe;
    this._minProfitToActivate = minProfitToActivate;
  }

  int ATRPeriod() { return this._atrPeriod; }
  void ATRPeriod(int value) { this._atrPeriod = value; }
  double ATRMultiplier() { return this._atrMultiplier; }
  void ATRMultiplier(double value) { this._atrMultiplier = value; }
  int Timeframe() { return this._timeframe; }
  void Timeframe(int value) { this._timeframe = value; }
  float MinProfitToActivate() { return this._minProfitToActivate; }
  void MinProfitToActivate(float value) { this._minProfitToActivate = value; }

  void _ManageSingleOrder(Order* order) {
    if (!order.IsMarket())
      return;

    double currentProfit = order.RealPipsProfit();
    if (currentProfit < this._minProfitToActivate)
      return;

    double atrPips = _GetATRPips(order.SymbolName()) * this._atrMultiplier;
    if (atrPips <= 0)
      return;

    order.TrailingStopLossPipsToClose(-atrPips);
  }
};
