#include "Object.mqh"
#include "Instrument.mqh"
#include "Common.mqh"
#include <stdlib.mqh>

#define SELL_COLOR Red
#define BUY_COLOR Lime
#define VIRTUAL_TICKET_ID 0

class Order:public Object {
  private:
      
    // fields from mt
    int _ticket;
    string _symbolName;
    double _openPrice;
    double _closePrice;
    datetime _openTime;
    datetime _closeTime;
    double _stopLoss;
    double _takeProfit;
    int _type;
    int _magicNumber;
    string _comment;
    double _commission;
    double _swap;
    double _lots;
    double _profit;
    datetime _expiration;
    
    // other internal fields
    double _oldStopLoss;
    double _oldTakeProfit;
    double _oldLots;
    Instrument* _symbol;
    
    // static methods
    static int _GetEntryOrderType(Instrument*,bool,double);
      
    Order(){
    }
    
    Order(int type,string symbolName,double lots,double openPrice,string comment,int magicToken){
      this._ticket=VIRTUAL_TICKET_ID;
      this._symbolName=symbolName;
      this._openPrice=openPrice;
      this._type=type;
      this._magicNumber=magicToken;
      this._comment=comment;
      this._oldLots=this._lots=lots;
    }  
      
  public:
    // ctor,dtor
    ~Order(){
      this._symbolName=NULL;
      this._comment=NULL;
      Instrument* symbol=this._symbol;
      if(symbol!=NULL)
        delete(symbol);
      this._symbol=NULL;
    }
           
    // static methods
    static Order* FromCurrentSelection();
    static Order* CreateMarketOrder(string,bool,double,string,int);
    static Order* CreateEntryOrder(string,bool,double,double,string,int);
    
    // props
    int Ticket(){return(this._ticket);}
    string SymbolName() {return(this._symbolName);}
    double OpenPrice() {return(this._openPrice);}
    double ClosePrice() {return(this._closePrice);}
    datetime OpenTime() {return(this._openTime);}
    datetime CloseTime() {return(this._closeTime);}
    float AgeInSeconds(){return(float)((this.IsClosed()?this.CloseTime():TimeGMT())-this.OpenTime());}
    float AgeInMinutes(){return(this.AgeInSeconds()/60);}
    float AgeInHours(){return(this.AgeInMinutes()/60);}
    float AgeInDays(){return(this.AgeInHours()/24);}
    
    double StopLoss() {return(this._stopLoss);}
    void StopLoss(double value){this._stopLoss=value;}
    
    void TrailingStopLoss(double value){if(((!this.HasStopLoss())||(this.IsBuy()&&value>this.StopLoss())||(this.IsSell()&&value<this.StopLoss()))) this.StopLoss(value);}
    
    double TakeProfit() {return(this._takeProfit);}
    void TakeProfit(double value){this._takeProfit=value;}
    
    int Type(){return(this._type);}
    int MagicNumber(){return(this._magicNumber);}
    string Comment(){return(this._comment);}
    double Commission(){return(this._commission);}
    double Swap(){return(this._swap);}
    
    double Lots(){return(this._lots);}
    void Lots(double value){if(!(this.IsPlaced()&&this.IsMarket()))this._lots=value;else{ThrowNotSupportedException("changing lot size of life orders is not supported");}}
    
    double Profit(){return(this._profit);}
    datetime Expiration(){return(this._expiration);}
    Instrument* Symbol() {Instrument* result=this._symbol;if(result==NULL)this._symbol=result=Instrument::FromName(this.SymbolName());return(result);}
    bool NeedsCommit() {return((!this.IsClosed())&&(!this.IsPlaced() || this.IsStopLossChanged() || this.IsTakeProfitChanged() || this.IsLotsChanged()));}
    
