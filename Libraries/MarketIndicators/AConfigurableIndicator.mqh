#include "..\IMarketIndicator.mqh"

class MarketIndicators__AConfigurableIndicator : public IMarketIndicator {
protected:
  int _timeframe;

  MarketIndicators__AConfigurableIndicator(string symbolName, int timeframe = PERIOD_H1) : IMarketIndicator(symbolName) {
    this._timeframe = timeframe;
  }

public:
  int Timeframe() { return this._timeframe; }
  void Timeframe(int value) { this._timeframe = value; }
};
