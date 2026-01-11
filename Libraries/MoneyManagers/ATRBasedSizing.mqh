#include "../IMoneyManager.mqh"

class MoneyManagers__ATRBasedSizing : public IMoneyManager {
private:
  double _basePercent;
  int _atrPeriod;
  double _baseATR;
  int _timeframe;
  double _minScaleFactor;
  double _maxScaleFactor;

public:
  MoneyManagers__ATRBasedSizing(double basePercent, int atrPeriod = 14, double baseATR = 0.001, int timeframe = PERIOD_H1, double minScaleFactor = 0.25, double maxScaleFactor = 2.0) {
    this._basePercent = basePercent;
    this._atrPeriod = atrPeriod;
    this._baseATR = baseATR;
    this._timeframe = timeframe;
    this._minScaleFactor = minScaleFactor;
    this._maxScaleFactor = maxScaleFactor;
  }

  double BasePercent() { return this._basePercent; }
  void BasePercent(double value) { this._basePercent = value; }
  int ATRPeriod() { return this._atrPeriod; }
  void ATRPeriod(int value) { this._atrPeriod = value; }
  double BaseATR() { return this._baseATR; }
  void BaseATR(double value) { this._baseATR = value; }
  int Timeframe() { return this._timeframe; }
  void Timeframe(int value) { this._timeframe = value; }
  double MinScaleFactor() { return this._minScaleFactor; }
  void MinScaleFactor(double value) { this._minScaleFactor = value; }
  double MaxScaleFactor() { return this._maxScaleFactor; }
  void MaxScaleFactor(double value) { this._maxScaleFactor = value; }

  virtual double CalculateLots(Order* order) {
    double currentATR = iATR(order.SymbolName(), this._timeframe, this._atrPeriod, 0);
    if (currentATR <= 0)
      return 0;

    double scaleFactor = this._baseATR / currentATR;
    scaleFactor = MathMin(this._maxScaleFactor, MathMax(this._minScaleFactor, scaleFactor));

    double adjustedPercent = this._basePercent * scaleFactor;
    return (AccountEquity() / 1000.0) * adjustedPercent * 0.01;
  }
};
