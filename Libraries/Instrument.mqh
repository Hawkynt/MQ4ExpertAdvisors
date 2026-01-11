#include "Object.mqh"

class Instrument:public Object {
  private:
    string _name;
    
  public:
    // ctor,dtor
    Instrument(string name) {
      this._name=name;
    }
    ~Instrument() {
      this._name=NULL;
    }
    
    // static
        
    /// <summary>
    /// Creates an instrument instance by it's name.
    /// </summary>
    static Instrument* FromName(string);
    /// <summary>
    /// Refreshes the rates of all symbols.
    /// </summary>
    static void RefreshRates();

    // props

    /// <summary>
    /// Gets the name
    /// </summary>
    string Name() {return(this._name);}
    /// <summary>
    /// Gets the size of a point, eg. 0.00001 on 5-digit brokers
    /// </summary>
    double PointSize(){return(MarketInfo(this.Name(),MODE_POINT));}
    /// <summary>
    /// Gets the cost of 1.00lot pip in the account currency
    /// </summary>
    double PipCost(){return(MarketInfo(this.Name(),MODE_TICKVALUE));}
    /// <summary>
    /// Gets the current bid price
    /// </summary>
    double Bid() {return(MarketInfo(this.Name(),MODE_BID));}
    /// <summary>
    /// Gets the current ask price
    /// </summary>
    double Ask() {return(MarketInfo(this.Name(),MODE_ASK));}
    /// <summary>
    /// Gets the number of digits eg. 5
    /// </summary>
    int Digits() {return((int)MarketInfo(this.Name(),MODE_DIGITS));}
    /// <summary>
    /// Gets the stop level (how many points must a stop be away from the open price)
    /// </summary>
    double StopLevel() {return(MarketInfo(this.Name(),MODE_STOPLEVEL));}
    double LotSize() {return(MarketInfo(this.Name(),MODE_LOTSIZE));}
    /// <summary>
    /// Gets the step in which lots are valid, eg. 0.01, 0.02, 0.1
    /// </summary>
    double LotStep() {return(MarketInfo(this.Name(),MODE_LOTSTEP));}
    /// <summary>
    /// Gets the minimum supported lot size
    /// </summary>
    double MinLots() {return(MarketInfo(this.Name(),MODE_MINLOT));}
    /// <summary>
    /// Gets the maximum supported lot size
    /// </summary>
    double MaxLots() {return(MarketInfo(this.Name(),MODE_MAXLOT));}
    /// <summary>
    /// Gets the factor to convert from points to pips
    /// </summary>
    double PointToPipFactor() {
      return(0.1);
    }
    /// <summary>
    /// Gets the size of a pip eg. 0.0001
    /// </summary>
    double PipSize() {return(this.PointSize()/this.PointToPipFactor());}
    /// <summary>
    /// Gets the cost of a 1.00lot point in the account currency
    /// </summary>
    double PointCost() {return(this.PipCost()*this.PointToPipFactor());}
    datetime CurrentBarTime(int period){return(iTime(this.Name(),period,0));}
    
    // methods
    
    /// <summary>
    /// Refreshes the rates for this symbol
    /// </summary>
    void Refresh() {Instrument::RefreshRates();}
    double AdjustLotSize(double lotSize){

      lotSize=NormalizeDouble(lotSize,2);

      double lotStep=this.LotStep();
      lotSize=int(lotSize/lotStep)*lotStep;

      if(lotSize<this.MinLots())
        return(0);

      if(lotSize>this.MaxLots())
        return(this.MaxLots());

      return(lotSize);
    }

    // spread and cost properties

    /// <summary>
    /// Gets the current spread in points
    /// </summary>
    double Spread() { return (this.Ask() - this.Bid()) / this.PointSize(); }
    /// <summary>
    /// Gets the current spread in pips
    /// </summary>
    double SpreadPips() { return (this.Ask() - this.Bid()) / this.PipSize(); }
    /// <summary>
    /// Gets the spread cost per lot in account currency
    /// </summary>
    double SpreadCost() { return this.SpreadPips() * this.PipCost(); }

