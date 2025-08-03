#include "../IMoneyManager.mqh"

class MoneyManagers__RiskMargin:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__RiskMargin(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return(AccountFreeMargin()*this._percentage/100.0/order.StopLossMoney());
    }
};
