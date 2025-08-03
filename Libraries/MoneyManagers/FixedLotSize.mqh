#include "../IMoneyManager.mqh"

class MoneyManagers__FixedLotSize:public IMoneyManager {
  private:
    double _lotSize;

  public:
    MoneyManagers__FixedLotSize(double lotSize){
      this._lotSize=lotSize;
    }
  
    virtual double CalculateLots(Order* order){
      return(this._lotSize);
    }
};
