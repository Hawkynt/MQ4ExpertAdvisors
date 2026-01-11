#include "../IMoneyManager.mqh"

class MoneyManagers__DrawdownLimiter : public IMoneyManager {
private:
  IMoneyManager* _baseManager;
  double _maxDrawdownPercent;
  double _reductionFactor;
  double _peakEquity;
  bool _ownsBaseManager;

public:
  MoneyManagers__DrawdownLimiter(IMoneyManager* baseManager, double maxDrawdownPercent = 20.0, double reductionFactor = 0.5, bool ownsBaseManager = false) {
    this._baseManager = baseManager;
    this._maxDrawdownPercent = maxDrawdownPercent;
    this._reductionFactor = reductionFactor;
    this._peakEquity = AccountEquity();
    this._ownsBaseManager = ownsBaseManager;
  }

  ~MoneyManagers__DrawdownLimiter() {
    if (this._ownsBaseManager && this._baseManager != NULL)
      delete this._baseManager;
    this._baseManager = NULL;
  }

  double MaxDrawdownPercent() { return this._maxDrawdownPercent; }
  void MaxDrawdownPercent(double value) { this._maxDrawdownPercent = value; }
  double ReductionFactor() { return this._reductionFactor; }
  void ReductionFactor(double value) { this._reductionFactor = value; }
  double PeakEquity() { return this._peakEquity; }
  void ResetPeakEquity() { this._peakEquity = AccountEquity(); }

  virtual double CalculateLots(Order* order) {
    if (this._baseManager == NULL)
      return 0;

    double currentEquity = AccountEquity();

    if (currentEquity > this._peakEquity)
      this._peakEquity = currentEquity;

    double drawdownPercent = ((this._peakEquity - currentEquity) / this._peakEquity) * 100.0;

    if (drawdownPercent >= this._maxDrawdownPercent)
      return 0;

    double baseLots = this._baseManager.CalculateLots(order);

    double scaleFactor = 1.0 - (drawdownPercent / this._maxDrawdownPercent) * (1.0 - this._reductionFactor);

    return baseLots * scaleFactor;
  }
};
