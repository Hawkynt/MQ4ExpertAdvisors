#include "../IOrderManager.mqh"
#include "../OrderCollection.mqh"

class OrderManagers__DirectionalBiasManager : public IOrderManager {
private:
  double _maxDirectionalBias;
  bool _closeOnExceed;
  bool _preventNewOrders;

public:
  OrderManagers__DirectionalBiasManager(
    double maxDirectionalBias = 0.7,
    bool closeOnExceed = true,
    bool preventNewOrders = false
  ) : IOrderManager() {
    this._maxDirectionalBias = maxDirectionalBias;
    this._closeOnExceed = closeOnExceed;
    this._preventNewOrders = preventNewOrders;
  }

  double MaxDirectionalBias() { return this._maxDirectionalBias; }
  void MaxDirectionalBias(double value) { this._maxDirectionalBias = value; }
  bool CloseOnExceed() { return this._closeOnExceed; }
  void CloseOnExceed(bool value) { this._closeOnExceed = value; }
  bool PreventNewOrders() { return this._preventNewOrders; }
  void PreventNewOrders(bool value) { this._preventNewOrders = value; }

  double GetCurrentBias() {
    OrderCollection* orders = OrderCollection::GetOpenOrders();
    if (this.IsMagicNumberFilterPresent())
      orders.FilterByMagicNumber(this.MagicNumberFilter());
    if (this.IsSymbolNameFilterPresent())
      orders.FilterBySymbolName(this.SymbolNameFilter());

    double bias = orders.GetDirectionalBias();
    delete orders;
    return bias;
  }

  bool IsLongBiased() {
    return GetCurrentBias() > this._maxDirectionalBias;
  }

  bool IsShortBiased() {
    return GetCurrentBias() < -this._maxDirectionalBias;
  }

  virtual void Manage() {
    if (!this._closeOnExceed)
      return;

    OrderCollection* orders = OrderCollection::GetOpenOrders();
    if (this.IsMagicNumberFilterPresent())
      orders.FilterByMagicNumber(this.MagicNumberFilter());
    if (this.IsSymbolNameFilterPresent())
      orders.FilterBySymbolName(this.SymbolNameFilter());

    double bias = orders.GetDirectionalBias();

    if (bias > this._maxDirectionalBias) {
      OrderCollection* longOrders = orders.Copy();
      longOrders.FilterByDirection(true);
      Order* worst = longOrders.GetWorstPerformingOrder();
      if (worst != NULL)
        worst.Close();
      delete longOrders;
    } else if (bias < -this._maxDirectionalBias) {
      OrderCollection* shortOrders = orders.Copy();
      shortOrders.FilterByDirection(false);
      Order* worst = shortOrders.GetWorstPerformingOrder();
      if (worst != NULL)
        worst.Close();
      delete shortOrders;
    }

    delete orders;
  }
};
