#include "AExistingOrdersManager.mqh"

class OrderManagers__MaxOrderAge:public OrderManagers__AExistingOrdersManager {
  private:
    float _maxAgeInSeconds;
    bool _onlyLossOrders;
    
  public:
    OrderManagers__MaxOrderAge(float maxAgeInSeconds){
      this.MaxAgeInSeconds(maxAgeInSeconds);
    }
    
    float MaxAgeInSeconds(){return(this._maxAgeInSeconds);}
    void MaxAgeInSeconds(float value){this._maxAgeInSeconds=value;}
    bool OnlyLossOrders(){return(this._onlyLossOrders);}
    void OnlyLossOrders(bool value){this._onlyLossOrders=value;}
    
    void _ManageSingleOrder(Order* order){
      if(this.OnlyLossOrders()&&order.RealPointsProfit()>0)
        return;
    
      if(order.AgeInSeconds()>this.MaxAgeInSeconds())
        order.Close();
    }
};
