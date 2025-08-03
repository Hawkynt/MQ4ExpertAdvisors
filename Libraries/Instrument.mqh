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
};

Instrument* Instrument::FromName(string name){
  return(new Instrument(name));
}

void Instrument::RefreshRates(){
  RefreshRates();
}
