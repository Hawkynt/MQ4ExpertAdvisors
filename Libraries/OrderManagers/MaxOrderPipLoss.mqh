#include "AExistingOrdersManager.mqh"

class OrderManagers__MaxOrderPipLoss:public OrderManagers__AExistingOrdersManager {
  private:
    float _maxOrderLoss;
    
  public:
    OrderManagers__MaxOrderPipLoss(float maxOrderLoss,string symbolName=NULL,bool isManagingBuyOrders=true,bool isManagingSellOrders=true,int magicToken=-1){
      this.MaxOrderLoss(maxOrderLoss);
      if(symbolName!=NULL)
        this.SymbolNameFilter(symbolName);
      if(magicToken!=NULL)
        this.MagicNumberFilter(magicToken);
      this.IsManagingBuyOrders(isManagingBuyOrders);
      this.IsManagingSellOrders(isManagingSellOrders);
    }
    
    float MaxOrderLoss(){return(this._maxOrderLoss);}
    void MaxOrderLoss(float value){this._maxOrderLoss=value;}
    
    void _ManageSingleOrder(Order* order){
      if(order.IsEntry())
        return;
        
      if(order.RealPipsProfit()<this.MaxOrderLoss())
        order.Close();
    }
};