    bool IsPlaced(){return(this.Ticket()!=VIRTUAL_TICKET_ID);}
    bool IsClosed(){return(this.CloseTime()>0);}
    bool IsBuy(){int type=this.Type();return(type==OP_BUY||type==OP_BUYLIMIT||type==OP_BUYSTOP);}
    bool IsSell(){int type=this.Type();return(type==OP_SELL||type==OP_SELLLIMIT||type==OP_SELLSTOP);}
    bool IsMarket(){int type=this.Type();return(type==OP_BUY||type==OP_SELL);}
    bool IsEntry(){int type=this.Type();return(type==OP_BUYLIMIT||type==OP_BUYSTOP||type==OP_SELLLIMIT||type==OP_SELLSTOP);}
    bool IsLotsChanged(){return(this._lots!=this._oldLots);}
    bool IsStopLossChanged(){return(this._stopLoss!=this._oldStopLoss);}
    bool IsTakeProfitChanged(){return(this._takeProfit!=this._oldTakeProfit);}
    
    int _SignFactor() {return(this.IsBuy()?1:this.IsSell()?-1:0);}
    
    double PointsProfit() { 
       if(!this.IsMarket())
          return(0);
       
       double delta=this.ClosePrice()-this.OpenPrice();
       delta/=this.Symbol().PointSize();
       return(delta*this._SignFactor());
    }
    
    double PointsSwap() {
       double result=this.Swap();
       result/=this.Symbol().PointCost();
       return(result);
    }
    
    double PointsCommission() {
       double result=this.Commission();
       result/=this.Symbol().PointCost();
       return(result);
    }
    
    double RealPointsProfit(){return(this.PointsProfit()+this.PointsSwap()+this.PointsCommission());}
    double PipsProfit(){return(this.PointsProfit()*this.Symbol().PointToPipFactor());}
    double PipsSwap(){return(this.PointsSwap()*this.Symbol().PointToPipFactor());}
    double PipsCommission(){return(this.PointsCommission()*this.Symbol().PointToPipFactor());}
    double RealPipsProfit(){return(this.RealPointsProfit()*this.Symbol().PointToPipFactor());}
    
    bool HasStopLoss(){return(this.StopLoss()!=0);}
    bool HasTakeProfit(){return(this.TakeProfit()!=0);}
    
    double StopLossPointsToOpen(){return((this.StopLoss()-this.OpenPrice())*this._SignFactor()/this.Symbol().PointSize());}
    void StopLossPointsToOpen(double value){this.StopLoss(this.OpenPrice()+this.Symbol().PointSize()*value*this._SignFactor());}
    void TrailingStopLossPointsToOpen(double value){this.TrailingStopLoss(this.OpenPrice()+this.Symbol().PointSize()*value*this._SignFactor());}
    
    double StopLossPipsToOpen() {return(this.StopLossPointsToOpen()*this.Symbol().PointToPipFactor());}
    void StopLossPipsToOpen(double value){this.StopLossPointsToOpen(value/this.Symbol().PointToPipFactor());}
    void TrailingStopLossPipsToOpen(double value){this.TrailingStopLossPointsToOpen(value/this.Symbol().PointToPipFactor());}
    
    double StopLossPointsToClose(){return((this.StopLoss()-this.ClosePrice())*this._SignFactor()/this.Symbol().PointSize());}
    void StopLossPointsToClose(double value){this.StopLoss(this.ClosePrice()+this.Symbol().PointSize()*value*this._SignFactor());}
    void TrailingStopLossPointsToClose(double value){this.TrailingStopLoss(this.ClosePrice()+this.Symbol().PointSize()*value*this._SignFactor());}
    
    double StopLossPipsToClose() {return(this.StopLossPointsToClose()*this.Symbol().PointToPipFactor());}
    void StopLossPipsToClose(double value){this.StopLossPointsToClose(value/this.Symbol().PointToPipFactor());}
    void TrailingStopLossPipsToClose(double value){this.TrailingStopLossPointsToClose(value/this.Symbol().PointToPipFactor());}
    
    double StopLossMoney() {return(this.StopLossPointsToOpen()*this.Symbol().PointCost()*this.Lots());}
    
    double TakeProfitPointsToOpen(){return((this.TakeProfit()-this.OpenPrice())*this._SignFactor()/this.Symbol().PointSize());}
    void TakeProfitPointsToOpen(double value){this.TakeProfit(this.OpenPrice()+this.Symbol().PointSize()*value*this._SignFactor());}
    
