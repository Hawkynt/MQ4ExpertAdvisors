#include "../IMoneyManager.mqh"

class MoneyManagers__PercentSqrBalance:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__PercentSqrBalance(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return(MathSqrt(AccountBalance()/1000.0)*this._percentage*0.01);
    }
};
