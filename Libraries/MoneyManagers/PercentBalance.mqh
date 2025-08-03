#include "../IMoneyManager.mqh"

class MoneyManagers__PercentBalance:public IMoneyManager {
  private:
    double _percentage;

  public:
    MoneyManagers__PercentBalance(double percentage){
      this._percentage=percentage;
    }
  
    virtual double CalculateLots(Order* order){
      return((AccountBalance()/1000.0)*this._percentage*0.01);
    }
};
