//+------------------------------------------------------------------+
//|                                                 TrailingStop.mq4 |
//|                                          Copyright 2014, Hawkynt |
//|                                         http://www.synthelicz.de |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, Hawkynt"
#property link      "http://www.synthelicz.de"
#property version   "1.00"
#property strict

#include "../Libraries/OrderCollection.mqh"
#include "../Libraries/IOrderManager.mqh"

#include "../Libraries/OrderManagers/LinearTrailingStop.mqh"
#include "../Libraries/OrderManagers/Pyramid.mqh"
#include "../Libraries/MarketIndicators/MAParabolic.mqh"

//--- input parameters
input float    InitialTriggerPips=15.0f;
input float    InitialPips=5.0f;
input float    TrailingPips=10.0f;

input float    PyramidPips=20.0f;
input float    PyramidLotFactor=1.0f;

List* _managers;
IMarketIndicator* _indicator;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
//---
  _managers=new List(true);

// TODO: multi order manager, multi money manager, max loss order manager
  
  string thisSymbol=Symbol();
  
  _indicator=new MarketIndicators__MAParabolic(thisSymbol);
  
  /*
  _managers.Add(new OrderManagers__Grid(
    thisSymbol,
    new MoneyManagers__FixedLotSize(PercentOrLots),
    PyramidPips
  ));
  */
  /*
  _managers.Add(new OrderManagers__IndicatorTriggered(
    indicator,
    new MoneyManagers__PercentEquity(PercentOrLots)
    //new MoneyManagers__FixedLotSize(PercentOrLots)
  ));
  */
  
  _managers.Add(new OrderManagers__LinearTrailingStop(InitialTriggerPips,InitialPips,TrailingPips,thisSymbol));
  //_managers.Add(new OrderManagers__ExponentialTrailingStop(InitialTriggerPips,InitialPips,TrailingPips,thisSymbol));
  
  _managers.Add(new OrderManagers__Pyramid(PyramidPips,PyramidLotFactor,_indicator,thisSymbol));
  /*
  _managers.Add(new OrderManagers__MaxOrderPipLoss(-MaxLossPips,thisSymbol));
  */
  
  // print all orders
  OrderCollection* orders=OrderCollection::GetOpenOrders();
    orders.FilterBySymbolName(thisSymbol);
    orders.Print();
  delete(orders);
//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
//---
  if(_indicator!=NULL)
    delete(_indicator);

  delete(_managers);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
  for(int i=_managers.Count()-1;i>=0;--i)
    if(_managers.Item(i)!=NULL) ((IOrderManager*)_managers.Item(i)).Manage();
}
//+------------------------------------------------------------------+
