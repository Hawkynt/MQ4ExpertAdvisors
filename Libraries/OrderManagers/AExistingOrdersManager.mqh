#include "..\Common.mqh"
#include "..\OrderCollection.mqh"
#include "..\IOrderManager.mqh"

/// <summary>
/// The base class for managing existing entry/market orders.
/// </summary>
class OrderManagers__AExistingOrdersManager:public IOrderManager {
  public:
  
    /// <summary>
    /// Is executed on each tick for doing management.
    /// </summary>
    virtual void Manage(){
      OrderCollection* orders=OrderCollection::GetOpenOrders();
      
      if(this.IsMagicNumberFilterPresent())
        orders.FilterByMagicNumber(this.MagicNumberFilter());
      
      if(this.IsSymbolNameFilterPresent())
        orders.FilterBySymbolName(this.SymbolNameFilter());
      
      for(int i=orders.Count()-1;i>=0;--i)
        this.Manage(orders.Item(i));
      
      delete(orders);
    }
    
    /// <summary>
    /// Is executed on each tick/order for doing management.
    /// </summary>
    void Manage(Order* order){
      if(order.IsBuy() && !this.IsManagingBuyOrders())
        return;
        
      if(order.IsSell() && !this.IsManagingSellOrders())
        return;
    
      this._ManageSingleOrder(order);
        
      if(order.IsClosed()||!order.NeedsCommit())
        return;
      
      order.Commit();
    }
    
    /// <summary>
    /// Manages a supported order.
    /// </summary>
    virtual void _ManageSingleOrder(Order* order){ThrowInterfaceNotImplementedException("AExistingOrdersManager","_ManageSingleOrder(Order*)");}
};
