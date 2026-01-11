#include "AExistingOrdersManager.mqh"
#include "../IMoneyManager.mqh"

class OrderManagers__OppositePositionHedge : public OrderManagers__AExistingOrdersManager {
private:
  double _lossThresholdPips;
  double _hedgeRatio;
  IMoneyManager* _moneyManager;
  bool _ownsMoneyManager;
  int _hedgedTickets[];

  bool _IsAlreadyHedged(int ticket) {
    for (int i = ArraySize(this._hedgedTickets) - 1; i >= 0; --i)
      if (this._hedgedTickets[i] == ticket)
        return true;
    return false;
  }

  void _MarkAsHedged(int ticket) {
    int size = ArraySize(this._hedgedTickets);
    ArrayResize(this._hedgedTickets, size + 1);
    this._hedgedTickets[size] = ticket;
  }

public:
  OrderManagers__OppositePositionHedge(
    double lossThresholdPips = 30.0,
    double hedgeRatio = 0.5,
    IMoneyManager* moneyManager = NULL,
    string symbolName = "",
    bool ownsMoneyManager = false
  ) : OrderManagers__AExistingOrdersManager() {
    this.SymbolNameFilter(symbolName);
    this._lossThresholdPips = lossThresholdPips;
    this._hedgeRatio = hedgeRatio;
    this._moneyManager = moneyManager;
    this._ownsMoneyManager = ownsMoneyManager;
  }

  ~OrderManagers__OppositePositionHedge() {
    if (this._ownsMoneyManager && this._moneyManager != NULL)
      delete this._moneyManager;
    ArrayResize(this._hedgedTickets, 0);
  }

  double LossThresholdPips() { return this._lossThresholdPips; }
  void LossThresholdPips(double value) { this._lossThresholdPips = value; }
  double HedgeRatio() { return this._hedgeRatio; }
  void HedgeRatio(double value) { this._hedgeRatio = value; }

  virtual void _ManageSingleOrder(Order* order) {
    if (!order.IsMarket())
      return;

    double lossPips = -order.RealPipsProfit();
    if (lossPips < this._lossThresholdPips)
      return;

    int ticket = order.Ticket();
    if (_IsAlreadyHedged(ticket))
      return;

    string symbol = order.SymbolName();
    double hedgeLots = order.Lots() * this._hedgeRatio;

    if (this._moneyManager != NULL) {
      double mmLots = this._moneyManager.CalculateLots(order);
      hedgeLots = MathMin(hedgeLots, mmLots);
    }

    hedgeLots = NormalizeDouble(hedgeLots, 2);
    double minLot = MarketInfo(symbol, MODE_MINLOT);
    if (hedgeLots < minLot)
      return;

    int hedgeCmd = (order.IsBuy()) ? OP_SELL : OP_BUY;
    double price = (hedgeCmd == OP_BUY) ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);

    int hedgeTicket = OrderSend(symbol, hedgeCmd, hedgeLots, price, 3, 0, 0, "Hedge", order.MagicNumber(), 0, clrNONE);
    if (hedgeTicket >= 0)
      _MarkAsHedged(ticket);
  }
};
