#include "../IMoneyManager.mqh"

class MoneyManagers__RiskEquity:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__RiskEquity(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return(AccountEquity()*this._percentage/100.0/order.StopLossMoney());
    }
};
