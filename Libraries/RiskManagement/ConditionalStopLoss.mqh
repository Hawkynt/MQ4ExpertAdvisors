#include "../OrderManagers/AExistingOrdersManager.mqh"

enum ENUM_STOP_CONDITION {
  STOP_CONDITION_TIME_DECAY,
  STOP_CONDITION_PRICE_ACTION,
  STOP_CONDITION_VOLATILITY,
  STOP_CONDITION_INDICATOR,
  STOP_CONDITION_PROFIT_TARGET
};

class RiskManagement__ConditionalStopLoss : public AExistingOrdersManager {
private:
  double _initialStopPips;
  double _timeDecayRate;
  int _timeDecayIntervalMinutes;
  double _minStopPips;
  bool _useTimeDecay;
  bool _usePriceAction;
  bool _useVolatilityAdjust;
  int _atrPeriod;
  double _atrMultiplier;
  int _swingLookback;

  datetime _GetOrderOpenTime(int ticket) {
    if (OrderSelect(ticket, SELECT_BY_TICKET))
      return OrderOpenTime();
    return 0;
  }

  double _GetTimeDecayStop(Order *order) {
    datetime openTime = _GetOrderOpenTime(order.Ticket);
    int minutesOpen = (int)((TimeCurrent() - openTime) / 60);
    int intervals = minutesOpen / this._timeDecayIntervalMinutes;

    double decayAmount = intervals * this._timeDecayRate;
    double newStopPips = this._initialStopPips - decayAmount;

    return MathMax(newStopPips, this._minStopPips);
  }

  double _GetSwingLow(string symbol, int timeframe, int lookback) {
    double lowest = iLow(symbol, timeframe, 0);
    for (int i = 1; i <= lookback; ++i) {
      double low = iLow(symbol, timeframe, i);
      if (low < lowest)
        lowest = low;
    }
    return lowest;
  }

  double _GetSwingHigh(string symbol, int timeframe, int lookback) {
    double highest = iHigh(symbol, timeframe, 0);
    for (int i = 1; i <= lookback; ++i) {
      double high = iHigh(symbol, timeframe, i);
      if (high > highest)
        highest = high;
    }
    return highest;
  }

  double _GetPriceActionStop(Order *order) {
    string symbol = order.SymbolName;
    int timeframe = PERIOD_H1;
    double point = MarketInfo(symbol, MODE_POINT);

    if (order.IsBuyOrder()) {
      double swingLow = _GetSwingLow(symbol, timeframe, this._swingLookback);
      double buffer = iATR(symbol, timeframe, this._atrPeriod, 0) * 0.5;
      return swingLow - buffer;
    } else {
      double swingHigh = _GetSwingHigh(symbol, timeframe, this._swingLookback);
      double buffer = iATR(symbol, timeframe, this._atrPeriod, 0) * 0.5;
      return swingHigh + buffer;
    }
  }

  double _GetVolatilityStop(Order *order) {
    string symbol = order.SymbolName;
    int timeframe = PERIOD_H1;
    double atr = iATR(symbol, timeframe, this._atrPeriod, 0);
    double stopDistance = atr * this._atrMultiplier;

    if (order.IsBuyOrder())
      return MarketInfo(symbol, MODE_BID) - stopDistance;
    else
      return MarketInfo(symbol, MODE_ASK) + stopDistance;
  }

  double _CalculateNewStop(Order *order) {
    double currentStop = order.StopLoss;
    double bestStop = currentStop;
    string symbol = order.SymbolName;
    double point = MarketInfo(symbol, MODE_POINT);

    if (this._useTimeDecay) {
      double timeDecayPips = _GetTimeDecayStop(order);
      double timeDecayStop;

      if (order.IsBuyOrder())
        timeDecayStop = order.OpenPrice - (timeDecayPips * point);
      else
        timeDecayStop = order.OpenPrice + (timeDecayPips * point);

      if (order.IsBuyOrder() && (bestStop == 0 || timeDecayStop > bestStop))
        bestStop = timeDecayStop;
      else if (order.IsSellOrder() && (bestStop == 0 || timeDecayStop < bestStop))
        bestStop = timeDecayStop;
    }

    if (this._usePriceAction) {
      double priceActionStop = _GetPriceActionStop(order);

      if (order.IsBuyOrder() && (bestStop == 0 || priceActionStop > bestStop))
        bestStop = priceActionStop;
      else if (order.IsSellOrder() && (bestStop == 0 || priceActionStop < bestStop))
        bestStop = priceActionStop;
    }

    if (this._useVolatilityAdjust) {
      double volStop = _GetVolatilityStop(order);

      if (order.IsBuyOrder() && (bestStop == 0 || volStop > bestStop))
        bestStop = volStop;
      else if (order.IsSellOrder() && (bestStop == 0 || volStop < bestStop))
        bestStop = volStop;
    }

    if (order.IsBuyOrder() && bestStop > 0) {
      double currentPrice = MarketInfo(symbol, MODE_BID);
      double minStop = currentPrice - (this._minStopPips * point);
      if (bestStop > minStop)
        bestStop = minStop;
    } else if (order.IsSellOrder() && bestStop > 0) {
      double currentPrice = MarketInfo(symbol, MODE_ASK);
      double minStop = currentPrice + (this._minStopPips * point);
      if (bestStop < minStop)
        bestStop = minStop;
    }

    return bestStop;
  }

public:
  RiskManagement__ConditionalStopLoss(
    double initialStopPips = 50,
    double timeDecayRate = 1.0,
    int timeDecayIntervalMinutes = 60,
    double minStopPips = 10,
    int atrPeriod = 14,
    double atrMultiplier = 2.0,
    int swingLookback = 10
  ) : AExistingOrdersManager() {
    this._initialStopPips = initialStopPips;
    this._timeDecayRate = timeDecayRate;
    this._timeDecayIntervalMinutes = timeDecayIntervalMinutes;
    this._minStopPips = minStopPips;
    this._atrPeriod = atrPeriod;
    this._atrMultiplier = atrMultiplier;
    this._swingLookback = swingLookback;

    this._useTimeDecay = true;
    this._usePriceAction = true;
    this._useVolatilityAdjust = false;
  }

