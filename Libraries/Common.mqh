#include <stdlib.mqh>

void ClearErrors(){
  while(GetLastError()!=ERR_NO_ERROR)
    ;
}

void ThrowInterfaceNotImplementedException(string interfaceName=NULL,string methodName=NULL){
  if(interfaceName==NULL)
    interfaceName="used";
  if(methodName==NULL)
    methodName="called";  
    
  ThrowException(StringFormat("The %s method of the %s interface is not implemented",methodName,interfaceName));  
}

void ThrowNotSupportedException(string objective=NULL){
  ThrowException(StringFormat("The objective %s is not supported",objective!=NULL?objective:""));
}

void ThrowArgumentException(string argument=NULL){
  ThrowException(StringFormat("The argument %s has a wrong value",argument!=NULL?argument:""));
}

void ThrowArgumentNullException(string argument=NULL){
  ThrowException(StringFormat("The argument %s is null",argument!=NULL?argument:""));
}

void ThrowException(string message){
  Alert(StringFormat("Exception:%s",message));
  DebugBreak();
  ExpertRemove();
}