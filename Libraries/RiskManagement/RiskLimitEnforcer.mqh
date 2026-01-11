#include "../IOrderManager.mqh"

class RiskManagement__RiskLimitEnforcer : public IOrderManager {
private:
  double _maxDailyLossPercent;
  double _maxWeeklyLossPercent;
  double _maxTotalDrawdownPercent;
  double _maxOpenRiskPercent;
  int _maxConcurrentOrders;
  double _maxDailyLots;

  datetime _dailyResetTime;
  datetime _weeklyResetTime;
  double _dailyStartBalance;
  double _weeklyStartBalance;
  double _peakBalance;

  bool _tradingHalted;
  string _haltReason;

  void _ResetDailyIfNeeded() {
    datetime currentDay = TimeCurrent() - (TimeCurrent() % 86400);
    if (currentDay > this._dailyResetTime) {
      this._dailyResetTime = currentDay;
      this._dailyStartBalance = AccountBalance();
      if (!this._tradingHalted || StringFind(this._haltReason, "Daily") >= 0) {
        this._tradingHalted = false;
        this._haltReason = "";
      }
    }
  }

  void _ResetWeeklyIfNeeded() {
    int dayOfWeek = TimeDayOfWeek(TimeCurrent());
    datetime weekStart = TimeCurrent() - (dayOfWeek * 86400) - (TimeCurrent() % 86400);

    if (weekStart > this._weeklyResetTime) {
      this._weeklyResetTime = weekStart;
      this._weeklyStartBalance = AccountBalance();
      if (!this._tradingHalted || StringFind(this._haltReason, "Weekly") >= 0) {
        this._tradingHalted = false;
        this._haltReason = "";
      }
    }
  }

  double _GetDailyPL() {
    return AccountBalance() - this._dailyStartBalance;
  }

  double _GetWeeklyPL() {
    return AccountBalance() - this._weeklyStartBalance;
  }

  double _GetTotalDrawdown() {
    if (AccountBalance() > this._peakBalance)
      this._peakBalance = AccountBalance();

    if (this._peakBalance == 0)
      return 0;

    return ((this._peakBalance - AccountEquity()) / this._peakBalance) * 100;
  }

  double _GetOpenRisk() {
    double totalRisk = 0;

    for (int i = OrdersTotal() - 1; i >= 0; --i) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        continue;
      if (this.IsSymbolNameFilterPresent() && OrderSymbol() != this.SymbolNameFilter())
        continue;
      if (this.IsMagicNumberFilterPresent() && OrderMagicNumber() != this.MagicNumberFilter())
        continue;

      double sl = OrderStopLoss();
      if (sl == 0)
        continue;

      double entryPrice = OrderOpenPrice();
      double pipValue = MarketInfo(OrderSymbol(), MODE_TICKVALUE);
      double point = MarketInfo(OrderSymbol(), MODE_POINT);

      if (point == 0)
        continue;

      double pips = MathAbs(entryPrice - sl) / point;
      double orderRisk = pips * pipValue * OrderLots();
      totalRisk += orderRisk;
    }

    return AccountBalance() > 0 ? (totalRisk / AccountBalance()) * 100 : 0;
  }

  int _GetOpenOrderCount() {
    int count = 0;
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        continue;
      if (this.IsSymbolNameFilterPresent() && OrderSymbol() != this.SymbolNameFilter())
        continue;
      if (this.IsMagicNumberFilterPresent() && OrderMagicNumber() != this.MagicNumberFilter())
        continue;
      if (OrderType() <= OP_SELL)
        ++count;
    }
    return count;
  }

  double _GetDailyTradedLots() {
    double totalLots = 0;
    datetime dayStart = TimeCurrent() - (TimeCurrent() % 86400);

    for (int i = OrdersHistoryTotal() - 1; i >= 0; --i) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        continue;
      if (OrderOpenTime() < dayStart)
        break;
      if (this.IsSymbolNameFilterPresent() && OrderSymbol() != this.SymbolNameFilter())
        continue;
      if (this.IsMagicNumberFilterPresent() && OrderMagicNumber() != this.MagicNumberFilter())
        continue;
      if (OrderType() <= OP_SELL)
        totalLots += OrderLots();
    }

    for (int j = OrdersTotal() - 1; j >= 0; --j) {
      if (!OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
        continue;
      if (OrderOpenTime() < dayStart)
        continue;
      if (this.IsSymbolNameFilterPresent() && OrderSymbol() != this.SymbolNameFilter())
        continue;
      if (this.IsMagicNumberFilterPresent() && OrderMagicNumber() != this.MagicNumberFilter())
        continue;
      if (OrderType() <= OP_SELL)
        totalLots += OrderLots();
    }

    return totalLots;
  }

