#include "../IMoneyManager.mqh"

class MoneyManagers__PercentSqrMargin:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__PercentSqrMargin(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return(MathSqrt(AccountFreeMargin()/1000.0)*this._percentage*0.01);
    }
};
