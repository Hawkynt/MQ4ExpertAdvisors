#include "../IMoneyManager.mqh"

class MoneyManagers__KellyCriterion : public IMoneyManager {
private:
  double _winRate;
  double _winLossRatio;
  double _fractionOfKelly;

public:
  MoneyManagers__KellyCriterion(double winRate, double winLossRatio, double fractionOfKelly = 0.5) {
    this._winRate = MathMin(1.0, MathMax(0.0, winRate));
    this._winLossRatio = MathMax(0.01, winLossRatio);
    this._fractionOfKelly = MathMin(1.0, MathMax(0.1, fractionOfKelly));
  }

  double WinRate() { return this._winRate; }
  void WinRate(double value) { this._winRate = MathMin(1.0, MathMax(0.0, value)); }
  double WinLossRatio() { return this._winLossRatio; }
  void WinLossRatio(double value) { this._winLossRatio = MathMax(0.01, value); }
  double FractionOfKelly() { return this._fractionOfKelly; }
  void FractionOfKelly(double value) { this._fractionOfKelly = MathMin(1.0, MathMax(0.1, value)); }

  virtual double CalculateLots(Order* order) {
    double stopLossMoney = order.StopLossMoney();
    if (stopLossMoney <= 0)
      return 0;

    double kellyPercent = this._winRate - ((1.0 - this._winRate) / this._winLossRatio);
    if (kellyPercent <= 0)
      return 0;

    kellyPercent *= this._fractionOfKelly;
    double riskAmount = AccountEquity() * kellyPercent;

    return riskAmount / stopLossMoney;
  }
};
