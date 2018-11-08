
#include <bits/stdc++.h>
#define pii pair<string,string>

using namespace std;
extern FILE *logout;
extern FILE *print_symbol;
class Function{
    public:
     string returnType;
     string* parameterType;
     string* symbols;
     vector<pii> typeId;
     int numberOfParameters;
     bool isDefined;
     string returned_asm_value;
     Function(int number=0){
        parameterType= new string[number];
        symbols=new string[number];
        numberOfParameters=number;
        isDefined=false;
        returned_asm_value="";
        
     }
     void print(){
        cout<<"return :"<<returnType<<" no of par:" <<numberOfParameters<<endl;
        for(int i=0;i<numberOfParameters;i++){
             cout<<"< item ,"<<parameterType[i]<<"> ";
        }
	cout<<endl;
     }
     void printId(){
         for(int i=0;i<numberOfParameters;i++){
             cout<<"< item ,"<<typeId[i].first<<" variable "<<typeId[i].second<<"> ";
         }
	 cout<<endl;
     }

};

class SymbolInfo
{
    public:
        //variables
        SymbolInfo* Next;
        bool isFunction;
        bool isArray;
        Function* function;
	SymbolInfo** arrayValues;
        int noOfElements;
        int currentIndex;


        string Name;
        string Type;
        string Value;
        string DataType;
        

        string code;
        string symbol;
        //methods
        SymbolInfo()
	{
	    //ctor
	    Name="";
	    Type="";
            DataType="";
            code="";
            symbol="";
	    
	    isFunction=false;
	    isArray=false;
	    Value="";
	    function=NULL;
	    Next=NULL;
	    arrayValues=NULL;
	    arrayValues=new SymbolInfo*[1];
	    currentIndex=0;
	
	}
        SymbolInfo(SymbolInfo* s)
	{
	    //ctor
	    Name=s->Name;
	    Type=s->Type;
            DataType=s->DataType;
            code=s->code;
            symbol=s->symbol;
	    isFunction=s->isFunction;
	    isArray=s->isArray;
	    Value=s->Value;
	    function=NULL;
	    Next=NULL;
	    arrayValues=NULL;
	    arrayValues=new SymbolInfo*[1];
	    currentIndex=0;
	
	}
        ~SymbolInfo()
	{
    		//dtor
            /*    delete Next;
                for(int i=0;i<noOfElements;i++){
			delete arrayValues[i];
                }
                delete arrayValues;
                delete function;*/
	}
		
        //setter getter
        void  setArray(SymbolInfo** s,int d){
     
     	    noOfElements=d;
     	    arrayValues= new SymbolInfo*[d];
            for(int i=0;i<d;i++) {
		arrayValues[i]= new SymbolInfo();
                //arrayValues[i]->symbol=symbol;
               // arrayValues[i]->isArray=true;
               
            }            
     	    cout<<"size "<<noOfElements<<endl;
     	    arrayValues=s;
	}
        SymbolInfo* getArrayElement(int curr){
		return arrayValues[curr];
        }
        void setName(string iName){
    		Name=iName;
	}
        
        string getName(){
   		return Name;
	}
        void setType(string iType){
   		Type= iType;
	}

        string getType(){
   	return Type;
	}
	void setValue(string iValue){
	   Value= iValue;
	}
        string getValue(){
   		return Value;
	}
	
    protected:
    private:
       
};













 



class ScopeTable
{
    public:
        int number;

        ScopeTable *ParentTable;

