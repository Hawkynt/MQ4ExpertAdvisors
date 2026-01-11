#include "AExistingOrdersManager.mqh"

class OrderManagers__PartialTakeProfit : public OrderManagers__AExistingOrdersManager {
private:
  float _targetPips;
  double _closePercent;
  bool _moveStopToBreakEven;
  string _partialCloseMarker;

  bool _IsPartiallyClosedAlready(Order* order) {
    string comment = order.Comment();
    return StringFind(comment, this._partialCloseMarker) >= 0;
  }

public:
  OrderManagers__PartialTakeProfit(float targetPips, double closePercent = 50, bool moveStopToBreakEven = true, string symbolName = NULL, bool manageBuy = true, bool manageSell = true) {
    this.SymbolNameFilter(symbolName);
    this.IsManagingBuyOrders(manageBuy);
    this.IsManagingSellOrders(manageSell);
    this._targetPips = targetPips;
    this._closePercent = MathMin(99, MathMax(1, closePercent));
    this._moveStopToBreakEven = moveStopToBreakEven;
    this._partialCloseMarker = "[partial]";
  }

  float TargetPips() { return this._targetPips; }
  void TargetPips(float value) { this._targetPips = value; }
  double ClosePercent() { return this._closePercent; }
  void ClosePercent(double value) { this._closePercent = MathMin(99, MathMax(1, value)); }
  bool MoveStopToBreakEven() { return this._moveStopToBreakEven; }
  void MoveStopToBreakEven(bool value) { this._moveStopToBreakEven = value; }

  void _ManageSingleOrder(Order* order) {
    if (!order.IsMarket())
      return;

    if (_IsPartiallyClosedAlready(order))
      return;

    if (order.RealPipsProfit() < this._targetPips)
      return;

    double currentLots = order.Lots();
    double lotsToClose = NormalizeDouble(currentLots * this._closePercent / 100.0, 2);
    double minLots = order.Symbol().MinLots();
    double lotStep = order.Symbol().LotStep();

    lotsToClose = MathFloor(lotsToClose / lotStep) * lotStep;
    if (lotsToClose < minLots)
      lotsToClose = minLots;

    double remainingLots = currentLots - lotsToClose;
    if (remainingLots < minLots)
      lotsToClose = currentLots - minLots;

    if (lotsToClose < minLots)
      return;

    double closePrice = order.IsBuy() ? order.Symbol().Bid() : order.Symbol().Ask();
    if (OrderClose(order.Ticket(), lotsToClose, closePrice, 0, order.IsBuy() ? Lime : Red)) {
      if (this._moveStopToBreakEven)
        order.TrailingStopLossPipsToOpen(0);
    }
  }
};