    double TakeProfitPipsToOpen() {return(this.TakeProfitPointsToOpen()*this.Symbol().PointToPipFactor());}
    void TakeProfitPipsToOpen(double value){this.TakeProfitPointsToOpen(value/this.Symbol().PointToPipFactor());}
    
    double TakeProfitPointsToClose(){return((this.TakeProfit()-this.ClosePrice())*this._SignFactor()/this.Symbol().PointSize());}
    void TakeProfitPointsToClose(double value){this.TakeProfit(this.ClosePrice()+this.Symbol().PointSize()*value*this._SignFactor());}
    
    double TakeProfitPipsToClose() {return(this.TakeProfitPointsToClose()*this.Symbol().PointToPipFactor());}
    void TakeProfitPipsToClose(double value){this.TakeProfitPointsToClose(value/this.Symbol().PointToPipFactor());}
    
    double TakeProfitMoney() {return(this.TakeProfitPointsToOpen()*this.Symbol().PointCost()*this.Lots());}

    // convenience aliases
    bool IsLong() { return this.IsBuy(); }
    bool IsShort() { return this.IsSell(); }
    bool IsInProfit() { return this.RealPipsProfit() > 0; }
    bool IsInLoss() { return this.RealPipsProfit() < 0; }
    bool IsLimit() { int type = this.Type(); return type == OP_BUYLIMIT || type == OP_SELLLIMIT; }
    bool IsStop() { int type = this.Type(); return type == OP_BUYSTOP || type == OP_SELLSTOP; }

    // spread
    double Spread() { return (this.Symbol().Ask() - this.Symbol().Bid()) / this.Symbol().PipSize(); }

    // breakeven price (price where profit = 0 after commission/swap)
    double BreakevenPrice() {
      if (!this.IsMarket())
        return this.OpenPrice();
      double costPips = -this.PipsCommission() - this.PipsSwap();
      return this.OpenPrice() + costPips * this.Symbol().PipSize() * this._SignFactor();
    }

    // risk amount in account currency based on stop loss
    double RiskAmount() {
      if (!this.HasStopLoss())
        return 0;
      return MathAbs(this.StopLossMoney());
    }

    // risk:reward ratio based on SL and TP distances
    double RiskRewardRatio() {
      if (!this.HasStopLoss() || !this.HasTakeProfit())
        return 0;
      double risk = MathAbs(this.StopLossPipsToOpen());
      if (risk == 0)
        return 0;
      double reward = MathAbs(this.TakeProfitPipsToOpen());
      return reward / risk;
    }

    // distance from current price to stop loss in pips
    double DistanceToStopLoss() {
      if (!this.HasStopLoss())
        return 0;
      return MathAbs(this.StopLossPipsToClose());
    }

    // distance from current price to take profit in pips
    double DistanceToTakeProfit() {
      if (!this.HasTakeProfit())
        return 0;
      return MathAbs(this.TakeProfitPipsToClose());
    }

    // profit as percentage of account equity
    double PercentProfit() {
      double equity = AccountEquity();
      if (equity == 0)
        return 0;
      return (this.Profit() / equity) * 100.0;
    }

    // margin required for this position
    double MarginRequired() {
      return MarketInfo(this.SymbolName(), MODE_MARGINREQUIRED) * this.Lots();
    }

    // day of week when order was opened (0=Sunday)
    int OpenDayOfWeek() { return TimeDayOfWeek(this.OpenTime()); }

    // close a portion of the position
    bool PartialClose(double lotsToClose) {
      if (!this.IsPlaced() || !this.IsMarket())
        return false;
      if (lotsToClose >= this.Lots())
        return false;
      double minLots = this.Symbol().MinLots();
      if (lotsToClose < minLots)
        return false;
      double closePrice = this.IsBuy() ? this.Symbol().Bid() : this.Symbol().Ask();
      return OrderClose(this.Ticket(), lotsToClose, closePrice, 0, this.IsBuy() ? BUY_COLOR : SELL_COLOR);
    }

