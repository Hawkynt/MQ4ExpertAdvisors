#include "../IMoneyManager.mqh"

class MoneyManagers__PercentMargin:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__PercentMargin(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return((AccountFreeMargin()/1000.0)*this._percentage*0.01);
    }
};
