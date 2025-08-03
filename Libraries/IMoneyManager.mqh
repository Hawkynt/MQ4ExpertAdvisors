#include "Common.mqh"
#include "Object.mqh"
#include "Order.mqh"

class IMoneyManager:public Object{
  private:
  
  protected:
  
  public:
    virtual double CalculateLots(Order* order){ThrowInterfaceNotImplementedException("IMoneyManager","CalculateLots(Order*)");return(0);}
};
