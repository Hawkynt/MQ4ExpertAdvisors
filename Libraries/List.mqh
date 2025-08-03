#include "Object.mqh"

class List:public Object {
  private:
    Object* _items[];
    bool _autoDisposeItems;
    int _count;
    int _capacity;
    
  public: 
    List(bool autoDisposeItems=false,int capacity=16){
      this._count=0;
      this.Capacity(capacity);
      this.AutoDisposeItems(autoDisposeItems);
    }
    ~List(){
      if(this.AutoDisposeItems())
        for(int i=this.Count()-1;i>=0;--i)
          if(this._items[i]!=NULL)
            delete(this._items[i]);
          
      ArrayResize(this._items,0,0);
    }
    
    Object* Item(int index){return(this._items[index]);}
    void Item(int index,Object* item){
      if(this.AutoDisposeItems()&&this._items[index]!=NULL)
        delete(this._items[index]);
      
      this._items[index]=item;
    }
    
    int Count(){return(this._count);}
    int Capacity(){return(this._capacity);}
    void Capacity(int value){
      if(this.AutoDisposeItems() && value<this.Count())
        for(int i=value;i<this.Count();++i)
          if(this._items[i]!=NULL)
            delete(this._items[i]);
      
      ArrayResize(this._items,value,0);
      this._capacity=value;
    }
    bool AutoDisposeItems(){return(this._autoDisposeItems);}
    void AutoDisposeItems(bool value){this._autoDisposeItems=value;}
    
    void _NeedSizeForElements(int count){
      int length=this.Count();
      int needed=count+length;
      if(needed<=this.Capacity())
        return;
        
      float newCapacity=(float)MathMax(1,this.Capacity());
      while(newCapacity<needed)
        newCapacity*=1.66f;
        
      this.Capacity((int)newCapacity);
    }
    
    void Clear(){
      int capacity=this.Capacity();
      this.Capacity(0);
      this.Capacity(capacity);
    }
    
    void Add(Object* item){
      this._NeedSizeForElements(1);
      this._items[this.Count()]=item;
      this._count++;
    }
    
    void AddRange(Object*& items[]){
      int length=ArraySize(items);
      this._NeedSizeForElements(length);
      for(int i=0;i<length;++i)
        this._items[this._count++]=items[i];
    }
    
    void AddRange(List* items){
      int length=items.Count();
      this._NeedSizeForElements(length);
      for(int i=0;i<length;++i)
        this._items[this._count++]=items.Item(i);
    }
    
    void RemoveAt(int index){
      int count=this.Count();
      if(index>=count)
        return;
        
      if(this.AutoDisposeItems()&&this._items[index]!=NULL)
        delete(this._items[index]);
        
      for(int i=index+1;i<count;++i)
        this._items[i-1]=this._items[i];
        
      this._items[count-1]=NULL;
      this._count--;
    }
    
    void Remove(Object* item){
      int count=this.Count();
      for(int i=0;i<count;++i){
        if(this._items[i]!=item)
          continue;
      
        this.RemoveAt(i);
        return;
      }
    }
    
    void RemoveAll(Object* item){
      int count=this.Count();
      for(int i=count-1;i>=0;--i){
        if(this._items[i]!=item)
          continue;
      
        this.RemoveAt(i);
        return;
      }
    }
    
    void RemoveAll(Object*& items[]){
      for(int i=ArraySize(items)-1;i>=0;--i)
        this.Remove(items[i]);
    }
};
