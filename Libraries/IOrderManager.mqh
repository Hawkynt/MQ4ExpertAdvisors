#include "Common.mqh"
#include "Object.mqh"
#include "Instrument.mqh"

#define _NO_MAGIC_VALUE -1

class IOrderManager:public Object{
  private:
    int _magicNumber;
    string _symbolName;
    bool _manageBuyOrders;
    bool _manageSellOrders;
    Instrument* _symbol;
  
  protected:
    IOrderManager() {
      this._magicNumber=_NO_MAGIC_VALUE;
    }
  
    Instrument* _Symbol(){
      Instrument* result=this._symbol;
      if(result==NULL&&this.IsSymbolNameFilterPresent())
        result=this._symbol=Instrument::FromName(this.SymbolNameFilter());
      return(result);
    }
  
  public:
    ~IOrderManager(){
      this._symbolName=NULL;
      Instrument* symbol=this._symbol;
      if(symbol!=NULL)
        delete(symbol);
      this._symbol=NULL;
      
    }
    bool IsMagicNumberFilterPresent() {return(this._magicNumber!=_NO_MAGIC_VALUE);}
    int MagicNumberFilter(){return(this._magicNumber);}
    void MagicNumberFilter(int value){this._magicNumber=value;}
    
    bool IsSymbolNameFilterPresent() {return(this._symbolName!=NULL);}
    string SymbolNameFilter(){return(this._symbolName);}
    void SymbolNameFilter(string value){this._symbolName=value;}
    
    bool IsManagingBuyOrders(){return(this._manageBuyOrders);}
    void IsManagingBuyOrders(bool value){this._manageBuyOrders=value;}
    bool IsManagingSellOrders(){return(this._manageSellOrders);}
    void IsManagingSellOrders(bool value){this._manageSellOrders=value;}
    
    virtual void Manage(){ThrowInterfaceNotImplementedException("IOrderManager","Manage()");}
};