  void EnableTimeDecay(bool enable) { this._useTimeDecay = enable; }
  void EnablePriceAction(bool enable) { this._usePriceAction = enable; }
  void EnableVolatilityAdjust(bool enable) { this._useVolatilityAdjust = enable; }

  void SetTimeDecayParams(double rate, int intervalMinutes) {
    this._timeDecayRate = rate;
    this._timeDecayIntervalMinutes = intervalMinutes;
  }

  void SetVolatilityParams(int atrPeriod, double multiplier) {
    this._atrPeriod = atrPeriod;
    this._atrMultiplier = multiplier;
  }

  void SetSwingLookback(int bars) { this._swingLookback = bars; }
  void SetMinStopPips(double pips) { this._minStopPips = pips; }

  virtual void _ManageSingleOrder(Order *order) {
    if (!order.IsMarketOrder())
      return;

    double newStop = _CalculateNewStop(order);
    double currentStop = order.StopLoss;
    string symbol = order.SymbolName;
    double point = MarketInfo(symbol, MODE_POINT);
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);

    if (newStop == 0)
      return;

    newStop = NormalizeDouble(newStop, digits);

    bool shouldModify = false;

    if (order.IsBuyOrder()) {
      if (currentStop == 0 || newStop > currentStop)
        shouldModify = true;
    } else {
      if (currentStop == 0 || newStop < currentStop)
        shouldModify = true;
    }

    if (shouldModify) {
      double stopLevel = MarketInfo(symbol, MODE_STOPLEVEL) * point;
      double currentPrice = order.IsBuyOrder() ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);

      if (order.IsBuyOrder() && currentPrice - newStop < stopLevel)
        return;
      if (order.IsSellOrder() && newStop - currentPrice < stopLevel)
        return;

      bool result = OrderModify(order.Ticket, order.OpenPrice, newStop, order.TakeProfit, 0, clrOrange);
      if (!result)
        Print("ConditionalStopLoss: Failed to modify order #", order.Ticket, " Error: ", GetLastError());
    }
  }

  string GetStopAnalysis(int ticket) {
    if (!OrderSelect(ticket, SELECT_BY_TICKET))
      return "Order not found";

    Order *order = new Order(ticket);
    string analysis = "=== Stop Analysis for #" + IntegerToString(ticket) + " ===\n";

    analysis += "Current Stop: " + DoubleToString(order.StopLoss, (int)MarketInfo(order.SymbolName, MODE_DIGITS)) + "\n";

    if (this._useTimeDecay) {
      double timeDecayPips = _GetTimeDecayStop(order);
      analysis += "Time Decay Stop: " + DoubleToString(timeDecayPips, 1) + " pips\n";
    }

    if (this._usePriceAction) {
      double paStop = _GetPriceActionStop(order);
      analysis += "Price Action Stop: " + DoubleToString(paStop, (int)MarketInfo(order.SymbolName, MODE_DIGITS)) + "\n";
    }

    if (this._useVolatilityAdjust) {
      double volStop = _GetVolatilityStop(order);
      analysis += "Volatility Stop: " + DoubleToString(volStop, (int)MarketInfo(order.SymbolName, MODE_DIGITS)) + "\n";
    }

    double recommended = _CalculateNewStop(order);
    analysis += "Recommended Stop: " + DoubleToString(recommended, (int)MarketInfo(order.SymbolName, MODE_DIGITS)) + "\n";

    delete order;
    return analysis;
  }
};
