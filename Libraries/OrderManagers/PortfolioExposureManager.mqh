#include "../IOrderManager.mqh"
#include "../OrderCollection.mqh"

class OrderManagers__PortfolioExposureManager : public IOrderManager {
private:
  double _maxTotalExposure;
  double _maxExposurePerSymbol;
  bool _closeWorstOnExceed;

public:
  OrderManagers__PortfolioExposureManager(
    double maxTotalExposure = 10.0,
    double maxExposurePerSymbol = 5.0,
    bool closeWorstOnExceed = true
  ) : IOrderManager() {
    this._maxTotalExposure = maxTotalExposure;
    this._maxExposurePerSymbol = maxExposurePerSymbol;
    this._closeWorstOnExceed = closeWorstOnExceed;
  }

  double MaxTotalExposure() { return this._maxTotalExposure; }
  void MaxTotalExposure(double value) { this._maxTotalExposure = value; }
  double MaxExposurePerSymbol() { return this._maxExposurePerSymbol; }
  void MaxExposurePerSymbol(double value) { this._maxExposurePerSymbol = value; }
  bool CloseWorstOnExceed() { return this._closeWorstOnExceed; }
  void CloseWorstOnExceed(bool value) { this._closeWorstOnExceed = value; }

  virtual void Manage() {
    OrderCollection* orders = OrderCollection::GetOpenOrders();

    if (this.IsMagicNumberFilterPresent())
      orders.FilterByMagicNumber(this.MagicNumberFilter());

    double totalExposure = orders.Lots();

    if (totalExposure > this._maxTotalExposure && this._closeWorstOnExceed) {
      Order* worst = orders.GetWorstPerformingOrder();
      if (worst != NULL)
        worst.Close();
    }

    _CheckSymbolExposures(orders);

    delete orders;
  }

private:
  void _CheckSymbolExposures(OrderCollection* orders) {
    string checkedSymbols[];
    int symbolCount = 0;

    for (int i = orders.Count() - 1; i >= 0; --i) {
      Order* order = orders.Item(i);
      string symbol = order.SymbolName();

      bool alreadyChecked = false;
      for (int j = 0; j < symbolCount; ++j) {
        if (checkedSymbols[j] == symbol) {
          alreadyChecked = true;
          break;
        }
      }

      if (alreadyChecked)
        continue;

      ArrayResize(checkedSymbols, symbolCount + 1);
      checkedSymbols[symbolCount] = symbol;
      ++symbolCount;

      OrderCollection* symbolOrders = orders.Copy();
      symbolOrders.FilterBySymbolName(symbol);
      double symbolExposure = symbolOrders.Lots();

      if (symbolExposure > this._maxExposurePerSymbol && this._closeWorstOnExceed) {
        Order* worst = symbolOrders.GetWorstPerformingOrder();
        if (worst != NULL)
          worst.Close();
      }

      delete symbolOrders;
    }
  }
};
