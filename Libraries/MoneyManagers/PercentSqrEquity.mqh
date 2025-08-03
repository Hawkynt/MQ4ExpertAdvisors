#include "../IMoneyManager.mqh"

class MoneyManagers__PercentSqrEquity:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__PercentSqrEquity(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return(MathSqrt(AccountEquity()/1000.0)*this._percentage*0.01);
    }
};
