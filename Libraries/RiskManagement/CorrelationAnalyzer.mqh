#include "../Common.mqh"
#include "../Object.mqh"

class RiskManagement__CorrelationAnalyzer : public Object {
private:
  string _symbols[];
  int _symbolCount;
  int _timeframe;
  int _lookbackPeriod;
  double _correlationMatrix[];

  double _GetReturn(string symbol, int shift) {
    double closeNow = iClose(symbol, this._timeframe, shift);
    double closePrev = iClose(symbol, this._timeframe, shift + 1);
    if (closePrev == 0)
      return 0;
    return (closeNow - closePrev) / closePrev;
  }

  double _CalculateCorrelation(string symbol1, string symbol2) {
    double returns1[];
    double returns2[];
    ArrayResize(returns1, this._lookbackPeriod);
    ArrayResize(returns2, this._lookbackPeriod);

    double sum1 = 0, sum2 = 0;
    int count = 0;

    for (int i = 0; i < this._lookbackPeriod; ++i) {
      returns1[i] = _GetReturn(symbol1, i);
      returns2[i] = _GetReturn(symbol2, i);
      sum1 += returns1[i];
      sum2 += returns2[i];
      ++count;
    }

    if (count < 2)
      return 0;

    double mean1 = sum1 / count;
    double mean2 = sum2 / count;

    double covariance = 0;
    double var1 = 0, var2 = 0;

    for (int j = 0; j < count; ++j) {
      double dev1 = returns1[j] - mean1;
      double dev2 = returns2[j] - mean2;
      covariance += dev1 * dev2;
      var1 += dev1 * dev1;
      var2 += dev2 * dev2;
    }

    double stdDev1 = MathSqrt(var1 / count);
    double stdDev2 = MathSqrt(var2 / count);

    if (stdDev1 == 0 || stdDev2 == 0)
      return 0;

    return (covariance / count) / (stdDev1 * stdDev2);
  }

public:
  RiskManagement__CorrelationAnalyzer(
    int timeframe = PERIOD_D1,
    int lookbackPeriod = 30
  ) {
    this._timeframe = timeframe;
    this._lookbackPeriod = lookbackPeriod;
    this._symbolCount = 0;
  }

  void SetTimeframe(int timeframe) { this._timeframe = timeframe; }
  void SetLookbackPeriod(int period) { this._lookbackPeriod = period; }
  int SymbolCount() { return this._symbolCount; }

  void AddSymbol(string symbol) {
    ArrayResize(this._symbols, this._symbolCount + 1);
    this._symbols[this._symbolCount] = symbol;
    ++this._symbolCount;
  }

  void SetSymbols(string &symbols[]) {
    this._symbolCount = ArraySize(symbols);
    ArrayResize(this._symbols, this._symbolCount);
    for (int i = 0; i < this._symbolCount; ++i)
      this._symbols[i] = symbols[i];
  }

  void AddMajorPairs() {
    AddSymbol("EURUSD");
    AddSymbol("GBPUSD");
    AddSymbol("USDJPY");
    AddSymbol("USDCHF");
    AddSymbol("AUDUSD");
    AddSymbol("USDCAD");
    AddSymbol("NZDUSD");
  }

  void ClearSymbols() {
    this._symbolCount = 0;
    ArrayResize(this._symbols, 0);
  }

  void CalculateMatrix() {
    int matrixSize = this._symbolCount * this._symbolCount;
    ArrayResize(this._correlationMatrix, matrixSize);
    ArrayInitialize(this._correlationMatrix, 0);

    for (int i = 0; i < this._symbolCount; ++i) {
      for (int j = 0; j < this._symbolCount; ++j) {
        int index = i * this._symbolCount + j;
        if (i == j) {
          this._correlationMatrix[index] = 1.0;
        } else if (j > i) {
          this._correlationMatrix[index] = _CalculateCorrelation(this._symbols[i], this._symbols[j]);
          this._correlationMatrix[j * this._symbolCount + i] = this._correlationMatrix[index];
        }
      }
    }
  }

  double GetCorrelation(int index1, int index2) {
    if (index1 < 0 || index1 >= this._symbolCount || index2 < 0 || index2 >= this._symbolCount)
      return 0;
    return this._correlationMatrix[index1 * this._symbolCount + index2];
  }

