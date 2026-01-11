#include "../Common.mqh"
#include "../Object.mqh"

class RiskManagement__ValueAtRisk : public Object {
private:
  string _symbolName;
  int _timeframe;
  int _lookbackPeriod;
  double _confidence95;
  double _confidence99;

  double _returns[];
  int _returnCount;

  void _CalculateReturns() {
    ArrayResize(this._returns, this._lookbackPeriod);
    this._returnCount = 0;

    for (int i = 0; i < this._lookbackPeriod - 1 && i < Bars - 1; ++i) {
      double closeNow = iClose(this._symbolName, this._timeframe, i);
      double closePrev = iClose(this._symbolName, this._timeframe, i + 1);

      if (closePrev > 0) {
        this._returns[this._returnCount] = (closeNow - closePrev) / closePrev;
        ++this._returnCount;
      }
    }
  }

  double _GetMean() {
    if (this._returnCount == 0)
      return 0;

    double sum = 0;
    for (int i = 0; i < this._returnCount; ++i)
      sum += this._returns[i];

    return sum / this._returnCount;
  }

  double _GetStdDev() {
    if (this._returnCount < 2)
      return 0;

    double mean = _GetMean();
    double sumSqDev = 0;

    for (int i = 0; i < this._returnCount; ++i) {
      double dev = this._returns[i] - mean;
      sumSqDev += dev * dev;
    }

    return MathSqrt(sumSqDev / (this._returnCount - 1));
  }

  void _SortReturns() {
    for (int i = 0; i < this._returnCount - 1; ++i) {
      for (int j = i + 1; j < this._returnCount; ++j) {
        if (this._returns[i] > this._returns[j]) {
          double temp = this._returns[i];
          this._returns[i] = this._returns[j];
          this._returns[j] = temp;
        }
      }
    }
  }

  double _GetPercentile(double percentile) {
    if (this._returnCount == 0)
      return 0;

    _SortReturns();

    double index = percentile * (this._returnCount - 1);
    int lowerIndex = (int)MathFloor(index);
    int upperIndex = (int)MathCeil(index);

    if (lowerIndex == upperIndex || upperIndex >= this._returnCount)
      return this._returns[lowerIndex];

    double fraction = index - lowerIndex;
    return this._returns[lowerIndex] + fraction * (this._returns[upperIndex] - this._returns[lowerIndex]);
  }

public:
  RiskManagement__ValueAtRisk(
    string symbolName,
    int timeframe = PERIOD_D1,
    int lookbackPeriod = 252
  ) {
    this._symbolName = symbolName;
    this._timeframe = timeframe;
    this._lookbackPeriod = lookbackPeriod;
    this._confidence95 = 1.645;
    this._confidence99 = 2.326;
    this._returnCount = 0;
  }

  string SymbolName() { return this._symbolName; }
  int Timeframe() { return this._timeframe; }
  int LookbackPeriod() { return this._lookbackPeriod; }
  void LookbackPeriod(int value) { this._lookbackPeriod = value; }

  void Calculate() {
    _CalculateReturns();
  }

  double GetParametricVaR95(double portfolioValue) {
    _CalculateReturns();
    double stdDev = _GetStdDev();
    return portfolioValue * stdDev * this._confidence95;
  }

  double GetParametricVaR99(double portfolioValue) {
    _CalculateReturns();
    double stdDev = _GetStdDev();
    return portfolioValue * stdDev * this._confidence99;
  }

  double GetHistoricalVaR95(double portfolioValue) {
    _CalculateReturns();
    double percentile = _GetPercentile(0.05);
    return portfolioValue * MathAbs(percentile);
  }

  double GetHistoricalVaR99(double portfolioValue) {
    _CalculateReturns();
    double percentile = _GetPercentile(0.01);
    return portfolioValue * MathAbs(percentile);
  }

