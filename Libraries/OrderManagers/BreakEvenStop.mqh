#include "AExistingOrdersManager.mqh"

class OrderManagers__BreakEvenStop : public OrderManagers__AExistingOrdersManager {
private:
  float _triggerPips;
  float _lockInPips;

public:
  OrderManagers__BreakEvenStop(float triggerPips, float lockInPips = 0, string symbolName = NULL, bool manageBuy = true, bool manageSell = true) {
    this.SymbolNameFilter(symbolName);
    this.IsManagingBuyOrders(manageBuy);
    this.IsManagingSellOrders(manageSell);
    this._triggerPips = triggerPips;
    this._lockInPips = lockInPips;
  }

  float TriggerPips() { return this._triggerPips; }
  void TriggerPips(float value) { this._triggerPips = value; }
  float LockInPips() { return this._lockInPips; }
  void LockInPips(float value) { this._lockInPips = value; }

  void _ManageSingleOrder(Order* order) {
    if (order.HasStopLoss() && order.StopLossPipsToOpen() >= this._lockInPips)
      return;

    if (order.RealPipsProfit() >= this._triggerPips)
      order.TrailingStopLossPipsToOpen(this._lockInPips);
  }
};
