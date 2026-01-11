#include "AConfigurableIndicator.mqh"

class MarketIndicators__MAParabolic : public MarketIndicators__AConfigurableIndicator {
private:
  int _maType;
  int _maPrice;
  int _maFast;
  int _maSlow;
  double _sarStep;
  double _sarMax;

public:
  MarketIndicators__MAParabolic(
    string symbolName,
    int timeframe = PERIOD_H1,
    int maFast = 9,
    int maSlow = 27,
    int maType = MODE_SMA,
    int maPrice = PRICE_CLOSE,
    double sarStep = 0.02,
    double sarMax = 0.2
  ) : MarketIndicators__AConfigurableIndicator(symbolName, timeframe) {
    this._maType = maType;
    this._maPrice = maPrice;
    this._maFast = maFast;
    this._maSlow = maSlow;
    this._sarStep = sarStep;
    this._sarMax = sarMax;
  }

  int MAType() { return this._maType; }
  void MAType(int value) { this._maType = value; }
  int MAPrice() { return this._maPrice; }
  void MAPrice(int value) { this._maPrice = value; }
  int MAFast() { return this._maFast; }
  void MAFast(int value) { this._maFast = value; }
  int MASlow() { return this._maSlow; }
  void MASlow(int value) { this._maSlow = value; }
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

  bool _IsMovingAverageLongTrend(int shift) {
    return iMA(this.SymbolName(), this.Timeframe(), this._maFast, 0, this._maType, this._maPrice, shift) > iMA(this.SymbolName(), this.Timeframe(), this._maSlow, 0, this._maType, this._maPrice, shift);
  }

  bool _IsMovingAverageShortTrend(int shift) {
    return iMA(this.SymbolName(), this.Timeframe(), this._maFast, 0, this._maType, this._maPrice, shift) < iMA(this.SymbolName(), this.Timeframe(), this._maSlow, 0, this._maType, this._maPrice, shift);
  }

  bool _IsLongTrend(int shift = 0) {
    return this._IsMovingAverageLongTrend(shift) && this._IsParabolicSARLongTrend(shift);
  }

  bool _IsShortTrend(int shift = 0) {
    return this._IsMovingAverageShortTrend(shift) && this._IsParabolicSARShortTrend(shift);
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
