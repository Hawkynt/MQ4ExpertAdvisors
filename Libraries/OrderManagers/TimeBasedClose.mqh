#include "AExistingOrdersManager.mqh"

class OrderManagers__TimeBasedClose : public OrderManagers__AExistingOrdersManager {
private:
  int _closeHour;
  int _closeMinute;
  bool _onlyLossOrders;
  bool _useServerTime;
  int _dayOfWeek;

public:
  OrderManagers__TimeBasedClose(int closeHour, int closeMinute = 0, bool onlyLossOrders = false, bool useServerTime = true, int dayOfWeek = -1, string symbolName = NULL) {
    this.SymbolNameFilter(symbolName);
    this.IsManagingBuyOrders(true);
    this.IsManagingSellOrders(true);
    this._closeHour = closeHour;
    this._closeMinute = closeMinute;
    this._onlyLossOrders = onlyLossOrders;
    this._useServerTime = useServerTime;
    this._dayOfWeek = dayOfWeek;
  }

  int CloseHour() { return this._closeHour; }
  void CloseHour(int value) { this._closeHour = value; }
  int CloseMinute() { return this._closeMinute; }
  void CloseMinute(int value) { this._closeMinute = value; }
  bool OnlyLossOrders() { return this._onlyLossOrders; }
  void OnlyLossOrders(bool value) { this._onlyLossOrders = value; }
  bool UseServerTime() { return this._useServerTime; }
  void UseServerTime(bool value) { this._useServerTime = value; }
  int DayOfWeek() { return this._dayOfWeek; }
  void DayOfWeek(int value) { this._dayOfWeek = value; }

  void _ManageSingleOrder(Order* order) {
    if (!order.IsMarket())
      return;

    if (this._onlyLossOrders && order.RealPipsProfit() > 0)
      return;

    datetime currentTime = this._useServerTime ? TimeCurrent() : TimeLocal();
    int currentHour = TimeHour(currentTime);
    int currentMinute = TimeMinute(currentTime);
    int currentDayOfWeek = TimeDayOfWeek(currentTime);

    if (this._dayOfWeek >= 0 && this._dayOfWeek != currentDayOfWeek)
      return;

    if (currentHour > this._closeHour || (currentHour == this._closeHour && currentMinute >= this._closeMinute))
      order.Close();
  }
};
