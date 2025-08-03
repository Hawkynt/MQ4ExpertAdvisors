#include "AExistingOrdersManager.mqh"

#define _DEFAULT_FACTOR 1.5
#define _DEFAULT_INITIAL_PIPS 0

class OrderManagers__ExponentialTrailingStop:public OrderManagers__AExistingOrdersManager {
  private:
    float _trailingPips;
    float _initialTriggerPips;
    float _initialPips;
    float _factor;
    
    void _Init(float initialTriggerPips,float initialPips,float trailingPips,float factor,string symbolName,bool manageBuy,bool manageSell){
      this.SymbolNameFilter(symbolName);
      this.IsManagingBuyOrders(manageBuy);
      this.IsManagingSellOrders(manageSell);
      this.InitialTriggerPips(initialTriggerPips);
      this.InitialPips(initialPips);
      this.TrailingPips(trailingPips);
      this.Factor(factor);
    }
    
  public:
    OrderManagers__ExponentialTrailingStop(float initialTriggerPips,float initialPips,float trailingPips,float factor,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(initialTriggerPips,initialPips,trailingPips,factor,symbolName,manageBuy,manageSell);
    }
    OrderManagers__ExponentialTrailingStop(float initialTriggerPips,float initialPips,float trailingPips,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(initialTriggerPips,initialPips,trailingPips,_DEFAULT_FACTOR,symbolName,manageBuy,manageSell);
    }
    OrderManagers__ExponentialTrailingStop(float initialTriggerPips,float trailingPips,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(initialTriggerPips,_DEFAULT_INITIAL_PIPS,trailingPips,_DEFAULT_FACTOR,symbolName,manageBuy,manageSell);
    }
    OrderManagers__ExponentialTrailingStop(float trailingPips,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(trailingPips,_DEFAULT_INITIAL_PIPS,trailingPips,_DEFAULT_FACTOR,symbolName,manageBuy,manageSell);
    }
    
    float TrailingPips(){return(this._trailingPips);}
    void TrailingPips(float value){this._trailingPips=value;}
    float InitialTriggerPips(){return(this._initialTriggerPips);}
    void InitialTriggerPips(float value){this._initialTriggerPips=value;}
    float InitialPips(){return(this._initialPips);}
    void InitialPips(float value){this._initialPips=value;}
    float Factor(){return(this._factor);}
    void Factor(float value){this._factor=value;}
    
    void _ManageSingleOrder(Order* order){
      double realPipsProfit=order.RealPipsProfit();
      if(realPipsProfit>=this.InitialTriggerPips())
        order.TrailingStopLossPipsToOpen(this.InitialPips()+MathMin(0,-order.PipsCommission()-order.PipsSwap()));
      
      if(realPipsProfit>=this.TrailingPips())
        order.TrailingStopLossPipsToClose(-this.TrailingPips()*this.Factor()*(realPipsProfit/this.TrailingPips()));
    }
};
