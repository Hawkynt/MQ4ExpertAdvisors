#include "List.mqh"
#include "Order.mqh"

class OrderCollection{
  private:
    OrderCollection(int capacity){
      this._items=new List(true,capacity);
    }
    
    static OrderCollection* _GetOrders(int);

    List* _items;
    void _Add(Order* order){this._items.Add(order);}
    void _RemoveAt(int index){this._items.RemoveAt(index);}
    
  public:

    ~OrderCollection(){
      delete(this._items);
    }

    // static methods
    static OrderCollection* GetOpenOrders();
    static OrderCollection* GetHistoricOrders();
    
    // props    
    int Count(){return(this._items.Count());}
    Order* Item(int index){return(this._items.Item(index));}
    
    double Profit(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).Profit();
      return(result);
    }
    
    double Commission(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).Commission();
      return(result);
    }
    
    double Swap(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).Swap();
      return(result);
    }
    
    double Lots(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).Lots();
      return(result);
    }
    
    double PointsProfit(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).PointsProfit();
      return(result);
    }
    
    double RealPointsProfit(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).RealPointsProfit();
      return(result);
    }
    
    double PointsSwap(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).PointsSwap();
      return(result);
    }
    
    double PointsCommission(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).PointsCommission();
      return(result);
    }
    
    double PipsProfit(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).PipsProfit();
      return(result);
    }
    
    double RealPipsProfit(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).RealPipsProfit();
      return(result);
    }
    
    double PipsSwap(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).PipsSwap();
      return(result);
    }
    
    double PipsCommission(){
      double result=0;
      for(int i=this.Count()-1;i>=0;--i)
        result+=this.Item(i).PipsCommission();
      return(result);
    }
    
    // methods
    void Print(){
      for(int i=this.Count()-1;i>=0;--i)
        this.Item(i).Print();
    }
    
    void CloseAll(){
      for(int i=this.Count()-1;i>=0;--i)
        this.Item(i).Close();
    }
    
    OrderCollection* Copy(){
      int length=this.Count();
      OrderCollection* result=new OrderCollection(length);
      for(int i=length-1;i>=0;--i)
        result._Add(this.Item(i).Copy());
      
      return(result);
    }
    
    void FilterBySymbolName(string symbolName) {
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).SymbolName()!=symbolName)
          this._RemoveAt(i);
    }
    
    void FilterByMagicNumber(int magicNumber) {
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).MagicNumber()!=magicNumber)
          this._RemoveAt(i);
    }
 
    void RemoveAllMarketOrders(){
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).IsMarket())
          this._RemoveAt(i);
    }
    
    void RemoveAllEntryOrders(){
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).IsEntry())
          this._RemoveAt(i);
    }
    
    bool IsAnyOrderPresent(int type=-1,bool onlyProfitable=false) {
      for(int i=this.Count()-1;i>=0;--i) {
        Order* order=this.Item(i);
        
        if(type!=-1&&type!=order.Type())
          continue;
        
        if(onlyProfitable&&order.RealPointsProfit()<=0)
          continue;
        
        return(true);
      }
      return(false);
    }
    
    // check orders bounds inclusive
    bool IsAnyOrderInRange(double minPrice,double maxPrice,int type=-1) {
      for(int i=this.Count()-1;i>=0;--i) {
        Order* order=this.Item(i);
        
        if(type!=-1&&type!=order.Type())
          continue;
        
        double openPrice=order.OpenPrice();
        if(openPrice>=minPrice && openPrice<=maxPrice)
          return(true);
      }
      return(false);
    }
    
    // check orders bounds exclusive
    bool IsAnyOrderWithinRange(double minPrice,double maxPrice,int type=-1) {
      for(int i=this.Count()-1;i>=0;--i) {
        Order* order=this.Item(i);
        
        if(type!=-1&&type!=order.Type())
          continue;
        
        double openPrice=order.OpenPrice();
        if(openPrice>minPrice && openPrice<maxPrice)
          return(true);
      }
      return(false);
    }
    
    bool IsAnyOrderOpenSince(datetime time,int type=-1){
      for(int i=this.Count()-1;i>=0;--i) {
        Order* order=this.Item(i);

        if(type!=-1&&type!=order.Type())
          continue;

        if(order.OpenTime()>=time)
          return(true);
      }
      return(false);
    }

    // Additional filter methods

    void FilterByType(int orderType) {
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).Type()!=orderType)
          this._RemoveAt(i);
    }

    void FilterByProfitability(bool profitableOnly) {
      for(int i=this.Count()-1;i>=0;--i) {
        double profit = this.Item(i).Profit();
        if(profitableOnly && profit <= 0)
          this._RemoveAt(i);
        else if(!profitableOnly && profit > 0)
          this._RemoveAt(i);
      }
    }

    void FilterByAgeMinutes(int minAge, int maxAge = -1) {
      datetime now = TimeCurrent();
      for(int i=this.Count()-1;i>=0;--i) {
        int ageMinutes = (int)((now - this.Item(i).OpenTime()) / 60);
        if(ageMinutes < minAge)
          this._RemoveAt(i);
        else if(maxAge >= 0 && ageMinutes > maxAge)
          this._RemoveAt(i);
      }
    }

    void FilterOpenedToday() {
      datetime todayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).OpenTime() < todayStart)
          this._RemoveAt(i);
    }

    void FilterByDirection(bool longOnly) {
      for(int i=this.Count()-1;i>=0;--i) {
        int type = this.Item(i).Type();
        bool isLong = (type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP);
        if(longOnly && !isLong)
          this._RemoveAt(i);
        else if(!longOnly && isLong)
          this._RemoveAt(i);
      }
    }

    // Additional aggregation methods

    double GetLongExposure() {
      double result = 0;
      for(int i=this.Count()-1;i>=0;--i) {
        int type = this.Item(i).Type();
        if(type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP)
          result += this.Item(i).Lots();
      }
      return result;
    }

    double GetShortExposure() {
      double result = 0;
      for(int i=this.Count()-1;i>=0;--i) {
        int type = this.Item(i).Type();
        if(type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP)
          result += this.Item(i).Lots();
      }
      return result;
    }

    double GetDirectionalBias() {
      double longExp = GetLongExposure();
      double shortExp = GetShortExposure();
      double total = longExp + shortExp;
      if(total == 0)
        return 0;
      return (longExp - shortExp) / total;
    }

    Order* GetWorstPerformingOrder() {
      if(this.Count() == 0)
        return NULL;
      Order* worst = this.Item(0);
      double worstProfit = worst.Profit();
      for(int i=this.Count()-1;i>=1;--i) {
        Order* order = this.Item(i);
        if(order.Profit() < worstProfit) {
          worst = order;
          worstProfit = order.Profit();
        }
      }
      return worst;
    }

    Order* GetBestPerformingOrder() {
      if(this.Count() == 0)
        return NULL;
      Order* best = this.Item(0);
      double bestProfit = best.Profit();
      for(int i=this.Count()-1;i>=1;--i) {
        Order* order = this.Item(i);
        if(order.Profit() > bestProfit) {
          best = order;
          bestProfit = order.Profit();
        }
      }
      return best;
    }

    double GetAverageOpenPrice(int type = -1) {
      double totalValue = 0;
      double totalLots = 0;
      for(int i=this.Count()-1;i>=0;--i) {
        Order* order = this.Item(i);
        if(type != -1 && order.Type() != type)
          continue;
        double lots = order.Lots();
        totalValue += order.OpenPrice() * lots;
        totalLots += lots;
      }
      if(totalLots == 0)
        return 0;
      return totalValue / totalLots;
    }

    int WinCount() {
      int count = 0;
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).Profit() > 0)
          ++count;
      return count;
    }

    int LoseCount() {
      int count = 0;
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).Profit() < 0)
          ++count;
      return count;
    }

    Order* GetOldestOrder() {
      if(this.Count() == 0)
        return NULL;
      Order* oldest = this.Item(0);
      for(int i=this.Count()-1;i>=1;--i) {
        Order* order = this.Item(i);
        if(order.OpenTime() < oldest.OpenTime())
          oldest = order;
      }
      return oldest;
    }

    Order* GetNewestOrder() {
      if(this.Count() == 0)
        return NULL;
      Order* newest = this.Item(0);
      for(int i=this.Count()-1;i>=1;--i) {
        Order* order = this.Item(i);
        if(order.OpenTime() > newest.OpenTime())
          newest = order;
      }
      return newest;
    }

    int CountByType(int orderType) {
      int count = 0;
      for(int i=this.Count()-1;i>=0;--i)
        if(this.Item(i).Type() == orderType)
          ++count;
      return count;
    }

    double GetMaxProfit() {
      if(this.Count() == 0)
        return 0;
      double maxProfit = this.Item(0).Profit();
      for(int i=this.Count()-1;i>=1;--i) {
        double profit = this.Item(i).Profit();
        if(profit > maxProfit)
          maxProfit = profit;
      }
      return maxProfit;
    }

    double GetMinProfit() {
      if(this.Count() == 0)
        return 0;
      double minProfit = this.Item(0).Profit();
      for(int i=this.Count()-1;i>=1;--i) {
        double profit = this.Item(i).Profit();
        if(profit < minProfit)
          minProfit = profit;
      }
      return minProfit;
    }

};

OrderCollection* OrderCollection::_GetOrders(int mode){
  int length=mode==MODE_HISTORY?OrdersHistoryTotal():OrdersTotal();
  OrderCollection* result=new OrderCollection(length);
  for(int i=0;i<length;++i) {
  
    if(!OrderSelect(i,SELECT_BY_POS,mode))
      continue;
  
    result._Add(Order::FromCurrentSelection());
  }
  
  return(result);
}

OrderCollection* OrderCollection::GetOpenOrders(){
  return(OrderCollection::_GetOrders(MODE_TRADES ));
}

OrderCollection* OrderCollection::GetHistoricOrders(){
  return(OrderCollection::_GetOrders(MODE_HISTORY ));
}
