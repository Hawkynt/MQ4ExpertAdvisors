#include "..\IOrderManager.mqh"
#include "..\IMarketIndicator.mqh"
#include "..\IMoneyManager.mqh"
#include "..\OrderCollection.mqh"
#include "..\Instrument.mqh"

class OrderManagers__IndicatorTriggered:public IOrderManager {
  private:
    IMarketIndicator* _indicator;
    IMoneyManager* _moneyManger;
    float _distancePips;
    bool _closeOrders;
    
  public:
    ~OrderManagers__IndicatorTriggered(){
      this._indicator=NULL;
      this._moneyManger=NULL;
    }

    OrderManagers__IndicatorTriggered(IMarketIndicator* marketIndicator,IMoneyManager* moneyManager,bool closeOrders=true,bool managesBuy=true,bool managesSell=true){
      if(marketIndicator==NULL)
        ThrowArgumentNullException("marketIndicator");
      if(moneyManager==NULL)
        ThrowArgumentNullException("moneyManager");
      
      this.SymbolNameFilter(marketIndicator.SymbolName());
      this.IsManagingBuyOrders(managesBuy);
      this.IsManagingSellOrders(managesSell);
      this.MarketIndicator(marketIndicator);
      this.MoneyManager(moneyManager);
      this.CloseOrders(closeOrders);
    }
  
    bool CloseOrders(){return(this._closeOrders);}
    void CloseOrders(bool value){this._closeOrders=value;}
    float DistancePips(){return(this._distancePips);}
    void DistancePips(float value){this._distancePips=value;}
    IMarketIndicator* MarketIndicator(){return(this._indicator);}
    void MarketIndicator(IMarketIndicator* value){this._indicator=value;}
    IMoneyManager* MoneyManager(){return(this._moneyManger);}
    void MoneyManager(IMoneyManager* value){this._moneyManger=value;}
    
    virtual void Manage(){
      OrderCollection* orders=OrderCollection::GetOpenOrders();
      
      if(this.IsMagicNumberFilterPresent())
        orders.FilterByMagicNumber(this.MagicNumberFilter());
      
      if(this.IsSymbolNameFilterPresent())
        orders.FilterBySymbolName(this.SymbolNameFilter());
      
      IMarketIndicator* marketIndicator=this.MarketIndicator();
      
      int magicToken=this.IsMagicNumberFilterPresent()?this.MagicNumberFilter():0;
      string symbolName=this.SymbolNameFilter();
      
      bool isLongEntry=marketIndicator.IsLongEntryPoint();
      bool isShortEntry=marketIndicator.IsShortEntryPoint();
      bool isLongTrend=marketIndicator.IsLongTrend();
      bool isShortTrend=marketIndicator.IsShortTrend();
      
      // close old orders if needed
      if(this.CloseOrders()){
        for(int i=orders.Count()-1;i>=0;--i){
          Order* order=orders.Item(i);
          if(!order.IsPlaced()||order.IsClosed())
            continue;
            
          if((order.IsBuy()&&isShortEntry)||(order.IsSell()&&isLongEntry))
            order.Close();
            
        }
      }
      
      // decide whether to create new orders      
      Order* order=NULL;
     
      string comment="Indicator triggered "+(isLongEntry||isShortEntry?"entry":"re-entry");
      if(this.IsManagingBuyOrders() && (isLongEntry||isLongTrend))
        order=Order::CreateMarketOrder(symbolName,true,0.01,comment,magicToken);
      else if(this.IsManagingSellOrders() && (isShortEntry||isShortTrend))
        order=Order::CreateMarketOrder(symbolName,false,0.01,comment,magicToken);
      
      comment=NULL;
      
      // when no order needs to be opened, return
      if(order==NULL){
        delete(orders);
        return;
      }
      
      // calculate lot size
      double lots=this.MoneyManager().CalculateLots(order);
      lots=order.Symbol().AdjustLotSize(lots);
      
      // when lot size not possible, return
      if(lots==0){
        delete(order);
        delete(orders);
        return;
      }
      
      // set lots
      order.Lots(lots);
      
      Instrument* symbol=order.Symbol();
      double price=order.OpenPrice();
      double distancePips=this.DistancePips();
      double lowerBorder=price-distancePips*symbol.PipSize();
      double upperBorder=price+distancePips*symbol.PipSize();
      if(!(
        orders.IsAnyOrderInRange(lowerBorder,upperBorder,order.Type())
        ||orders.IsAnyOrderOpenSince(symbol.CurrentBarTime(PERIOD_H1),order.Type())
        ||orders.IsAnyOrderPresent(order.Type(),false)
      )){
        order.Print("Trying to open:");
        order.Commit();
      }
      delete(order);
      delete(orders);
    }
};
