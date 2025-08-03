#include "..\IMarketIndicator.mqh"

#define MA_TYPE MODE_SMA
#define MA_PRICE PRICE_CLOSE
#define MA_FAST 9
#define MA_SLOW 27

class MarketIndicators__MovingAverageCross:public IMarketIndicator {
  private:
    int _timeframe;
    int _Timeframe(){return(this._timeframe);}
  
  public:
    MarketIndicators__MovingAverageCross(string symbolName):IMarketIndicator(symbolName){
      this._timeframe=PERIOD_H1;
    }
    
    bool _IsMovingAverageLongTrend(int shift){
      return(iMA(this.SymbolName(),this._Timeframe(),MA_FAST,0,MA_TYPE,MA_PRICE,shift)>iMA(this.SymbolName(),this._Timeframe(),MA_SLOW,0,MA_TYPE,MA_PRICE,shift));
    }
    
    bool _IsMovingAverageShortTrend(int shift){
      return(iMA(this.SymbolName(),this._Timeframe(),MA_FAST,0,MA_TYPE,MA_PRICE,shift)<iMA(this.SymbolName(),this._Timeframe(),MA_SLOW,0,MA_TYPE,MA_PRICE,shift));
    }
        
    bool _IsLongTrend(int shift=0){
      return(this._IsMovingAverageLongTrend(shift));
    }
    
    bool _IsShortTrend(int shift=0){
      return(this._IsMovingAverageShortTrend(shift));
    }
    
    virtual bool IsLongEntryPoint(){
      return(this._IsLongTrend(0) && !this._IsLongTrend(1));
    }
    
    virtual bool IsShortEntryPoint(){
      return(this._IsShortTrend(0) && !this._IsShortTrend(1));
    }
    
    virtual bool IsLongTrend(){
      return(this._IsLongTrend());
    }
    
    virtual bool IsShortTrend(){
      return(this._IsShortTrend());
    }
};