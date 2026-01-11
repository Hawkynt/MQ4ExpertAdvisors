#include "../IMoneyManager.mqh"
#include "../OrderCollection.mqh"

class MoneyManagers__AntiMartingale : public IMoneyManager {
private:
  double _baseLots;
  double _winMultiplier;
  double _lossMultiplier;
  int _maxWinMultiplications;
  int _consecutiveWins;
  int _consecutiveLosses;
  double _minLots;
  double _maxLots;

  void _UpdateConsecutiveResults() {
    OrderCollection* history = OrderCollection::GetHistoricOrders();
    int count = history.Count();

    this._consecutiveWins = 0;
    this._consecutiveLosses = 0;

    bool countingWins = true;
    bool countingLosses = true;

    for (int i = count - 1; i >= 0; --i) {
      Order* order = history.Item(i);
      if (order.Type() > OP_SELL)
        continue;

      if (order.Profit() > 0) {
        if (countingWins)
          ++this._consecutiveWins;
        countingLosses = false;
      } else if (order.Profit() < 0) {
        if (countingLosses)
          ++this._consecutiveLosses;
        countingWins = false;
      }

      if (!countingWins && !countingLosses)
        break;
    }

    delete history;
  }

public:
  MoneyManagers__AntiMartingale(double baseLots = 0.01, double winMultiplier = 1.5, double lossMultiplier = 0.5, int maxWinMultiplications = 4, double minLots = 0.01, double maxLots = 10.0) {
    this._baseLots = baseLots;
    this._winMultiplier = winMultiplier;
    this._lossMultiplier = lossMultiplier;
    this._maxWinMultiplications = maxWinMultiplications;
    this._minLots = minLots;
    this._maxLots = maxLots;
    this._consecutiveWins = 0;
    this._consecutiveLosses = 0;
  }

  double BaseLots() { return this._baseLots; }
  void BaseLots(double value) { this._baseLots = value; }
  double WinMultiplier() { return this._winMultiplier; }
  void WinMultiplier(double value) { this._winMultiplier = value; }
  double LossMultiplier() { return this._lossMultiplier; }
  void LossMultiplier(double value) { this._lossMultiplier = value; }
  int MaxWinMultiplications() { return this._maxWinMultiplications; }
  void MaxWinMultiplications(int value) { this._maxWinMultiplications = value; }
  double MinLots() { return this._minLots; }
  void MinLots(double value) { this._minLots = value; }
  double MaxLots() { return this._maxLots; }
  void MaxLots(double value) { this._maxLots = value; }
  int ConsecutiveWins() { return this._consecutiveWins; }
  int ConsecutiveLosses() { return this._consecutiveLosses; }

  virtual double CalculateLots(Order* order) {
    _UpdateConsecutiveResults();

    double lots = this._baseLots;

    if (this._consecutiveWins > 0) {
      int multiplications = MathMin(this._consecutiveWins, this._maxWinMultiplications);
      lots = this._baseLots * MathPow(this._winMultiplier, multiplications);
    } else if (this._consecutiveLosses > 0) {
      lots = this._baseLots * MathPow(this._lossMultiplier, this._consecutiveLosses);
    }

    lots = MathMax(lots, this._minLots);
    lots = MathMin(lots, this._maxLots);

    return lots;
  }
};