public:
  RiskManagement__RiskLimitEnforcer(
    double maxDailyLossPercent = 3.0,
    double maxWeeklyLossPercent = 10.0,
    double maxTotalDrawdownPercent = 20.0,
    double maxOpenRiskPercent = 5.0,
    int maxConcurrentOrders = 5,
    double maxDailyLots = 10.0
  ) : IOrderManager() {
    this._maxDailyLossPercent = maxDailyLossPercent;
    this._maxWeeklyLossPercent = maxWeeklyLossPercent;
    this._maxTotalDrawdownPercent = maxTotalDrawdownPercent;
    this._maxOpenRiskPercent = maxOpenRiskPercent;
    this._maxConcurrentOrders = maxConcurrentOrders;
    this._maxDailyLots = maxDailyLots;

    this._dailyResetTime = 0;
    this._weeklyResetTime = 0;
    this._dailyStartBalance = AccountBalance();
    this._weeklyStartBalance = AccountBalance();
    this._peakBalance = AccountBalance();
    this._tradingHalted = false;
    this._haltReason = "";
  }

  void SetLimits(double dailyLoss, double weeklyLoss, double totalDrawdown) {
    this._maxDailyLossPercent = dailyLoss;
    this._maxWeeklyLossPercent = weeklyLoss;
    this._maxTotalDrawdownPercent = totalDrawdown;
  }

  bool IsTradingAllowed() {
    _ResetDailyIfNeeded();
    _ResetWeeklyIfNeeded();

    if (this._tradingHalted)
      return false;

    double dailyLoss = -_GetDailyPL();
    double dailyLossPercent = this._dailyStartBalance > 0 ? (dailyLoss / this._dailyStartBalance) * 100 : 0;
    if (dailyLossPercent >= this._maxDailyLossPercent) {
      this._tradingHalted = true;
      this._haltReason = "Daily loss limit reached: " + DoubleToString(dailyLossPercent, 2) + "%";
      return false;
    }

    double weeklyLoss = -_GetWeeklyPL();
    double weeklyLossPercent = this._weeklyStartBalance > 0 ? (weeklyLoss / this._weeklyStartBalance) * 100 : 0;
    if (weeklyLossPercent >= this._maxWeeklyLossPercent) {
      this._tradingHalted = true;
      this._haltReason = "Weekly loss limit reached: " + DoubleToString(weeklyLossPercent, 2) + "%";
      return false;
    }

    double totalDrawdown = _GetTotalDrawdown();
    if (totalDrawdown >= this._maxTotalDrawdownPercent) {
      this._tradingHalted = true;
      this._haltReason = "Total drawdown limit reached: " + DoubleToString(totalDrawdown, 2) + "%";
      return false;
    }

    return true;
  }

  bool CanOpenNewOrder() {
    if (!IsTradingAllowed())
      return false;

    if (_GetOpenOrderCount() >= this._maxConcurrentOrders)
      return false;

    if (_GetOpenRisk() >= this._maxOpenRiskPercent)
      return false;

    if (_GetDailyTradedLots() >= this._maxDailyLots)
      return false;

    return true;
  }

  bool IsHalted() { return this._tradingHalted; }
  string GetHaltReason() { return this._haltReason; }

  void ResetHalt() {
    this._tradingHalted = false;
    this._haltReason = "";
  }

  void ResetPeakBalance() {
    this._peakBalance = AccountBalance();
  }

  virtual void Manage() {
    _ResetDailyIfNeeded();
    _ResetWeeklyIfNeeded();

    if (!IsTradingAllowed()) {
      Print("Risk Limit Enforcer: Trading halted - " + this._haltReason);
    }
  }

  string GetStatusReport() {
    _ResetDailyIfNeeded();
    _ResetWeeklyIfNeeded();

    string report = "=== Risk Limits Status ===\n";

    double dailyLoss = -_GetDailyPL();
    double dailyLossPercent = this._dailyStartBalance > 0 ? (dailyLoss / this._dailyStartBalance) * 100 : 0;
    report += "Daily P/L: " + DoubleToString(_GetDailyPL(), 2) + " (" + DoubleToString(-dailyLossPercent, 2) + "% / -" + DoubleToString(this._maxDailyLossPercent, 2) + "%)\n";

    double weeklyLoss = -_GetWeeklyPL();
    double weeklyLossPercent = this._weeklyStartBalance > 0 ? (weeklyLoss / this._weeklyStartBalance) * 100 : 0;
    report += "Weekly P/L: " + DoubleToString(_GetWeeklyPL(), 2) + " (" + DoubleToString(-weeklyLossPercent, 2) + "% / -" + DoubleToString(this._maxWeeklyLossPercent, 2) + "%)\n";

    report += "Total Drawdown: " + DoubleToString(_GetTotalDrawdown(), 2) + "% / " + DoubleToString(this._maxTotalDrawdownPercent, 2) + "%\n";
    report += "Open Risk: " + DoubleToString(_GetOpenRisk(), 2) + "% / " + DoubleToString(this._maxOpenRiskPercent, 2) + "%\n";
    report += "Open Orders: " + IntegerToString(_GetOpenOrderCount()) + " / " + IntegerToString(this._maxConcurrentOrders) + "\n";
    report += "Daily Lots: " + DoubleToString(_GetDailyTradedLots(), 2) + " / " + DoubleToString(this._maxDailyLots, 2) + "\n\n";

    report += "Trading Allowed: " + (IsTradingAllowed() ? "YES" : "NO") + "\n";
    report += "Can Open New: " + (CanOpenNewOrder() ? "YES" : "NO") + "\n";

    if (this._tradingHalted)
      report += "HALTED: " + this._haltReason;

    return report;
  }
};