        ScopeTable(int Size)
	{
    		//ctor
    		_size= Size;
    		insertedItem=0;
    		HashTable= new SymbolInfo* [_size];
    		for(int i=0;i<_size;i++){
         		HashTable[i]= new SymbolInfo;
    		}
	}
        int HashFunction(string key){
    		int length= key.length();
    		int sum;
    		for(int i=0;i<length;i++){
        		sum+= (key[i]* (i+1))%_size;
    		}
    		sum=sum%_size;
    		return sum;

	}
        template <typename T> string tostr(const T& t) { 
   		ostringstream os; 
   		os<<t; 
   		return os.str(); 
	} 
      //  bool Insert(string name,string type, int ID);
	bool Insert(SymbolInfo* newSymbol,int id){
		if(insertedItem== _size){
        		increaseSize();
   		}
   		string name= newSymbol->getName();
   		int index=HashFunction(name);
  		int Hash_index=0;
   		SymbolInfo* temp= new SymbolInfo;
   
   		temp=newSymbol;
                temp->symbol=temp->Name+tostr(number);
                cout<<"SYMBOL!!!!!"<<temp->symbol;
   		SymbolInfo* initial= HashTable[index];
   		if(initial == NULL){
   		   initial=temp;
   		   cout<<"Inserted in ScopeTable# "<<id<< " at position "<<index<<","<<Hash_index<<endl;
                   cout<<"Name of element "<<initial->Name<<"  "<<initial->DataType<<endl ;
   		   insertedItem++;
   		   return true;
   		}
   		while(initial->Next != NULL){
   		   // cout<<"NAME "<<initial->getName()<<" =="<<name<<endl;
   		    if(initial->getName()== name){
   		        cout<<"<"<<name<<","<<initial->getType()<<">"<<" already exists in current ScopeTable"<<endl;
   		        return false;
   		    }
   		    Hash_index++;
   		    initial=initial->Next;
   		}
   		if(initial->getName()== name){
   		        cout<<"<"<<name<<","<<initial->getType()<<">"<<" already exists in current ScopeTable"<<endl;
   		        return false;
   		 }
   		initial->Next=temp;
   		cout<<"Inserted in ScopeTable# "<<id<< " at position "<<index<<","<<Hash_index<<endl;
                cout<<"Name of element "<<temp->Name<<"  "<<temp->DataType<<endl ;
   		insertedItem++;
   		return true;

        }
        SymbolInfo* LookUp(string symbol,int id){
		int index= HashFunction(symbol);
    		int strt=0;

    		SymbolInfo* initial= HashTable[index]->Next;
    		while(initial != NULL){

        		if(initial->getName()== symbol) {
             		cout<<"Found in ScopeTable# "<<id<<" at position "<<index<<","<<strt<<endl;
             		return initial;
        		}
        		initial= initial->Next;
        		strt++;
    		}
    		cout<<"Not found"<<endl;
   		return NULL;

        }
        void Print(){
                SymbolInfo* temp;
    		for(int i=0;i<_size;i++){
        		temp=HashTable[i]->Next;
                        if(temp== NULL)  continue;
        		cout<<i<<"-->";
                        fprintf(logout,"%d-->",i);
        		while(temp != NULL){
           			if(temp->isFunction){
					cout<<"< "<<temp->getName()<<" , "<<temp->getType()<<" >";
				        fprintf(logout,"< %s , %s >",temp->getName().c_str(),temp->getType().c_str());
				}
           			else if(temp->isArray){
					cout<<"< "<<temp->getName()<<" , "<<temp->getType()<<" ,"<<temp->DataType<<", {";
                                        fprintf(logout,"< %s , %s ,%s , {",temp->getName().c_str(),temp->getType().c_str(),temp->DataType.c_str());
                			SymbolInfo **s=temp->arrayValues;
                			int Size=temp->noOfElements;
                			for(int i=0;i<Size;i++){
		     				cout<<s[i]->Value;
                                                fprintf(logout,"%s",s[i]->Value.c_str());
                     				if(i!= Size-1){
							cout<<" ,";
							fprintf(logout," ,");
						}
                			}
                			cout<<"}>";
                                        fprintf(logout,"}>");

           			}
          			 else  {
					cout<<"< "<<temp->getName()<<" , "<<temp->getType()<<" , "<<temp->getValue()<<" ,"<<temp->DataType<<" >";
					fprintf(logout,"< %s , %s ,%s >",temp->getName().c_str(),temp->getType().c_str(),temp->getValue().c_str());
				}
           			temp=temp->Next;

        		}
        		cout<<endl;
                        fprintf(logout,"\n");
    		}



        }
        void Printforsymtab(){
		SymbolInfo* temp;
    		for(int i=0;i<_size;i++){
        		temp=HashTable[i]->Next;
                        if(temp== NULL)  continue;
        		cout<<i<<"-->";
                        fprintf(print_symbol,"%d-->",i);
        		while(temp != NULL){
           			if(temp->isFunction){
					cout<<"< "<<temp->getName()<<" , "<<temp->getType()<<", "<<temp->DataType<<" >";
				        fprintf(print_symbol,"< %s , %s >",temp->getName().c_str(),temp->getType().c_str());
				}
           			else if(temp->isArray){
					cout<<"< "<<temp->getName()<<" , "<<temp->getType()<<" ,"<<temp->DataType<<", {";
                                        fprintf(print_symbol,"< %s , %s , {",temp->getName().c_str(),temp->getType().c_str());
                			SymbolInfo **s=temp->arrayValues;
                			int Size=temp->noOfElements;
                			for(int i=0;i<Size;i++){
		     				cout<<s[i]->Value;
                                                fprintf(print_symbol,"%s",s[i]->Value.c_str());
                     				if(i!= Size-1){
							cout<<" ,";
							fprintf(print_symbol," ,");
						}
                			}
                			cout<<"}>";
                                        fprintf(print_symbol,"}>");

           			}
          			 else  {
					cout<<"< "<<temp->getName()<<" , "<<temp->getType()<<" , "<<temp->getValue()<<" ,"<<temp->DataType<<" >";
					fprintf(print_symbol,"< %s , %s ,%s >",temp->getName().c_str(),temp->getType().c_str(),temp->getValue().c_str());
				}
           			temp=temp->Next;

        		}
        		cout<<endl;
                        fprintf(print_symbol,"\n");
    		}



        }
 	void increaseSize(){
              	int newSize=2* _size -1;
        	int old=_size;
        	SymbolInfo **newHash;
 		newHash= new SymbolInfo* [_size];
    		for(int i=0;i<_size;i++){
         		newHash[i]= new SymbolInfo;
    		}
        	newHash= HashTable;
        
        	HashTable= new SymbolInfo* [newSize];

        	for(int i=0;i<newSize;i++){
         		HashTable[i]= new SymbolInfo;
    		}
        	SymbolInfo* temp;
        	_size= newSize;
    		for(int i=0;i<old;i++){
                	temp=newHash[i]->Next;
        
        		while(temp != NULL){
      	        	   cout<<"< "<<temp->getName()<<": "<<temp->getType()<<" >";
                	   InsertOld(temp);
                	   //cout<<"inserted successfully "<<temp->getName()<<endl;
                	   temp=temp->Next;
	
                	}
       
       
       		}
        
       		cout<<"Size changed from "<<_size<<" to "<<newSize<<endl;
       		return ;


        }
        
