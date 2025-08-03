#include "..\IOrderManager.mqh"
#include "..\IMoneyManager.mqh"
#include "..\OrderCollection.mqh"

#define _DEFAULT_PREFETCH_COUNT 1

class OrderManagers__Grid:public IOrderManager {
  private:
    int _prefetchOrderCount;
    float _distancePips;
    IMoneyManager* _moneyManger;
    
    double _GridSpace(){
      return(this._Symbol().PipSize()*this.DistancePips());
    }
    
  public:
    OrderManagers__Grid(string symbolName,IMoneyManager* moneyManager,float distancePips,bool isManagingBuyOrders=true,bool isManagingSellOrders=true,int magicToken=-1, int prefetchOrderCount=_DEFAULT_PREFETCH_COUNT){
      this.SymbolNameFilter(symbolName);
      this.MoneyManager(moneyManager);
      this.DistancePips(distancePips);
      this.PrefetchOrderCount(prefetchOrderCount);
      this.IsManagingBuyOrders(isManagingBuyOrders);
      this.IsManagingSellOrders(isManagingSellOrders);
      this.MagicNumberFilter(magicToken);
    }
    
    ~OrderManagers__Grid(){
      this._moneyManger=NULL;
    }
    
    // props
    int PrefetchOrderCount(){return(this._prefetchOrderCount);}
    void PrefetchOrderCount(int value){this._prefetchOrderCount=value;}
    float DistancePips(){return(this._distancePips);}
    void DistancePips(float value){this._distancePips=value;}
    IMoneyManager* MoneyManager(){return(this._moneyManger);}
    void MoneyManager(IMoneyManager* value){this._moneyManger=value;}
    
    // methods
    void Manage(){
      OrderCollection* orders=OrderCollection::GetOpenOrders();
      
      if(this.IsMagicNumberFilterPresent())
        orders.FilterByMagicNumber(this.MagicNumberFilter());
      
      if(this.IsSymbolNameFilterPresent())
        orders.FilterBySymbolName(this.SymbolNameFilter());
      
      Instrument* symbol=this._Symbol();
      
      if(this.IsManagingBuyOrders())
        this._BuildEntryGrid(symbol.Ask(),true,orders);
      
      if(this.IsManagingSellOrders())
        this._BuildEntryGrid(symbol.Bid(),false,orders);
      
      
      delete(orders);
    }
    
    void _BuildEntryGrid(double currentPrice,bool isBuy,OrderCollection* orders){
      string symbolName=this.SymbolNameFilter();
      double gridSpace=this._GridSpace();
      IMoneyManager* moneyManager=this.MoneyManager();
      int magicToken=this.IsMagicNumberFilterPresent()?this.MagicNumberFilter():0;
      
      double basePrice=currentPrice/gridSpace;
      basePrice=isBuy?MathFloor(basePrice):MathCeil(basePrice);
      basePrice*=gridSpace;
      
      double sign=isBuy?1:-1;
      for(int i=this.PrefetchOrderCount();i>0;--i){
        double price=basePrice+sign*i*gridSpace;
        int type1=isBuy?OP_BUYLIMIT:OP_SELLLIMIT;
        int type2=isBuy?OP_BUYSTOP:OP_SELLSTOP;
        int type3=isBuy?OP_BUY:OP_SELL;
        
        
        if(
          orders.IsAnyOrderWithinRange(price-gridSpace,price+gridSpace,type1)||
          orders.IsAnyOrderWithinRange(price-gridSpace,price+gridSpace,type2)||
          orders.IsAnyOrderWithinRange(price-gridSpace,price+gridSpace,type3)
        )
          continue;
        
        Order* newOrder=Order::CreateEntryOrder(symbolName,isBuy,0.01,price,StringFormat("Grid %s @ %d",(isBuy?"long":"short"),price),magicToken);
        double lots=moneyManager.CalculateLots(newOrder);
        if(lots>0){
          newOrder.Lots(lots);
          newOrder.Commit();
        }
        delete(newOrder);
      }
    }
};