  double GetCorrelation(string symbol1, string symbol2) {
    int index1 = -1, index2 = -1;
    for (int i = 0; i < this._symbolCount; ++i) {
      if (this._symbols[i] == symbol1)
        index1 = i;
      if (this._symbols[i] == symbol2)
        index2 = i;
    }

    if (index1 < 0 || index2 < 0)
      return _CalculateCorrelation(symbol1, symbol2);

    return GetCorrelation(index1, index2);
  }

  bool IsHighlyCorrelated(string symbol1, string symbol2, double threshold = 0.7) {
    double corr = GetCorrelation(symbol1, symbol2);
    return MathAbs(corr) >= threshold;
  }

  bool IsNegativelyCorrelated(string symbol1, string symbol2, double threshold = -0.5) {
    double corr = GetCorrelation(symbol1, symbol2);
    return corr <= threshold;
  }

  string GetMostCorrelatedPair(string symbol) {
    double maxCorr = 0;
    string maxSymbol = "";

    for (int i = 0; i < this._symbolCount; ++i) {
      if (this._symbols[i] == symbol)
        continue;

      double corr = MathAbs(GetCorrelation(symbol, this._symbols[i]));
      if (corr > maxCorr) {
        maxCorr = corr;
        maxSymbol = this._symbols[i];
      }
    }

    return maxSymbol;
  }

  string GetLeastCorrelatedPair(string symbol) {
    double minCorr = 2.0;
    string minSymbol = "";

    for (int i = 0; i < this._symbolCount; ++i) {
      if (this._symbols[i] == symbol)
        continue;

      double corr = MathAbs(GetCorrelation(symbol, this._symbols[i]));
      if (corr < minCorr) {
        minCorr = corr;
        minSymbol = this._symbols[i];
      }
    }

    return minSymbol;
  }

  double GetAverageCorrelation(string symbol) {
    double sum = 0;
    int count = 0;

    for (int i = 0; i < this._symbolCount; ++i) {
      if (this._symbols[i] == symbol)
        continue;

      sum += MathAbs(GetCorrelation(symbol, this._symbols[i]));
      ++count;
    }

    return count > 0 ? sum / count : 0;
  }

  double GetPortfolioCorrelationRisk() {
    if (this._symbolCount < 2)
      return 0;

    double sum = 0;
    int count = 0;

    for (int i = 0; i < this._symbolCount; ++i) {
      for (int j = i + 1; j < this._symbolCount; ++j) {
        sum += MathAbs(GetCorrelation(i, j));
        ++count;
      }
    }

    return count > 0 ? sum / count : 0;
  }

  string GetCorrelationMatrixReport() {
    string report = "=== Correlation Matrix ===\n";
    report += "Lookback: " + IntegerToString(this._lookbackPeriod) + " periods\n\n";

    report += "       ";
    for (int h = 0; h < this._symbolCount; ++h)
      report += StringSubstr(this._symbols[h], 0, 6) + " ";
    report += "\n";

    for (int i = 0; i < this._symbolCount; ++i) {
      report += StringSubstr(this._symbols[i], 0, 6) + " ";
      for (int j = 0; j < this._symbolCount; ++j) {
        double corr = GetCorrelation(i, j);
        if (corr >= 0)
          report += " ";
        report += DoubleToString(corr, 2) + " ";
      }
      report += "\n";
    }

    report += "\nPortfolio Correlation Risk: " + DoubleToString(GetPortfolioCorrelationRisk(), 2);

    return report;
  }

  string GetHighCorrelationWarnings(double threshold = 0.7) {
    string warnings = "";

    for (int i = 0; i < this._symbolCount; ++i) {
      for (int j = i + 1; j < this._symbolCount; ++j) {
        double corr = GetCorrelation(i, j);
        if (MathAbs(corr) >= threshold) {
          warnings += this._symbols[i] + " / " + this._symbols[j] +
                      ": " + DoubleToString(corr, 2) + "\n";
        }
      }
    }

    return warnings == "" ? "No high correlations found" : warnings;
  }
};
