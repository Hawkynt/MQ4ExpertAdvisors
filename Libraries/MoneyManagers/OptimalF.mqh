#include "../IMoneyManager.mqh"
#include "../OrderCollection.mqh"

class MoneyManagers__OptimalF : public IMoneyManager {
private:
  double _fraction;
  double _minLots;
  double _maxLots;
  int _lookbackTrades;
  double _largestLoss;
  bool _autoCalculateFraction;

  void _UpdateLargestLoss() {
    OrderCollection* history = OrderCollection::GetHistoricOrders();
    int count = history.Count();

    this._largestLoss = 0;
    int tradesAnalyzed = 0;

    for (int i = count - 1; i >= 0 && tradesAnalyzed < this._lookbackTrades; --i) {
      Order* order = history.Item(i);
      if (order.Type() > OP_SELL)
        continue;

      double loss = order.Profit();
      if (loss < 0 && MathAbs(loss) > this._largestLoss)
        this._largestLoss = MathAbs(loss);

      ++tradesAnalyzed;
    }

    delete history;
  }

  double _CalculateOptimalFraction() {
    OrderCollection* history = OrderCollection::GetHistoricOrders();
    int count = history.Count();

    int wins = 0;
    int losses = 0;
    double totalWin = 0;
    double totalLoss = 0;
    int tradesAnalyzed = 0;

    for (int i = count - 1; i >= 0 && tradesAnalyzed < this._lookbackTrades; --i) {
      Order* order = history.Item(i);
      if (order.Type() > OP_SELL)
        continue;

      double profit = order.Profit();
      if (profit > 0) {
        ++wins;
        totalWin += profit;
      } else if (profit < 0) {
        ++losses;
        totalLoss += MathAbs(profit);
      }

      ++tradesAnalyzed;
    }

    delete history;

    if (wins == 0 || losses == 0 || totalLoss == 0)
      return 0.1;

    double winRate = (double)wins / (wins + losses);
    double avgWin = totalWin / wins;
    double avgLoss = totalLoss / losses;
    double winLossRatio = avgWin / avgLoss;

    double optimalF = winRate - ((1.0 - winRate) / winLossRatio);
    return MathMax(0.01, MathMin(0.5, optimalF));
  }

public:
  MoneyManagers__OptimalF(double fraction = 0.1, int lookbackTrades = 100, double minLots = 0.01, double maxLots = 10.0, bool autoCalculateFraction = true) {
    this._fraction = fraction;
    this._lookbackTrades = lookbackTrades;
    this._minLots = minLots;
    this._maxLots = maxLots;
    this._autoCalculateFraction = autoCalculateFraction;
    this._largestLoss = 0;
  }

  double Fraction() { return this._fraction; }
  void Fraction(double value) { this._fraction = value; }
  int LookbackTrades() { return this._lookbackTrades; }
  void LookbackTrades(int value) { this._lookbackTrades = value; }
  double MinLots() { return this._minLots; }
  void MinLots(double value) { this._minLots = value; }
  double MaxLots() { return this._maxLots; }
  void MaxLots(double value) { this._maxLots = value; }
  bool AutoCalculateFraction() { return this._autoCalculateFraction; }
  void AutoCalculateFraction(bool value) { this._autoCalculateFraction = value; }
  double LargestLoss() { return this._largestLoss; }

  virtual double CalculateLots(Order* order) {
    _UpdateLargestLoss();

    double fraction = this._fraction;
    if (this._autoCalculateFraction)
      fraction = _CalculateOptimalFraction();

    if (this._largestLoss <= 0)
      return this._minLots;

    double equity = AccountEquity();
    double riskAmount = equity * fraction;
    double lots = riskAmount / this._largestLoss;

    lots = MathMax(lots, this._minLots);
    lots = MathMin(lots, this._maxLots);

    return lots;
  }
};
