#include "AExistingOrdersManager.mqh"
#include "../IMoneyManager.mqh"
#include "../IMarketIndicator.mqh"

class OrderManagers__AntiMartingaleScaler : public IOrderManager {
private:
  IMoneyManager* _moneyManager;
  IMarketIndicator* _indicator;
  double _profitThresholdPips;
  double _scaleMultiplier;
  int _maxScaleOrders;
  double _minDistancePips;
  bool _ownsMoneyManager;
  bool _ownsIndicator;
  int _currentScaleCount;

public:
  OrderManagers__AntiMartingaleScaler(
    IMoneyManager* moneyManager,
    IMarketIndicator* indicator,
    double profitThresholdPips = 20.0,
    double scaleMultiplier = 0.5,
    int maxScaleOrders = 3,
    double minDistancePips = 10.0,
    string symbolName = "",
    bool ownsMoneyManager = false,
    bool ownsIndicator = false
  ) : IOrderManager() {
    this.SymbolNameFilter(symbolName);
    this._moneyManager = moneyManager;
    this._indicator = indicator;
    this._profitThresholdPips = profitThresholdPips;
    this._scaleMultiplier = scaleMultiplier;
    this._maxScaleOrders = maxScaleOrders;
    this._minDistancePips = minDistancePips;
    this._ownsMoneyManager = ownsMoneyManager;
    this._ownsIndicator = ownsIndicator;
    this._currentScaleCount = 0;
  }

  ~OrderManagers__AntiMartingaleScaler() {
    if (this._ownsMoneyManager && this._moneyManager != NULL)
      delete this._moneyManager;
    if (this._ownsIndicator && this._indicator != NULL)
      delete this._indicator;
  }

  double ProfitThresholdPips() { return this._profitThresholdPips; }
  void ProfitThresholdPips(double value) { this._profitThresholdPips = value; }
  double ScaleMultiplier() { return this._scaleMultiplier; }
  void ScaleMultiplier(double value) { this._scaleMultiplier = value; }
  int MaxScaleOrders() { return this._maxScaleOrders; }
  void MaxScaleOrders(int value) { this._maxScaleOrders = value; }
  double MinDistancePips() { return this._minDistancePips; }
  void MinDistancePips(double value) { this._minDistancePips = value; }

  virtual void Manage() {
    OrderCollection* orders = OrderCollection::GetOpenOrders();

    if (this.IsSymbolNameFilterPresent())
      orders.FilterBySymbolName(this.SymbolNameFilter());
    if (this.IsMagicNumberFilterPresent())
      orders.FilterByMagicNumber(this.MagicNumberFilter());

    for (int i = orders.Count() - 1; i >= 0; --i) {
      Order* order = orders.Item(i);
      _CheckAndScale(order);
    }

    delete orders;
  }

private:
  void _CheckAndScale(Order* order) {
    if (this._currentScaleCount >= this._maxScaleOrders)
      return;

    double profitPips = order.RealPipsProfit();
    if (profitPips < this._profitThresholdPips)
      return;

    if (!_IsTrendConfirmed(order))
      return;

    if (!_IsSufficientDistance(order))
      return;

    double baseLots = order.Lots();
    double scaleLots = baseLots * this._scaleMultiplier;

    if (this._moneyManager != NULL) {
      double mmLots = this._moneyManager.CalculateLots(order);
      scaleLots = MathMin(scaleLots, mmLots);
    }

    string symbol = order.SymbolName();
    scaleLots = NormalizeDouble(scaleLots, 2);

    double minLot = MarketInfo(symbol, MODE_MINLOT);
    if (scaleLots < minLot)
      return;

    int cmd = order.Type();
    double price = (cmd == OP_BUY) ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);

    int ticket = OrderSend(symbol, cmd, scaleLots, price, 3, 0, 0, "Scale", order.MagicNumber(), 0, clrNONE);
    if (ticket >= 0)
      ++this._currentScaleCount;
  }

  bool _IsTrendConfirmed(Order* order) {
    if (this._indicator == NULL)
      return true;

    if (order.IsBuy())
      return this._indicator.IsLongTrend();
    return this._indicator.IsShortTrend();
  }

  bool _IsSufficientDistance(Order* order) {
    string symbol = order.SymbolName();
    double pipSize = MarketInfo(symbol, MODE_POINT) * 10;
    double currentPrice = (order.IsBuy()) ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);
    double distance = MathAbs(currentPrice - order.OpenPrice()) / pipSize;
    return distance >= this._minDistancePips;
  }
};