    // modify stop loss with validation
    bool ModifyStopLoss(double newStopLoss) {
      if (!this.IsPlaced())
        return false;
      this.StopLoss(newStopLoss);
      return true;
    }

    // modify take profit with validation
    bool ModifyTakeProfit(double newTakeProfit) {
      if (!this.IsPlaced())
        return false;
      this.TakeProfit(newTakeProfit);
      return true;
    }

    // methods
    
    /// <summary>
    /// Prints the field values of this order.
    /// </summary>
    /// <param name="prefix">Optional: A prefix to show</param>
    void Print(string prefix=NULL){
      PrintFormat(
        "%s%s: %s(%.2f) @%f [%.1fpips/%.1freal] %s %s %s %s %s", 
        prefix!=NULL?prefix:"",
        this.IsPlaced()?StringFormat("%d",this.Ticket()):"virtual",
        this.SymbolName(),
        this.Lots(),
        this.OpenPrice(),
        this.PipsProfit(),
        this.RealPipsProfit(),
        this.IsMarket()?StringFormat("Profit:%.2f",this.Profit()):"",
        this.IsBuy()?"Buy":"Sell",
        this.IsEntry()?"Entry":"",
        this.HasStopLoss()?StringFormat("Stop:@%f(%.1fpips)",this.StopLoss(),this.StopLossPipsToOpen()):"",
        this.HasTakeProfit()?StringFormat("Limit:@%f(%.1fpips)",this.TakeProfit(),this.TakeProfitPipsToOpen()):"",
        0
      );
    }
  
    /// <summary>
    /// Closes this order or deletes it from the entries list.
    /// </summary>
    void Close(){
      if(!this.IsPlaced())
        return;
        
      if(this.IsMarket()){
        if(OrderClose(this.Ticket(),this.Lots(),this.IsBuy()?this.Symbol().Bid():this.Symbol().Ask(),0,this.IsBuy()?BUY_COLOR:SELL_COLOR))
          this._Refresh();
        return;
      }
      
      if(this.IsEntry()){
        if(OrderDelete(this.Ticket(),this.IsBuy()?BUY_COLOR:SELL_COLOR))
          this._Refresh();
        return;
      }
      
    }
  
    /// <summary>
    /// Commits any outstanding changes.
    /// </summary>
    void Commit(){
      if(!this.NeedsCommit())
        return;
      
      ClearErrors();
      
      bool lotsChangedForEntry=this.IsPlaced() && this.IsEntry() && this.IsLotsChanged();
      if(!this.IsPlaced() || lotsChangedForEntry) {
        
        // delete entries which have changed lot size
        if(lotsChangedForEntry && OrderDelete(this.Ticket()))
          this._ticket=VIRTUAL_TICKET_ID;
        
        // place order
        this._ticket=OrderSend(this.SymbolName(),this.Type(),this.Lots(),this.OpenPrice(),0,this.StopLoss(),this.TakeProfit(),this.Comment(),this.MagicNumber(),0,this.IsBuy()?BUY_COLOR:SELL_COLOR);
        int lastError=GetLastError();
        if(lastError!=ERR_NO_ERROR) {
          string description=ErrorDescription(lastError);
          this.Print(StringFormat("WARNING:Failed to open order:%s(%d):",description,lastError));
        }
        
        this._Refresh();
      }
      
      // set stop
      if(this.IsPlaced() && this.IsStopLossChanged() && OrderModify(this.Ticket(),this.OpenPrice(),NormalizeDouble(this.StopLoss(),this.Symbol().Digits()),this.TakeProfit(),this.Expiration(),SELL_COLOR))
        this._oldStopLoss=this._stopLoss;
      
      // set limit
      if(this.IsPlaced() && this.IsTakeProfitChanged() && OrderModify(this.Ticket(),this.OpenPrice(),this.StopLoss(),NormalizeDouble(this.TakeProfit(),this.Symbol().Digits()),this.Expiration(),BUY_COLOR))
        this._oldTakeProfit=this._takeProfit;
      
    }
  
