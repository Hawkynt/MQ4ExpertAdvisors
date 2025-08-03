#include "AExistingOrdersManager.mqh"

class OrderManagers__MaxOrderLoss:public OrderManagers__AExistingOrdersManager {
  private:
    float _maxOrderLoss;
    
  public:
    OrderManagers__MaxOrderLoss(float maxOrderLoss){
      this.MaxOrderLoss(maxOrderLoss);
    }
    
    float MaxOrderLoss(){return(this._maxOrderLoss);}
    void MaxOrderLoss(float value){this._maxOrderLoss=value;}
    
    void _ManageSingleOrder(Order* order){
      if(order.Profit()<this.MaxOrderLoss())
        order.Close();
    }
};