        bool InsertOld(SymbolInfo* newSymbol){
              
   		string name= newSymbol->getName();
   		int index=HashFunction(name);
   		int Hash_index=0;
   		SymbolInfo* temp= new SymbolInfo;
   
   		temp=newSymbol;
   		SymbolInfo* initial= HashTable[index];
   		if(initial == NULL){
      			initial=temp;
      			//cout<<"Inserted in ScopeTable# "<<ID<< " at position "<<index<<","<<Hash_index<<endl;
      			insertedItem++;
      			return true;
   		}
   		while(initial->Next != NULL){
      			// cout<<"NAME "<<initial->getName()<<" =="<<name<<endl;
       			if(initial->getName()== name){
          			// cout<<"<"<<name<<","<<initial->getType()<<">"<<" already exists in current ScopeTable"<<endl;
        	   		return false;
       			}
       			Hash_index++;
       			initial=initial->Next;
   		}
   		if(initial->getName()== name){
        		 //  cout<<"<"<<name<<","<<initial->getType()<<">"<<" already exists in current ScopeTable"<<endl;
        		   return false;
    		}
   		initial->Next=temp;
  		// cout<<"Inserted in ScopeTable# "<<ID<< " at position "<<index<<","<<Hash_index<<endl;
   		insertedItem++;
   		return true;


        }
        bool Delete(string symbol,int id){
		int index= HashFunction(symbol);
    		int strt=-1;

    		SymbolInfo* initial= HashTable[index];
 		SymbolInfo *par=NULL;
    		SymbolInfo *temp;

   		 if(initial->getName()== symbol){
        		temp=initial;
        		initial=initial->Next;
        		cout<<"Found in ScopeTable# "<<id<<" at position "<<index<<","<<strt<<endl;
        		cout<<"Deleted entry at "<<index<<","<<strt<<"from current ScopeTable"<<endl;
        		delete temp;
    		}
    		while(initial != NULL){

        		if(initial->getName()== symbol) {
            			temp=initial;
            			par->Next=initial->Next;
            			cout<<"Found in ScopeTable# "<<id<<" at position "<<index<<","<<strt<<endl;
            			cout<<"Deleted entry at "<<index<<","<<strt<<" from current ScopeTable"<<endl;
            			delete temp;
            			return true;

        		}
        		par=initial;
        		strt++;
        		initial= initial->Next;

    		}
    		cout<<"Not found"<<endl;
   		 return false;



        }

        ~ScopeTable(){
		//dtor
    		SymbolInfo* temp, *curr;
    		for(int i=0;i<_size;i++){
        		temp=HashTable[i];
        	/*	while(temp!= NULL){
            			curr=temp;
            			temp=temp->Next;
            			delete curr;
        		}
        		delete temp;*/

    		}

        }


