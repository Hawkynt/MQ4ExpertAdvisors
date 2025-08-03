#include "../IMoneyManager.mqh"

class MoneyManagers__PercentEquity:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__PercentEquity(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return((AccountEquity()/1000.0)*this._percentage*0.01);
    }
};
