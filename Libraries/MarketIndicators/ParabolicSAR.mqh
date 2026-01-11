#include "AConfigurableIndicator.mqh"

class MarketIndicators__ParabolicSAR : public MarketIndicators__AConfigurableIndicator {
private:
  double _sarStep;
  double _sarMax;

public:
  MarketIndicators__ParabolicSAR(
    string symbolName,
    int timeframe = PERIOD_H1,
    double sarStep = 0.02,
    double sarMax = 0.2
  ) : MarketIndicators__AConfigurableIndicator(symbolName, timeframe) {
    this._sarStep = sarStep;
    this._sarMax = sarMax;
  }

  double SARStep() { return this._sarStep; }
  void SARStep(double value) { this._sarStep = value; }
  double SARMax() { return this._sarMax; }
  void SARMax(double value) { this._sarMax = value; }

  bool _IsParabolicSARLongTrend(int shift) {
    return iSAR(this.SymbolName(), this.Timeframe(), this._sarStep, this._sarMax, shift) < iClose(this.SymbolName(), this.Timeframe(), shift);
  }

  bool _IsParabolicSARShortTrend(int shift) {
    return iSAR(this.SymbolName(), this.Timeframe(), this._sarStep, this._sarMax, shift) > iClose(this.SymbolName(), this.Timeframe(), shift);
  }

  bool _IsLongTrend(int shift = 0) {
    return this._IsParabolicSARLongTrend(shift);
  }

  bool _IsShortTrend(int shift = 0) {
    return this._IsParabolicSARShortTrend(shift);
  }

  virtual bool IsLongEntryPoint() {
    return this._IsLongTrend(0) && !this._IsLongTrend(1);
  }

  virtual bool IsShortEntryPoint() {
    return this._IsShortTrend(0) && !this._IsShortTrend(1);
  }

  virtual bool IsLongTrend() {
    return this._IsLongTrend();
  }

  virtual bool IsShortTrend() {
    return this._IsShortTrend();
  }
};