    protected:

    private:
      int insertedItem;
      SymbolInfo **HashTable;
      int _size;


};






















class SymbolTable
{
    public:
        int numberofScope;
        int id;
        int nowID;
        SymbolTable(int _size){
		 //ctor
    		Size=_size;
    		StackTable=NULL;
    		id=1;
                numberofScope=1;
                nowID=1;


	}
        //bool Insert(string name, string);
        bool Insert(SymbolInfo* symbol){
		if(StackTable == NULL){

      			StackTable= new ScopeTable(Size);
                        StackTable->number=numberofScope;
      			StackTable->Insert(symbol,id);
    		 	return true;

    		}

    		return StackTable->Insert(symbol,id);

        }
        bool Delete(string name){
		return StackTable->Delete(name,id);

        }
        SymbolInfo* LookUp(string name){
		ScopeTable* temp=StackTable;
    		SymbolInfo* ans;
    		int id_now=id;
    		while(temp!= NULL){
    		   ans=temp->LookUp(name,id_now);
    		   if(ans!= NULL) {
	
    		        return ans;
    		   }
    		   id_now--;
    		   temp=temp->ParentTable;
    		}
    		return NULL;
	}
        SymbolInfo* LookUpInTheScope(string name){
                 if(StackTable== NULL) return NULL;
                  SymbolInfo* s= NULL;
                   s=StackTable->LookUp(name,id);
                   if(s != NULL) return s;
                  return NULL;
                
        }

        void PrintCurrentScope(){

		StackTable->Print();
        }
        void EnterScope(){
		ScopeTable *New = new ScopeTable(Size);
     		id++;
                numberofScope++;
                New->number=numberofScope;
                //nowID=numberofScope;
     		cout<<"New ScopeTable with id "<<numberofScope<<" created"<<endl;
     		New->ParentTable= StackTable;
     		StackTable=New;
        }
        void ExitScope(){
                ScopeTable* temp=StackTable;
    		StackTable=StackTable->ParentTable;
    		cout<<"ScopeTable with id "<<numberofScope<<" removed"<<endl;
    		id--;
               // nowID=StackTable->number;
    		delete temp;

        }
        int getID(){

		return StackTable->number;
       }

        void PrintAllTable(){
		ScopeTable* temp=StackTable;
    		int id_now=id;
    		while(temp!= NULL){
    		   cout<<"ScopeTable # "<<temp->number<<endl;
                   fprintf(logout,"ScopeTable # %d\n",temp->number);
    		   temp->Print();
    		   temp=temp->ParentTable;
    		   id_now--;
    		   cout<<endl;
                   fprintf(logout,"\n");
    		}
	
        }
        void PrintAllTableforSymtab(){
		ScopeTable* temp=StackTable;
    		int id_now=id;
    		while(temp!= NULL){
    		   cout<<"ScopeTable # "<<temp->number<<endl;
                   fprintf(print_symbol,"ScopeTable # %d\n",temp->number);
    		   temp->Printforsymtab();
    		   temp=temp->ParentTable;
    		   id_now--;
    		   cout<<endl;
                   fprintf(print_symbol,"\n");
    		}
	
        }


        ~SymbolTable(){
		while(StackTable!= NULL){
       			ScopeTable* temp=StackTable;
       			StackTable=StackTable->ParentTable;
       			delete temp;
    		}
        }
    protected:
    private:
      ScopeTable* StackTable;
      int Size;
      
      
};



/*
int main(){
    SymbolInfo * newInfo= new SymbolInfo();

    newInfo->setName("function"),newInfo->setType("ID"),newInfo->setValue("0");
   Function* f=new Function(2);
    string *s= new string[2];
    s[0]="int",s[1]="float";
    f->parameterType=s;
    f->returnType="int";
    int d =2;
    d=getArrayLength(s);
    cout<<"size of f "<<d<<endl;
    f->numberOfParameters=d;
    newInfo->isFunction=true;
    newInfo->function=f;
    SymbolTable table(6);
    table.Insert(newInfo);

    SymbolInfo* array= new SymbolInfo();
    array->setName("array");
    array->setType("int");
    string *s1= new string[2];
    s1[0]="3",s1[1]="4";
     
    array->setArray(s1,2);
    array->isArray=true;
    //array->noOfElements=d;
    table.Insert(array);
    table.PrintCurrentScope();
    return 0;


}*/


