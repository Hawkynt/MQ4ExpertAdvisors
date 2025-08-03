#include "../IMoneyManager.mqh"

class MoneyManagers__RiskBalance:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__RiskBalance(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return(AccountBalance()*this._percentage/100.0/order.StopLossMoney());
    }
};
