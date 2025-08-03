#include "AExistingOrdersManager.mqh"

class OrderManagers__LinearTrailingStop:public OrderManagers__AExistingOrdersManager {
  private:
    float _trailingPips;
    float _initialTriggerPips;
    float _initialPips;
    void _Init(float initialTriggerPips,float initialPips,float trailingPips,string symbolName,bool manageBuy,bool manageSell){
      this.SymbolNameFilter(symbolName);
      this.IsManagingBuyOrders(manageBuy);
      this.IsManagingSellOrders(manageSell);
      this.InitialTriggerPips(initialTriggerPips);
      this.InitialPips(initialPips);
      this.TrailingPips(trailingPips);
    }
    
  public:
    OrderManagers__LinearTrailingStop(float initialTriggerPips,float initialPips,float trailingPips,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(initialTriggerPips,initialPips,trailingPips,symbolName,manageBuy,manageSell);
    }
    OrderManagers__LinearTrailingStop(float initialTriggerPips,float trailingPips,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(initialTriggerPips,0,trailingPips,symbolName,manageBuy,manageSell);
    }
    OrderManagers__LinearTrailingStop(float trailingPips,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(trailingPips,0,trailingPips,symbolName,manageBuy,manageSell);
    }
    
    float TrailingPips(){return(this._trailingPips);}
    void TrailingPips(float value){this._trailingPips=value;}
    float InitialTriggerPips(){return(this._initialTriggerPips);}
    void InitialTriggerPips(float value){this._initialTriggerPips=value;}
    float InitialPips(){return(this._initialPips);}
    void InitialPips(float value){this._initialPips=value;}
    
    void _ManageSingleOrder(Order* order){
      double realPipsProfit=order.RealPipsProfit();
      if(realPipsProfit>=this.InitialTriggerPips())
        order.TrailingStopLossPipsToOpen(this.InitialPips()+MathMin(0,-order.PipsCommission()-order.PipsSwap()));
      
      if(realPipsProfit>=this.TrailingPips())
        order.TrailingStopLossPipsToClose(-this.TrailingPips());
    }
};
