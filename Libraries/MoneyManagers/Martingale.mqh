#include "../IMoneyManager.mqh"
#include "../OrderCollection.mqh"

class MoneyManagers__Martingale : public IMoneyManager {
private:
  double _baseLots;
  double _multiplier;
  int _maxMultiplications;
  int _consecutiveLosses;
  double _maxLots;

  void _UpdateConsecutiveLosses() {
    OrderCollection* history = OrderCollection::GetHistoricOrders();
    int count = history.Count();

    this._consecutiveLosses = 0;

    for (int i = count - 1; i >= 0; --i) {
      Order* order = history.Item(i);
      if (order.Type() > OP_SELL)
        continue;

      if (order.Profit() < 0)
        ++this._consecutiveLosses;
      else
        break;
    }

    delete history;
  }

public:
  MoneyManagers__Martingale(double baseLots = 0.01, double multiplier = 2.0, int maxMultiplications = 5, double maxLots = 10.0) {
    this._baseLots = baseLots;
    this._multiplier = multiplier;
    this._maxMultiplications = maxMultiplications;
    this._maxLots = maxLots;
    this._consecutiveLosses = 0;
  }

  double BaseLots() { return this._baseLots; }
  void BaseLots(double value) { this._baseLots = value; }
  double Multiplier() { return this._multiplier; }
  void Multiplier(double value) { this._multiplier = value; }
  int MaxMultiplications() { return this._maxMultiplications; }
  void MaxMultiplications(int value) { this._maxMultiplications = value; }
  double MaxLots() { return this._maxLots; }
  void MaxLots(double value) { this._maxLots = value; }
  int ConsecutiveLosses() { return this._consecutiveLosses; }

  virtual double CalculateLots(Order* order) {
    _UpdateConsecutiveLosses();

    int multiplications = MathMin(this._consecutiveLosses, this._maxMultiplications);
    double lots = this._baseLots * MathPow(this._multiplier, multiplications);

    return MathMin(lots, this._maxLots);
  }
};
