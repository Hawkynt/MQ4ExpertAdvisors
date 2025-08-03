#include "Common.mqh"
#include "Object.mqh"

class IMarketIndicator:public Object {
  private:
    string _symbolName;
  protected:
    IMarketIndicator(string symbolName){
      this._symbolName=symbolName;
    }
  public: 
    string SymbolName() {return(this._symbolName);}
    virtual bool IsLongEntryPoint(){ThrowInterfaceNotImplementedException("IMarketIndicator","IsLongEntryPoint()");return(false);}
    virtual bool IsShortEntryPoint(){ThrowInterfaceNotImplementedException("IMarketIndicator","IsShortEntryPoint()");return(false);}
    virtual bool IsLongTrend(){ThrowInterfaceNotImplementedException("IMarketIndicator","IsLongTrend()");return(false);}
    virtual bool IsShortTrend(){ThrowInterfaceNotImplementedException("IMarketIndicator","IsShortTrend()");return(false);}
};