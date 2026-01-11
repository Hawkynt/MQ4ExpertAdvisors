#include "../IMoneyManager.mqh"
#include "../OrderCollection.mqh"

class MoneyManagers__MaxExposureCap : public IMoneyManager {
private:
  IMoneyManager* _baseManager;
  double _maxTotalLots;
  double _maxLotsPerSymbol;
  bool _ownsBaseManager;

public:
  MoneyManagers__MaxExposureCap(IMoneyManager* baseManager, double maxTotalLots = 10.0, double maxLotsPerSymbol = 5.0, bool ownsBaseManager = false) {
    this._baseManager = baseManager;
    this._maxTotalLots = maxTotalLots;
    this._maxLotsPerSymbol = maxLotsPerSymbol;
    this._ownsBaseManager = ownsBaseManager;
  }

  ~MoneyManagers__MaxExposureCap() {
    if (this._ownsBaseManager && this._baseManager != NULL)
      delete this._baseManager;
    this._baseManager = NULL;
  }

  double MaxTotalLots() { return this._maxTotalLots; }
  void MaxTotalLots(double value) { this._maxTotalLots = value; }
  double MaxLotsPerSymbol() { return this._maxLotsPerSymbol; }
  void MaxLotsPerSymbol(double value) { this._maxLotsPerSymbol = value; }

  virtual double CalculateLots(Order* order) {
    if (this._baseManager == NULL)
      return 0;

    OrderCollection* openOrders = OrderCollection::GetOpenOrders();

    double totalLots = openOrders.Lots();

    OrderCollection* symbolOrders = openOrders.Copy();
    symbolOrders.FilterBySymbolName(order.SymbolName());
    double symbolLots = symbolOrders.Lots();
    delete symbolOrders;
    delete openOrders;

    double baseLots = this._baseManager.CalculateLots(order);

    double remainingTotal = this._maxTotalLots - totalLots;
    if (remainingTotal <= 0)
      return 0;

    double remainingSymbol = this._maxLotsPerSymbol - symbolLots;
    if (remainingSymbol <= 0)
      return 0;

    return MathMin(baseLots, MathMin(remainingTotal, remainingSymbol));
  }
};
