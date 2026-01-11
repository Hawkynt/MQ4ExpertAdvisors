#include "AExistingOrdersManager.mqh"

enum ENUM_TRADING_SESSION {
  SESSION_SYDNEY,
  SESSION_TOKYO,
  SESSION_LONDON,
  SESSION_NEW_YORK
};

class OrderManagers__SessionTradingManager : public OrderManagers__AExistingOrdersManager {
private:
  ENUM_TRADING_SESSION _activeSession;
  bool _closeOutsideSession;
  int _sessionStartHour;
  int _sessionEndHour;
  bool _useCustomHours;

  void _GetSessionHours(ENUM_TRADING_SESSION session, int &startHour, int &endHour) {
    switch (session) {
      case SESSION_SYDNEY:
        startHour = 22;
        endHour = 7;
        break;
      case SESSION_TOKYO:
        startHour = 0;
        endHour = 9;
        break;
      case SESSION_LONDON:
        startHour = 8;
        endHour = 17;
        break;
      case SESSION_NEW_YORK:
        startHour = 13;
        endHour = 22;
        break;
    }
  }

  bool _IsWithinSession() {
    int startHour, endHour;

    if (this._useCustomHours) {
      startHour = this._sessionStartHour;
      endHour = this._sessionEndHour;
    } else {
      _GetSessionHours(this._activeSession, startHour, endHour);
    }

    int currentHour = TimeHour(TimeCurrent());

    if (startHour < endHour)
      return currentHour >= startHour && currentHour < endHour;
    return currentHour >= startHour || currentHour < endHour;
  }

public:
  OrderManagers__SessionTradingManager(
    ENUM_TRADING_SESSION activeSession = SESSION_LONDON,
    bool closeOutsideSession = true,
    string symbolName = ""
  ) : OrderManagers__AExistingOrdersManager() {
    this.SymbolNameFilter(symbolName);
    this._activeSession = activeSession;
    this._closeOutsideSession = closeOutsideSession;
    this._useCustomHours = false;
    this._sessionStartHour = 0;
    this._sessionEndHour = 0;
  }

  ENUM_TRADING_SESSION ActiveSession() { return this._activeSession; }
  void ActiveSession(ENUM_TRADING_SESSION value) { this._activeSession = value; this._useCustomHours = false; }
  bool CloseOutsideSession() { return this._closeOutsideSession; }
  void CloseOutsideSession(bool value) { this._closeOutsideSession = value; }

  void SetCustomSession(int startHour, int endHour) {
    this._sessionStartHour = startHour;
    this._sessionEndHour = endHour;
    this._useCustomHours = true;
  }

  bool IsSessionActive() {
    return _IsWithinSession();
  }

  virtual void _ManageSingleOrder(Order* order) {
    if (!order.IsMarket())
      return;

    if (!this._closeOutsideSession)
      return;

    if (_IsWithinSession())
      return;

    order.Close();
  }
};