    // volatility and range properties

    /// <summary>
    /// Gets the Average True Range for the specified period and timeframe
    /// </summary>
    double AverageTrueRange(int period = 14, int timeframe = PERIOD_H1) {
      return iATR(this.Name(), timeframe, period, 0);
    }
    /// <summary>
    /// Gets the Average True Range in pips
    /// </summary>
    double AverageTrueRangePips(int period = 14, int timeframe = PERIOD_H1) {
      return this.AverageTrueRange(period, timeframe) / this.PipSize();
    }
    /// <summary>
    /// Gets today's range (High - Low)
    /// </summary>
    double DailyRange() {
      return iHigh(this.Name(), PERIOD_D1, 0) - iLow(this.Name(), PERIOD_D1, 0);
    }

    // swap and margin properties

    /// <summary>
    /// Gets the overnight swap for long positions
    /// </summary>
    double SwapLong() { return MarketInfo(this.Name(), MODE_SWAPLONG); }
    /// <summary>
    /// Gets the overnight swap for short positions
    /// </summary>
    double SwapShort() { return MarketInfo(this.Name(), MODE_SWAPSHORT); }
    /// <summary>
    /// Gets the margin required per standard lot
    /// </summary>
    double MarginRequired() { return MarketInfo(this.Name(), MODE_MARGINREQUIRED); }
    /// <summary>
    /// Gets the contract size
    /// </summary>
    double ContractSize() { return MarketInfo(this.Name(), MODE_LOTSIZE); }

    // trading constraints

    /// <summary>
    /// Gets the freeze level (minimum distance for pending order modification)
    /// </summary>
    double FreezeLevel() { return MarketInfo(this.Name(), MODE_FREEZELEVEL); }
    /// <summary>
    /// Checks whether trading is allowed for this symbol
    /// </summary>
    bool TradeAllowed() { return MarketInfo(this.Name(), MODE_TRADEALLOWED) != 0; }

    // price utilities

    /// <summary>
    /// Gets the mid price ((Ask + Bid) / 2)
    /// </summary>
    double MidPrice() { return (this.Ask() + this.Bid()) / 2.0; }
    /// <summary>
    /// Gets the current bar high for the specified timeframe
    /// </summary>
    double CurrentHigh(int timeframe = PERIOD_H1) { return iHigh(this.Name(), timeframe, 0); }
    /// <summary>
    /// Gets the current bar low for the specified timeframe
    /// </summary>
    double CurrentLow(int timeframe = PERIOD_H1) { return iLow(this.Name(), timeframe, 0); }
    /// <summary>
    /// Gets the current bar open for the specified timeframe
    /// </summary>
    double CurrentOpen(int timeframe = PERIOD_H1) { return iOpen(this.Name(), timeframe, 0); }
    /// <summary>
    /// Gets the previous bar close for the specified timeframe
    /// </summary>
    double PreviousClose(int timeframe = PERIOD_H1) { return iClose(this.Name(), timeframe, 1); }

    // conversion and normalization

    /// <summary>
    /// Normalizes a price to the correct number of digits for this symbol
    /// </summary>
    double NormalizePrice(double price) { return NormalizeDouble(price, this.Digits()); }
    /// <summary>
    /// Checks if a stop distance (in points) meets broker requirements
    /// </summary>
    bool IsValidStopDistance(double distanceInPoints) {
      return distanceInPoints >= this.StopLevel();
    }
    /// <summary>
    /// Converts points to price offset
    /// </summary>
    double PointsToPrice(double points) { return points * this.PointSize(); }
    /// <summary>
    /// Converts pips to price offset
    /// </summary>
    double PipsToPrice(double pips) { return pips * this.PipSize(); }
};

Instrument* Instrument::FromName(string name){
  return(new Instrument(name));
}

void Instrument::RefreshRates(){
  RefreshRates();
}