  double GetExpectedShortfall95(double portfolioValue) {
    _CalculateReturns();
    _SortReturns();

    int cutoffIndex = (int)(0.05 * this._returnCount);
    if (cutoffIndex == 0)
      cutoffIndex = 1;

    double sum = 0;
    for (int i = 0; i < cutoffIndex; ++i)
      sum += this._returns[i];

    double avgTailLoss = sum / cutoffIndex;
    return portfolioValue * MathAbs(avgTailLoss);
  }

  double GetExpectedShortfall99(double portfolioValue) {
    _CalculateReturns();
    _SortReturns();

    int cutoffIndex = (int)(0.01 * this._returnCount);
    if (cutoffIndex == 0)
      cutoffIndex = 1;

    double sum = 0;
    for (int i = 0; i < cutoffIndex; ++i)
      sum += this._returns[i];

    double avgTailLoss = sum / cutoffIndex;
    return portfolioValue * MathAbs(avgTailLoss);
  }

  double GetDailyVolatility() {
    _CalculateReturns();
    return _GetStdDev();
  }

  double GetAnnualizedVolatility() {
    double dailyVol = GetDailyVolatility();
    return dailyVol * MathSqrt(252);
  }

  double GetMaxHistoricalDrawdown() {
    double peak = 0;
    double maxDD = 0;
    double cumReturn = 1.0;

    _CalculateReturns();

    for (int i = this._returnCount - 1; i >= 0; --i) {
      cumReturn *= (1 + this._returns[i]);
      if (cumReturn > peak)
        peak = cumReturn;

      double dd = (peak - cumReturn) / peak;
      if (dd > maxDD)
        maxDD = dd;
    }

    return maxDD;
  }

  double GetWorstDailyReturn() {
    _CalculateReturns();
    if (this._returnCount == 0)
      return 0;

    double worst = this._returns[0];
    for (int i = 1; i < this._returnCount; ++i)
      if (this._returns[i] < worst)
        worst = this._returns[i];

    return worst;
  }

  double GetBestDailyReturn() {
    _CalculateReturns();
    if (this._returnCount == 0)
      return 0;

    double best = this._returns[0];
    for (int i = 1; i < this._returnCount; ++i)
      if (this._returns[i] > best)
        best = this._returns[i];

    return best;
  }

  string GetRiskReport(double portfolioValue) {
    string report = "=== Value at Risk Report ===\n";
    report += "Symbol: " + this._symbolName + "\n";
    report += "Portfolio Value: " + DoubleToString(portfolioValue, 2) + "\n";
    report += "Lookback: " + IntegerToString(this._lookbackPeriod) + " periods\n\n";

    report += "--- Parametric VaR ---\n";
    report += "95% VaR: " + DoubleToString(GetParametricVaR95(portfolioValue), 2) + "\n";
    report += "99% VaR: " + DoubleToString(GetParametricVaR99(portfolioValue), 2) + "\n\n";

    report += "--- Historical VaR ---\n";
    report += "95% VaR: " + DoubleToString(GetHistoricalVaR95(portfolioValue), 2) + "\n";
    report += "99% VaR: " + DoubleToString(GetHistoricalVaR99(portfolioValue), 2) + "\n\n";

    report += "--- Expected Shortfall (CVaR) ---\n";
    report += "95% ES: " + DoubleToString(GetExpectedShortfall95(portfolioValue), 2) + "\n";
    report += "99% ES: " + DoubleToString(GetExpectedShortfall99(portfolioValue), 2) + "\n\n";

    report += "--- Volatility ---\n";
    report += "Daily: " + DoubleToString(GetDailyVolatility() * 100, 2) + "%\n";
    report += "Annualized: " + DoubleToString(GetAnnualizedVolatility() * 100, 2) + "%\n\n";

    report += "--- Extremes ---\n";
    report += "Worst Day: " + DoubleToString(GetWorstDailyReturn() * 100, 2) + "%\n";
    report += "Best Day: " + DoubleToString(GetBestDailyReturn() * 100, 2) + "%\n";
    report += "Max Drawdown: " + DoubleToString(GetMaxHistoricalDrawdown() * 100, 2) + "%\n";

    return report;
  }
};
