//+------------------------------------------------------------------+
//| stdlib.mqh - legacy MetaQuotes standard library                  |
//| Current MT4 builds no longer ship <stdlib.mqh>, but older EAs    |
//| still #include it for ErrorDescription(). CI copies this file    |
//| into the compiler MQL4\Include directory before building.        |
//+------------------------------------------------------------------+
#property strict

string ErrorDescription(int error_code)
  {
   string e;
   switch(error_code)
     {
      case 0:
      case 1:    e="no error";                                                  break;
      case 2:    e="common error";                                              break;
      case 3:    e="invalid trade parameters";                                  break;
      case 4:    e="trade server is busy";                                      break;
      case 5:    e="old version of the client terminal";                        break;
      case 6:    e="no connection with trade server";                           break;
      case 7:    e="not enough rights";                                         break;
      case 8:    e="too frequent requests";                                     break;
      case 9:    e="malfunctional trade operation";                             break;
      case 64:   e="account disabled";                                          break;
      case 65:   e="invalid account";                                           break;
      case 128:  e="trade timeout";                                             break;
      case 129:  e="invalid price";                                             break;
      case 130:  e="invalid stops";                                             break;
      case 131:  e="invalid trade volume";                                      break;
      case 132:  e="market is closed";                                          break;
      case 133:  e="trade is disabled";                                         break;
      case 134:  e="not enough money";                                          break;
      case 135:  e="price changed";                                             break;
      case 136:  e="off quotes";                                                break;
      case 138:  e="requote";                                                   break;
      case 139:  e="order is locked";                                           break;
      case 140:  e="long positions only allowed";                              break;
      case 141:  e="too many requests";                                         break;
      case 145:  e="modification denied, order too close to market";           break;
      case 146:  e="trade context is busy";                                     break;
      case 147:  e="expirations are denied by broker";                         break;
      case 148:  e="orders limit reached";                                     break;
      case 4000: e="no error";                                                  break;
      case 4001: e="wrong function pointer";                                    break;
      case 4002: e="array index is out of range";                              break;
      case 4003: e="no memory for function call stack";                        break;
      case 4004: e="recursive stack overflow";                                 break;
      case 4051: e="invalid function parameter value";                         break;
      case 4052: e="string function internal error";                           break;
      case 4053: e="some array error";                                         break;
      case 4054: e="incorrect series array using";                             break;
      case 4055: e="custom indicator error";                                   break;
      case 4056: e="arrays are incompatible";                                  break;
      case 4057: e="global variables processing error";                        break;
      case 4058: e="global variable not found";                                break;
      case 4059: e="function is not allowed in testing mode";                  break;
      case 4060: e="function is not confirmed";                                 break;
      case 4061: e="send mail error";                                          break;
      case 4062: e="string parameter expected";                                break;
      case 4063: e="integer parameter expected";                               break;
      case 4064: e="double parameter expected";                                break;
      case 4065: e="array as parameter expected";                              break;
      case 4066: e="requested history data in update state";                   break;
      case 4099: e="end of file";                                              break;
      case 4105: e="no order selected";                                        break;
      case 4106: e="unknown symbol";                                           break;
      case 4107: e="invalid price parameter for trade function";               break;
      case 4108: e="invalid ticket";                                           break;
      case 4109: e="trade is not allowed";                                     break;
      case 4110: e="longs are not allowed";                                    break;
      case 4111: e="shorts are not allowed";                                   break;
      default:   e="unknown error";
     }
   return(e);
  }