    /// <summary>
    /// Tries to select the order and refreshes all fields.
    /// </summary>
    void _Refresh(){
      int ticket=this.Ticket();
      if(!this.IsPlaced() || !OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES) || !OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY))
        return;
      
      this._FillFromCurrentSelection();    
    }
    
    /// <summary>
    /// Refreshes all fields from the currently selected order.
    /// </summary>
    void _FillFromCurrentSelection(){
      this._ticket=OrderTicket();
      this._type=OrderType();
      this._symbolName=OrderSymbol();
      if(this._symbol!=NULL)
        delete(this._symbol);
        
      this._symbol=NULL;
      this._oldLots=this._lots=OrderLots();
      this._openPrice=OrderOpenPrice();
      this._oldStopLoss=this._stopLoss=OrderStopLoss();
      this._oldTakeProfit=this._takeProfit=OrderTakeProfit();
      this._comment=OrderComment();
      this._magicNumber=OrderMagicNumber();
      this._closePrice=OrderClosePrice();
      this._openTime=OrderOpenTime();
      this._closeTime=OrderCloseTime();
      this._commission=OrderCommission();
      this._swap=OrderSwap();
      this._profit=OrderProfit();
      this._expiration=OrderExpiration();
    }
    
    /// <summary>
    /// Copies all fields from another order instance.
    /// </summary>
    /// <param name="other">The other roder whose fields to copy</param>
    void _CopyFromOtherOrder(Order* other){
      this._ticket=other._ticket;
      this._type=other._type;
      this._symbolName=other._symbolName;
      if(this._symbol!=NULL)
        delete(this._symbol);
        
      this._symbol=NULL;
      this._lots=other._lots;
      this._oldLots=other._oldLots;
      this._openPrice=other._openPrice;
      this._oldStopLoss=other._oldStopLoss;
      this._stopLoss=other._stopLoss;
      this._oldTakeProfit=other._oldTakeProfit;
      this._takeProfit=other._takeProfit;
      this._comment=other._comment;
      this._magicNumber=other._magicNumber;
      this._closePrice=other._closePrice;
      this._openTime=other._openTime;
      this._closeTime=other._closeTime;
      this._commission=other._commission;
      this._swap=other._swap;
      this._profit=other._profit;
      this._expiration=other._expiration;
    }
    
    /// <summary>
    /// Creates a copy of this order instance.
    /// </summary>
    /// <returns>A new instance which has identical field values</returns>
    Order* Copy(){
      Order* result=new Order();
      result._CopyFromOtherOrder((Order*)this);
      return(result);
    }
};

Order* Order::FromCurrentSelection(){
  Order* result=new Order();
  result._FillFromCurrentSelection();
  return(result);   
}

Order* Order::CreateMarketOrder(string symbolName,bool isBuy,double lots,string comment=NULL,int magicToken=0){
  Instrument* symbol=Instrument::FromName(symbolName);
  Order* result=new Order(isBuy?OP_BUY:OP_SELL,symbolName,lots,isBuy?symbol.Ask():symbol.Bid(),comment,magicToken);
  delete symbol;
  return(result);
}

Order* Order::CreateEntryOrder(string symbolName,bool isBuy,double lots,double openPrice,string comment=NULL,int magicToken=0){
  Instrument* symbol=Instrument::FromName(symbolName);
  Order* result=new Order(Order::_GetEntryOrderType(symbol,isBuy,openPrice),symbolName,lots,openPrice,comment,magicToken);
  delete symbol;
  return(result);
}

int Order::_GetEntryOrderType(Instrument* symbol,bool isBuy,double price) {
  double current;
  
  if(isBuy) {
    current=symbol.Ask();
    if(price>current)
      return(OP_BUYSTOP);
    if(price<current)
      return(OP_BUYLIMIT);
    return(OP_BUY);
  }
  
  current=symbol.Bid();
  if(price>current)
    return(OP_SELLLIMIT);
  if(price<current)
    return(OP_SELLSTOP);
  return(OP_SELL);
}
