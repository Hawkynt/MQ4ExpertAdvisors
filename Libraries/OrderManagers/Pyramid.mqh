#include "AExistingOrdersManager.mqh"
#include "..\IMarketIndicator.mqh"

class OrderManagers__Pyramid:public OrderManagers__AExistingOrdersManager {
  private:
    float _distancePips;
    float _lotFactor;
    IMarketIndicator* _indicator;
    
    void _Init(float distancePips,float lotFactor,IMarketIndicator* indicator,string symbolName,bool manageBuy,bool manageSell){
      this.SymbolNameFilter(symbolName);
      this.IsManagingBuyOrders(manageBuy);
      this.IsManagingSellOrders(manageSell);
      this.DistancePips(distancePips);
      this.LotFactor(lotFactor);
      this.MarketIndicator(indicator);
    }
      
  
  public:
    OrderManagers__Pyramid(float distancePips,float lotFactor=1,IMarketIndicator* indicator=NULL,string symbolName=NULL,bool manageBuy=true,bool manageSell=true){
      this._Init(distancePips,lotFactor,indicator,symbolName,manageBuy,manageSell);
    }
      
    float DistancePips(){return(this._distancePips);}
    void DistancePips(float value){this._distancePips=value;}
    float LotFactor(){return(this._lotFactor);}
    void LotFactor(float value){this._lotFactor=value;}
    IMarketIndicator* MarketIndicator(){return(this._indicator);}
    void MarketIndicator(IMarketIndicator* value){this._indicator=value;}
    
    void _ManageSingleOrder(Order* order){
      
      // if buy not managed, ignore
      if(order.IsBuy() && !(this.MarketIndicator()==NULL || this.MarketIndicator().IsLongTrend()))
        return;
      
      // if sell not managed, ignore  
      if(order.IsSell() && !(this.MarketIndicator()==NULL || this.MarketIndicator().IsShortTrend()))
        return;
    
      // if order is still risky, ignore
      if(order.StopLossMoney()<=0)
        return;
    
      // if too less pips, ignore
      float distancePips=this.DistancePips();
      if(order.RealPipsProfit()<distancePips)
        return;
        
      Instrument* symbol=order.Symbol();
      double price=order.ClosePrice();
      double lowerBorder=price-distancePips*symbol.PipSize();
      double upperBorder=price+distancePips*symbol.PipSize();
    
      // if there is already another open order, ignore
      OrderCollection* currentOrders=OrderCollection::GetOpenOrders();
      if(this.IsSymbolNameFilterPresent())
        currentOrders.FilterBySymbolName(this.SymbolNameFilter());
      
      bool alreadyPresent=currentOrders.IsAnyOrderInRange(lowerBorder,upperBorder,order.Type());
      delete(currentOrders);
      
      if(alreadyPresent)
        return;
      
      // default to lot factor 1 if values below or equal zero
      float lotFactor=this.LotFactor();
      if(lotFactor<=0)
         lotFactor=1;
      
      // calculate lots for new order
      double lots=order.Lots()*lotFactor;
      lots=order.Symbol().AdjustLotSize(lots);
      if(lots<=0)
         return;
      
      Order* newOrder=Order::CreateMarketOrder(order.SymbolName(),order.IsBuy(),lots,"Pyramid");
      newOrder.Commit();
      Print("Building Pyramid on");
      order.Print();
      newOrder.Print();
      delete newOrder;
    }
};
