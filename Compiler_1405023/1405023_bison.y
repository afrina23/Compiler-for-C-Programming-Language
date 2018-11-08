%{

#define YYSTYPE SymbolInfo*
#define pii pair<string,string>
#include <stdio.h>
#include <stdlib.h>
#include "1405023_SymbolTable.h"

using namespace std;

SymbolTable* table;
SymbolInfo* workingFunction=NULL;
int yylex(void);
extern FILE* yyin;
extern int yylineno;
FILE *logout;
FILE *errorFile;
FILE *print_symbol;
FILE *asm_file;
FILE *optimized;

string variable_type;
string function_return_type;
string return_type;
vector<pii> parameterList;
vector<SymbolInfo*> argument_list;
string returned_type="void";
bool scopeCreated=false;
bool notFunction=false;


int labelCount=0;
int tempCount=0;

string variable_declare;
string outdec;
string start_code;
extern int linecount;
extern int errorcount;
int curly_brace=0;
void yyerror(string str)
{
	
	cout << "ERROR at Line " << linecount << " : " << str << endl << endl << endl;
        fprintf(logout,"ERROR at Line  %d : %s\n\n",linecount,str.c_str());
	fprintf(errorFile,"ERROR at Line  %d : %s\n\n",linecount,str.c_str());
        errorcount++;
}
template <typename T> string tostr(const T& t) { 
   ostringstream os; 
   os<<t; 
   return os.str(); 
} 

char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
        variable_declare+= string(t) + " DW " + "?\n";
	return t;
}
bool searchInScope(SymbolInfo* s1){
      SymbolInfo* s= table->LookUpInTheScope(s1->Name);
      if(s== NULL) return false;
      return true;

}




void insertVariable(SymbolInfo* s){

      if(searchInScope(s)){
	    yyerror("Multiple Declaration of "+s->Name);
            
            return;
      }
       if(variable_type=="void"){
            yyerror("A variable cannot be declared as void ");
            
            return;

       }
	s->Value="-1e+007";
      
        
        s->symbol=s->Name+ tostr(table->getID());
         variable_declare+= s->symbol + " DW " + "?\n";
        cout<<variable_declare<<"   hocche na kn???"<<endl;
        s->DataType=variable_type;
        table->Insert(s);
        
        //table->PrintAllTable();
}

void insertArray(SymbolInfo * s, SymbolInfo* const_int){

        if(searchInScope(s)){
	    yyerror("Multiple Declaration of "+s->Name);
            
            return;
        }
		
        SymbolInfo* newItem= new SymbolInfo();
        newItem->Name= s->Name;
        newItem->Type=s->Type;
        newItem->symbol=s->symbol+tostr(table->getID());
        newItem->isArray=true;
        newItem->DataType=variable_type;
        newItem->noOfElements=atoi((const_int->Value).c_str());
        SymbolInfo** element= new SymbolInfo*[newItem->noOfElements];
        variable_declare+= newItem->symbol+" DW ";
        for(int i=0;i<newItem->noOfElements;i++){
		element[i]= new SymbolInfo();
                element[i]->DataType=variable_type;
                element[i]->Value="-1";
                element[i]->Name=s->Name;
                element[i]->symbol=newItem->symbol;
                element[i]->isArray=true;
                variable_declare+= " ?";
                if(i != (newItem->noOfElements-1)) variable_declare+=",";
                

        }
        variable_declare+= "\n";
       // table->Insert(newItem);
        newItem->setArray(element,newItem->noOfElements);
        table->Insert(newItem);
        //table->PrintAllTable();
  
}

void insertFunctionDeclare(SymbolInfo* name,SymbolInfo* return_type){

     if(searchInScope(name)){
	    yyerror("Multiple Declaration of "+name->Name);
            
            return;
      }
     Function* newFunc= new Function(parameterList.size());
     newFunc->returnType=function_return_type;
     string* parameter= new string[parameterList.size()];
     cout<<"size of vector !!!!!!!!!!!!!!!!!!"<<parameterList.size()<<endl;
     for(int i=0;i<parameterList.size();i++){
	parameter[i]=parameterList[i].first;
     }
     newFunc->parameterType=parameter;
     newFunc->returned_asm_value= newTemp();
     newFunc->isDefined=false;
     SymbolInfo *newItem= new SymbolInfo();
     newItem->function=newFunc;
     newItem->isFunction=true;
     newItem->Name=name->Name;
     newItem->Value="0";
     newItem->Type=name->Type;
     newItem->DataType= "int";
     parameterList.clear();
     table->Insert(newItem);
     newItem->function->print();
     //table->PrintAllTable();

}

void insertFunctionDefine(SymbolInfo* name,SymbolInfo* return_type){

     Function* newFunc= new Function(parameterList.size());
     newFunc->returnType= function_return_type;
     string* parameter= new string[parameterList.size()];
     string* symbol= new string[parameterList.size()];
     cout<<"size of vector !!!!!!!!!!!!!!!!!!"<<parameterList.size()<<endl;
     for(int i=0;i<parameterList.size();i++){
	parameter[i]=parameterList[i].first;
        symbol[i]=parameterList[i].second+tostr(table->numberofScope+1);
     }
     newFunc->typeId=parameterList;
     newFunc->parameterType=parameter;
     newFunc->symbols=symbol;
     newFunc->isDefined=true;
     SymbolInfo *newItem= new SymbolInfo();
     newItem->function=newFunc;
     newItem->isFunction=true;
     newItem->Name=name->Name;
     newItem->Value="0";
     newItem->Type=name->Type;
     newItem->DataType= "int";
    
     SymbolInfo* prev= table->LookUp(name->Name);
     if(prev!=NULL){
          if(prev->isFunction==false) {
		yyerror("Multiple definition of variable");
               
		return;
          }
          else{
		if(prev->function->isDefined==true){
			yyerror("Multiple definition of function");
               		
			return;
		}
                else{
                     newFunc->print();
                     prev->function->print();
		     if(prev->function->returnType != newFunc->returnType){
                        yyerror("mismatch in return type of function");
               		
			return;
                     }
                     else if(prev->function->numberOfParameters != newFunc->numberOfParameters){
                        yyerror("mismatch in parameter number of function");
               		
			return;
                     }
                     else{
                           for(int i=0;i<newFunc->numberOfParameters;i++){
                                 cout<<parameter[i]<<" type dekha hocche "<< prev->function->parameterType[i]<<endl;
                                 if(parameter[i] != prev->function->parameterType[i]){
                                       yyerror("mismatch in parameter type of function");
               		              
			               return;
				 }
                           }
                           newItem->function->returned_asm_value=prev->function->returned_asm_value;
                           prev=newItem;
                           cout<<"function replace hoye gese!!!!!!!"<<endl;
                           
                     }
                }
          }

     }
     else{
        newItem->function->returned_asm_value=newTemp();
        newItem->DataType= "int";
   	table->Insert(newItem);
     }
     
     parameterList.clear();
     newItem->function->print();
     newItem->function->printId();
     //table->PrintAllTable();
     workingFunction=newItem;
     

}

void insertParameter(){

     vector<pii> var=workingFunction->function->typeId;
    
     int Size=var.size();
     for(int i=0;i<Size;i++){
        SymbolInfo * parameter= new SymbolInfo();
     	parameter->Value="-1e+007";
        parameter->Type="ID";
	parameter->Name=var[i].second;
         parameter->DataType=var[i].first;
        parameter->symbol=var[i].second+tostr(table->numberofScope);
       table->Insert(parameter);
        variable_declare+= parameter->symbol + " DW " + "?\n";
        cout<<"<name "<<parameter->Name<<" type "<<parameter->DataType<<">";
        //delete parameter;
     }
     //table->PrintAllTable();
     
}
SymbolInfo* gen_for_function(SymbolInfo* s1,SymbolInfo* s2){
	SymbolInfo*  ans= new SymbolInfo();
        SymbolInfo* f= table->LookUp(s1->Name);
        if(f==NULL){
		return ans;        
	}
        if(f->isFunction==false  ) {
		return ans;
        }
	
        ans->code=f->Name+" PROC\n";
        if(f->Name== "main"){
		ans->code+="mov ax, @data\nmov ds, ax\n\n\n";
        }
        else{
		ans->code+="PUSH AX\nPUSH BX\nPUSH CX\nPUSH DX\n";
                ans->code+="PUSH BP\nmov BP, SP\n";        
	}
        Function* function=f->function;
        int number=function->numberOfParameters;
        for(int i=number-1;i>=0;i--){
		//SymbolInfo* sym=table->LookUp(function->typeId[i].second);
                
                int num=12+(number-i-1)*2;
                ans->code+="mov ax, [BP+"+tostr(num)+"]\n";
                ans->code+="mov "+function->symbols[i]+", ax\n";

        }
        ans->code+=s2->code;
        
        
        
        if(function->returnType != "void"){
              
              if(f->Name != "main") ans->code+="POP BP\nPOP DX\nPOP CX\nPOP BX\nPOP AX\n";
              if(number != 0)ans->code+="ret "+tostr(number*2)+"\n";
        }
        else ans->code+="ret \n";
        if(f->Name=="main"){
		ans->code+="\n\nmov ah, 4ch\nint 21h\n\n";
        }
        ans->code+=f->Name+" ENDP\n\n\n";
        cout<<"function likhi "<<ans->code<<endl;
        return ans;
}

SymbolInfo* variableInc(SymbolInfo *s1,SymbolInfo *s2){
      SymbolInfo* s= table->LookUp(s1->Name);
      //cout<<" s value double"<<s->Value<<endl;
      if(s->isFunction){
            if(s->function->returnType== "void") {
		yyerror(s->Name+" function return type is void");
                return s;
            }
		
       }


        



      if(s->DataType== "int"){
            int num=atoi((s->Value).c_str());
            
      	    if(s2->Name== "++") num=num+1;
	    else num=num-1;
            s1->Value=tostr(num);
            s->Value=tostr(num);
	    //cout<<" s value int  "<<s->Value<<" "<<num<<endl;
      }
      else if(s->DataType== "float"){
            float num=atof((s->Value).c_str());
	    
      	    if(s2->Name== "++") num=num+1;
	    else num=num-1;
            s1->Value=tostr(num);
	    s->Value=tostr(num);
	  //  cout<<" s value float"<<s->Value<<endl;
      }
      else if(s->DataType== "double"){
            double num=::atof((s->Value).c_str());
	    
      	    if(s2->Name== "++") num=num+1;
	    else num=num-1;
            s1->Value=tostr(num);
	    s->Value=tostr(num);
	//    cout<<" s value double"<<s->Value<<endl;
      }
     // cout<<" s value "<<s->Value<<endl;
     // table->PrintAllTable();
     
     
     s->code= s1->code;
     if(s2->Name== "++"){
		if(s->isArray) s->code+= "mov ax, "+s1->symbol+"[bx]\n";
		else s->code+= "mov ax, "+s1->symbol+"\n";
                s->code+= "add ax, 1\n";
                if(s->isArray) s->code+= "mov "+s1->symbol+"[bx], ax\n";
		else s->code+= "mov "+s1->symbol+", ax\n";
     }
     else    {
		if(s->isArray) s->code+= "mov ax, "+s1->symbol+"[bx]\n";
		else s->code+= "mov ax, "+s1->symbol+"\n";
                s->code+= "sub ax, 1\n";
                if(s->isArray) s->code+= "mov "+s1->symbol+"[bx], ax\n";
		else s->code+= "mov "+s1->symbol+", ax\n";

     }
     
     cout<<s->code<<endl;
      
      return s;
      

}


void assignVariable(SymbolInfo* s1,SymbolInfo* s2){
        SymbolInfo* s= table->LookUp(s1->Name);
        if(s2->isFunction){
            if(s2->function->returnType== "void") {
		yyerror(s2->Name+" function return type is void");
                return ;
            }
	
        }
        
        if(s== NULL) return;
         cout<<s1->DataType<<"!!!!!!!!!!!!!!!!TYPE!!!!!"<<s2->DataType<<endl;
        if(s1->DataType=="int" && (s2->DataType=="float"||s2->DataType=="double")){
		yyerror("Type Mismatch"+ s1->DataType+ "  "+s2->DataType);
               // errorcount++;
                 return;
        }
	s1->Value=s2->Value;
}


SymbolInfo* handleMulOp(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3){
        if(s1->isFunction){
            if(s1->function->returnType== "void") {
		yyerror(s1->Name+" function return type is void");
                return s3;
            }
		
        }
        else if(s3->isFunction){
            if(s3->function->returnType== "void") {
		yyerror(s3->Name+" function return type is void");
                return s1;
            }
		
        }
         
        SymbolInfo* ans= new SymbolInfo();
       // if(s1->Type== "ID") s1=table->LookUp(s1->Name);
        //if(s3->Type== "ID") s3=table->LookUp(s3->Name);
   	if(s1->DataType== "int" && s3->DataType== "int"){
             cout<<"doing int into int"<<endl;
             int one=atoi((s1->Value).c_str());
             int two=atoi((s3->Value).c_str()); 
             int answer;
             if(s2->Name== "*"){
 		answer= one* two;
             }
             else if(s2->Name== "/"){
 		answer= one/ two;
             }
             else if(s2->Name== "%"){
 		answer= one%two;
             }
             ans->Value=tostr(answer);
             ans->DataType="int";


        }
        else if((s1->DataType== "float" && s3->DataType== "int")||(s1->DataType== "int" && s3->DataType== "float")){
             float one=atof((s1->Value).c_str());
             float two=atof((s3->Value).c_str()); 
             float answer;
	     cout<<"doing float into int"<<endl;
             if(s2->Name== "*"){
 		answer= one* two;
             }
             else if(s2->Name== "/"){
 		answer= one/ two;
             }
             else if(s2->Name== "%"){
 		yyerror("Non-Integer operand on modulus operator");
                //errorcount++;
             }
             ans->Value=tostr(answer);
             ans->DataType="float";


        }
        else if((s1->DataType== "double" && s3->DataType== "int") ||(s1->DataType== "int" && s3->DataType== "double")) {
             double one=::atof((s1->Value).c_str());
             double two=::atof((s3->Value).c_str()); 
             double answer;
	     cout<<"doing float into int"<<endl;
             if(s2->Name== "*"){
 		answer= one* two;
             }
             else if(s2->Name== "/"){
 		answer= one/ two;
             }
             else if(s2->Name== "%"){
 		yyerror("Non-Integer operand on modulus operator");
                //errorcount++;
             }
             ans->Value=tostr(answer);
             ans->DataType="double";


        }
        
        else if(s1->DataType== "float" && s3->DataType== "float"){
             float one=atof((s1->Value).c_str());
             float two=atof((s3->Value).c_str()); 
             float answer;
	     cout<<"doing float into float"<<endl;
             if(s2->Name== "*"){
 		answer= one* two;
             }
             else if(s2->Name== "/"){
 		answer= one/ two;
             }
             else if(s2->Name== "%"){
 		yyerror("Non-Integer operand on modulus operator");
		//errorcount++;
             }
             ans->Value=tostr(answer);
             ans->DataType="float";


        }
        else if(s1->DataType== "double" && s3->DataType== "double"){
             double one=::atof((s1->Value).c_str());
             double two=::atof((s3->Value).c_str()); 
             double answer;
	     cout<<"doing float into float"<<endl;
             if(s2->Name== "*"){
 		answer= one* two;
             }
             else if(s2->Name== "/"){
 		answer= one/ two;
             }
             else if(s2->Name== "%"){
 		yyerror("Non-Integer operand on modulus operator");
		//errorcount++;
             }
             ans->Value=tostr(answer);
             ans->DataType="double";


        }
        
        ans->code=s1->code+s3->code;
	ans->code += "mov ax, "+ s1->symbol+"\n";
	ans->code += "mov bx, "+ s3->symbol +"\n";
	char *temp=newTemp();
	if(s2->Name=="*"){
		ans->code += "mul bx\n";
		ans->code += "mov "+ string(temp) + ", ax\n";
	}
	else if(s2->Name=="/"){
	        // clear dx, perform 'div bx' and mov ax to temp
                ans->code+= "xor dx, dx\n";
                ans->code+= "div bx\n";
                ans->code+= "mov "+string(temp)+ ", ax\n"; 
	}
	else{
	       // clear dx, perform 'div bx' and mov dx to temp
               ans->code+= "xor dx, dx\n";
               ans->code+= "div bx\n";
               ans->code+= "mov "+string(temp)+ ", dx\n";
               
	}
	ans->symbol=(temp);
	cout << endl << ans->code << endl;
        cout<<ans->Value<<"Valueeee mul!!!!!!!!!!!!!"<<endl;
        return ans;
}

SymbolInfo* handleRelOp(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3){
        
        SymbolInfo* ans= new SymbolInfo();
	ans->DataType="int";
        if(s1->isFunction){
            if(s1->function->returnType== "void") {
		yyerror(s1->Name+" function return type is void");
                return ans;
            }
		
        }
        else if(s3->isFunction){
            if(s3->function->returnType== "void") {
		yyerror(s3->Name+" function return type is void");
                return ans;
            }
		
        }
        
        int value;
         
        float a=atof((s1->Value).c_str());
        float b=atof((s3->Value).c_str());
        if(s2->Name=="<") value= a<b;
	else if(s2->Name=="<=") value= (a<=b);
	else if(s2->Name==">") value= (a>b);
	else if(s2->Name==">=") value= (a>=b);
	else if(s2->Name=="==") value= (a==b); 
        else if(s2->Name=="!=") value= (a!=b);


        ans->code= s1->code+s3->code;
        ans->code+="mov ax, " + s1->symbol+"\n";
	ans->code+="cmp ax, " + s3->symbol+"\n";
	char *temp=newTemp();
	char *label1=newLabel();
	char *label2=newLabel();
	if(s2->Name=="<"){
		ans->code+="jl " + string(label1)+"\n";
	}
	else if(s2->Name=="<="){
		ans->code+="jle " + string(label1)+"\n";		
        } 
	else if(s2->Name==">"){
		ans->code+="jg " + string(label1)+"\n";
	}
	else if(s2->Name==">="){
		ans->code+="jge " + string(label1)+"\n";
	}
	else if(s2->Name=="=="){
		ans->code+="je " + string(label1)+"\n";
	}
	else{
		ans->code+="jne " + string(label1)+"\n";	
	}
				
	ans->code+="mov "+string(temp) +", 0\n";
	ans->code+="jmp "+string(label2) +"\n";
        ans->code+=string(label1)+":\nmov "+string(temp)+", 1\n";
	ans->code+=string(label2)+":\n";
	ans->symbol=temp;
        ans->Value=tostr(value); 
	return ans;

}


SymbolInfo* handleUnaryAddNot(SymbolInfo* s1,SymbolInfo* s2){
            SymbolInfo* ans;
            if(s1->isFunction){
            	if(s1->function->returnType== "void") {
			yyerror(s1->Name+" function return type is void");
                	return s1;
           	 }
		
       	    }
            
        
            if(s1->DataType== "int"){
                   int value= atoi(s1->Value.c_str());
                   int ans;
                   if(s2->Name=="+")   ans= (+value);
                   else if(s2->Name=="-")   ans= (-value);
                   else if(s2->Name=="!")   ans= (!value);
                   s1->Value=tostr(ans);

            }
            else if(s1->DataType== "float"){
                   float value= atof(s1->Value.c_str());
                   float ans;
                   if(s2->Name=="+")   ans= (+value);
                   else if(s2->Name=="-")   ans= (-value);
                   else if(s2->Name=="!")   ans= (!value);
                   s1->Value=tostr(ans);

            }
           else if(s1->DataType== "double"){
                   double value=:: atof(s1->Value.c_str());
                   double ans;
                   if(s2->Name=="+")   ans= (+value);
                   else if(s2->Name=="-")   ans= (-value);
                   else if(s2->Name=="!")   ans= (!value);
                   s1->Value=tostr(ans);

            }
           char *temp=newTemp();
           ans=new SymbolInfo(s1); 
           ans->symbol=string(temp);

	   if(s2->Name == "-") {
	        ans->code+= "mov ax, " + s1->symbol + "\n";
		ans->code+=  "neg ax\n";
		ans->code+=  "mov " + ans->symbol + ", ax\n";	
           }
           else if(s2->Name=="!"){
                  

		char *label1=newLabel();
                char *label2=newLabel();
                ans->code+="mov ax, " + s1->symbol + "\n";
		ans->code+="cmp ax, 0\n";
		ans->code+="je " + string(label1) + "\nmov " + string(temp) +", 0\njmp " + string(label2)+"\n";
                ans->code+=string(label1)+":\nmov "+string(temp) + "1\n" + string(label2)+ ":\n";
           }
           
           return ans;


}

SymbolInfo* handleLogiclOp(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3){
	SymbolInfo* ans= new SymbolInfo();
	ans->DataType="int";
        if(s1->isFunction){
            if(s1->function->returnType== "void") {
		yyerror(s1->Name+" function return type is void");
                return s3;
            }
		
        }
        else if(s3->isFunction){
            if(s3->function->returnType== "void") {
		yyerror(s3->Name+" function return type is void");
                return s1;
            }
		
        }
        
        int value;
        float a=atof((s1->Value).c_str());
        float b=atof((s3->Value).c_str());
        char* temp=newTemp();
        ans->code= s1->code+ s3->code;  
        if(s2->Name=="&&") {
		value= a&&b;
                ans->code+="mov ax, "+s1->symbol+"\n";
                ans->code+="and ax, "+s3->symbol+"\n";
                ans->code+="mov "+string(temp)+", ax\n";
        }
       
	else if(s2->Name=="||"){
		 value= (a||b);
                 ans->code+="mov ax, "+s1->symbol+"\n";
                 ans->code+="or ax, "+s3->symbol+"\n";
                 ans->code+="mov "+string(temp)+", ax\n";
	}
        ans->symbol=temp;	
        ans->Value=tostr(value); 
	return ans;

}
SymbolInfo* handleAddOp(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3){
	SymbolInfo* ans= new SymbolInfo();
        //if(s1->Type== "ID") s1=table->LookUp(s1->Name);
        //if(s3->Type== "ID") s3=table->LookUp(s1->Name);
        if(s1->isFunction){
            if(s1->function->returnType== "void") {
		yyerror(s1->Name+" function return type is void");
                return s3;
            }
		
        }
        else if(s3->isFunction){
            if(s3->function->returnType== "void") {
		yyerror(s3->Name+" function return type is void");
                return s1;
            }
		
        }
        
	if(s1->DataType== "int" && s3->DataType== "int"){
             cout<<"doing int add int"<<endl;
             int one=atoi((s1->Value).c_str());
             int two=atoi((s3->Value).c_str()); 
             int answer;
             if(s2->Name== "+"){
 		answer= one +two;
             }
             else if(s2->Name== "-"){
 		answer= one- two;
             }
             
             ans->Value=tostr(answer);
             ans->DataType="int";


        } 
        else if(s1->DataType== "double" || s3->DataType== "double"){
            double one=::atof((s1->Value).c_str());
            double two=::atof((s3->Value).c_str()); 
            double answer;
	    cout<<"doing float into float"<<endl;
            if(s2->Name== "+"){
 		answer= one+ two;
            }
            else if(s2->Name== "-"){
 		answer= one- two;
            }
             
            ans->Value=tostr(answer);
            ans->DataType="double";
        }
        else {
            float one=atof((s1->Value).c_str());
            float two=atof((s3->Value).c_str()); 
            float answer;
	    cout<<"doing float into float"<<endl;
            cout<<s1->Name<<" "<<s1->DataType<<" data types "<<s1->Name<<" "<<s3->DataType<<endl;
            if(s2->Name== "+"){
 		answer= one+ two;
            }
            else if(s2->Name== "-"){
 		answer= one- two;
            }
             
            ans->Value=tostr(answer);
            ans->DataType="float";


        }

        char* temp = newTemp();
        ans->code=s1->code+s3->code;
        if(s2->Name=="+"){
	     ans->code+="mov ax, "+s1->symbol+"\n";
             ans->code+= "add ax, "+s3->symbol+"\n";
             ans->code+= "mov "+string(temp)+", ax\n";	
        }
        if(s2->Name=="-"){
	     ans->code+="mov ax, "+s1->symbol+"\n";
             ans->code+= "sub ax, "+s3->symbol+"\n";
             ans->code+= "mov "+string(temp)+", ax\n";	
        }        
        ans->symbol=temp;
        cout<<ans->Value<<"Valueeee mul!!!!!!!!!!!!!"<<endl;
        return ans;

}
SymbolInfo* getSymbolInfo(SymbolInfo* s1){
         SymbolInfo* s= table->LookUp(s1->Name);
      
         if(s==NULL) {
		yyerror("Undeclared Variable "+ s1->Name);
               // errorcount++;
		return s1;
               
         }
         if(s->isArray== true){
		yyerror("No index on array "+ s1->Name);
               // errorcount++;
		return s1;


         }
         delete s1;
         s->code="";
         return s;


}

SymbolInfo* getArrayIndex(SymbolInfo* s1,SymbolInfo* s2){
	SymbolInfo* s= table->LookUp(s1->Name);
        string indexType= s2->DataType;
        
        if(s==NULL) {
		yyerror("Undeclared Variable "+ s1->Name);
                //errorcount++;
		return s1;
               
         }
        if(s->isArray== false){
		yyerror("Index on non-array "+ s1->Name);
               // errorcount++;
		return s1;
        }
        if(indexType != "int") {
	       yyerror("Index should be integer "+ s1->Name);
               // errorcount++;
		return s1;

        }
        else{
                int curr=atoi((s2->Value).c_str());
                if(curr >= s->noOfElements || curr<0){
                     yyerror("Array index out of bound "+ s1->Name);
                    // errorcount++;
		     return s1;

                } 
                SymbolInfo* now=s->getArrayElement(curr);
                cout<<"Array Value "<<now->Value<<" "<<curr<<endl;
                now->symbol=s->symbol; 
                return    now;
                
        }


}
SymbolInfo* checkFunctionCall(SymbolInfo* s1){
      
      SymbolInfo* s= table->LookUp(s1->Name);
      SymbolInfo* ans= new SymbolInfo();
      if(s== NULL) {
            //cout<<"Undeclared Function "<<s1->Name<<endl<<endl;
            yyerror("Undeclared Function "+s1->Name);
           // errorcount++;
            argument_list.clear();
            return ans;
      }
      //ans= new SymbolInfo(s);
      if(s->isFunction== false){
            yyerror(s->Name+ " is not a function");
	   // errorcount++;
	    argument_list.clear();
            return ans;
      }
      else{
           Function* defined= s->function;
           cout<<"NUMBER OF PARAMETER "<<defined->numberOfParameters<<"  SIZE "<<argument_list.size()<<endl;
           if(defined->numberOfParameters != argument_list.size()){
		yyerror("Total Number of Arguments mismatch in funtion "+s1->Name);
            	//errorcount++;
	        argument_list.clear();
            	return ans;
           }
           else{
                cout<<"$$$$$$$$$$$$$$$ checking argument $$$$$$$$$$$$$"<<endl;
                for(int i=0;i<argument_list.size();i++){
                        cout<<"< "<<argument_list[i]->DataType<<"    "<< defined->parameterType[i]<<"> "<<endl;
			if(argument_list[i]->DataType != defined->parameterType[i]){
                             yyerror(tostr(i+1)+"th argument mismatch in function  "+s1->Name);
            	             //errorcount++;
 			     argument_list.clear();
            		     return ans;
                        }
                }

           }
           ans->DataType="int";
           ans->Value="0";
           for(int i=0;i<argument_list.size();i++){
		ans->code+=argument_list[i]->code;
           }
           if(s->Name == workingFunction->Name){
        	cout<<"same name hoise!!!!"<<endl;
	       int number=workingFunction->function->numberOfParameters;
               for(int i=0;i<number;i++){
		//SymbolInfo* sym=table->LookUp(function->typeId[i].second);
                
                
                	ans->code+="PUSH "+workingFunction->function->symbols[i]+"\n";

                }

           }
           for(int i=0;i<argument_list.size();i++){
		ans->code+="PUSH "+argument_list[i]->symbol+"\n";
           }
           

           
           ans->code+="CALL "+s->Name+"\n";
           if(s->Name == workingFunction->Name){
        	cout<<"same name hoise!!!!"<<endl;
	       int number=workingFunction->function->numberOfParameters;
               for(int i=number-1;i>=0;i--){
		//SymbolInfo* sym=table->LookUp(function->typeId[i].second);
                
                
                	ans->code+="POP "+workingFunction->function->symbols[i]+"\n";

                }

           }
           ans->symbol=s->function->returned_asm_value;
	   argument_list.clear();
           return ans;
      }
      

}
SymbolInfo* generate_if(SymbolInfo* s1,SymbolInfo* s2){
        SymbolInfo* ans=new SymbolInfo();
        ans->code=s1->code;
	char *label=newLabel();
	ans->code+="mov ax, "+s1->symbol+"\n";
	ans->code+="cmp ax, 0\n";
	ans->code+="je "+string(label)+"\n";
	ans->code+=s2->code;
        cout<<"S2 er code ase naki dekha"<<endl<<s2->code<<endl;
	ans->code+=string(label)+":\n";
	//ans->symbol="if";
        cout<<ans->code<<"  If er full code likhsi!!!"<<endl;				
        return ans;
}
SymbolInfo* generate_if_else(SymbolInfo* s1,SymbolInfo* s2,SymbolInfo* s3){
        SymbolInfo* ans=new SymbolInfo();
        ans->code=s1->code;
	char *END=newLabel();
        char *ELSE=newLabel();
	ans->code+="mov ax, "+s1->symbol+"\n";
	ans->code+="cmp ax, 0\n";
	ans->code+="je "+string(ELSE)+"\n";
	ans->code+=s2->code;
        ans->code+= "jmp "+string(END)+"\n";
	ans->code+=string(ELSE)+":\n";
        ans->code+=s3->code;
        ans->code+=string(END)+":\n";
	ans->symbol="if_else";
        cout<<ans->code<<"  If else er full code likhsi!!!"<<endl;				
        return ans;

}
SymbolInfo* generate_for(SymbolInfo* s1,SymbolInfo* s2, SymbolInfo* s3, SymbolInfo* s4){
       SymbolInfo* ans=new SymbolInfo();
       ans->code=s1->code;
       char *FOR=newLabel();
       char *END=newLabel();
       ans->code+=string(FOR)+":\n";
       ans->code+=s2->code;
       ans->code+="cmp "+s2->symbol+ ", 0\n";
       ans->code+="je "+string(END)+ "\n";
       ans->code+=s3->code;
       ans->code+=s4->code;
       ans->code+="jmp "+string(FOR)+"\n";
       ans->code+=string(END)+":\n";
       ans->symbol="for";
       cout<<ans->code<<"  for full code likhsi!!!"<<endl;				
       return ans;


}

SymbolInfo* generate_while(SymbolInfo* s1,SymbolInfo* s2){
       SymbolInfo* ans=new SymbolInfo();
       
       char *WHILE=newLabel();
       char *END=newLabel();
       ans->code=string(WHILE)+":\n";
       ans->code+=s1->code;
       ans->code+="cmp "+s1->symbol+ ", 0\n";
       ans->code+="je "+string(END)+ "\n";
       ans->code+=s2->code;
       ans->code+="jmp "+string(WHILE)+"\n";
       ans->code+=string(END)+":\n";
       ans->symbol="while";
       cout<<ans->code<<"  while full code likhsi!!!"<<endl;				
       return ans;

}
SymbolInfo* gen_println(SymbolInfo* s1){

          SymbolInfo* ans = new SymbolInfo();
          SymbolInfo* s = table->LookUp(s1->Name);
          cout<<"println e asche\n";
          if(s== NULL){
		yyerror("undeclared variable "+s1->Name);
                return ans;
          }
          cout<<"null hoy nai\n";
	  string sym = s->symbol;
		
	  ans->code = "mov ax, " + sym + "\n";
	  ans->code += "CALL OUTDEC\n";
	  return ans;	
		
	

}

void checkReturn(){
	if(workingFunction->function->returnType != returned_type){
             yyerror( "return type does not match");
	   // errorcount++;   

        }
        cout<<"function is ending!!!!!!!!!!!!!!!"<<workingFunction->function->returnType<<"!!!!!!!!!!!!!!!!!!!!!!!!"<<returned_type<<endl;
       workingFunction=NULL;
       returned_type="void";
       cout<<"check function sesh"<<endl;
}
void printOutdec(){
     outdec="OUTDEC PROC\n";
     outdec+="PUSH AX\nPUSH BX\nPUSH CX\nPUSH DX\n";
     outdec+="OR AX, AX\nJGE @END_IF1\nPUSH AX\n";
     outdec+="mov DL, '-'\nmov AH, 2\nINT 21H\n";
     outdec+="POP AX\nNEG AX\n";
     outdec+="@END_IF1:\nXOR CX, CX\nmov BX, 10D\n";
     outdec+="@REPEAT1:\nXOR DX, DX\nDIV BX\nPUSH DX\nINC CX\nOR AX, AX\nJNE @REPEAT1\n";
     outdec+="mov AH, 2\n";
     outdec+="@PRINT_LOOP:\n\nPOP DX\nOR DL, 30H\nINT 21H\nLOOP @PRINT_LOOP\n";
     outdec+="POP DX\nPOP CX\nPOP BX\nPOP AX\nRET\nOUTDEC ENDP\n\n";

}

string get_command(string str)
{
	int i = 0;
	
	while(str[i] != ' ') i++;
	//printf("command %s\n",str.substr(0, i).c_str());
	return str.substr(0, i);
}
string get_des(string str)
{
	int i = 0;
	
	while(str[i] != ' ') i++;
	i++;
	int j = i + 1;
	
	while(str[j] != ',' && j<str.size()) j++;
	//printf("dest %s\n",str.substr(i, j-i).c_str());
        return str.substr(i, j-i);
}
string get_src(string str)
{	
	int len = str.size();
	int i = 0;
	while(str[i] != ',') i++;
        i += 2;
	//printf("command %s\n",str.substr(i, len-i).c_str());
	return str.substr(i, len-i);
}

void optimize(){
	freopen("normal_out.asm", "r", stdin);
	freopen("optimized_out.asm", "w", stdout);
        string input1="";
        string input2="";
        getline(cin, input1);
        cout<<input1<<endl;
        while(getline(cin, input2)){
		
                //printf("line %s\n",input1.c_str());
                string cmd1=get_command(input1);
		//cout<<cmd1<<endl;                 
		if(input1 == "END MAIN") {
			cout<<input1<<endl;
                        cout<<"end hoye gese!!!!"<<endl;
                        return;
                        break;

                }
                if(cmd1=="add" || cmd1=="sub"){
			if(get_src(input1)=="0"){
 				input1=input2;
				continue;                        
			}
                
                }
		if(cmd1=="mul" || cmd1=="div"){
			if(get_des(input1)=="1"){
				input1=input2;
				continue;                        
			}
                
                }
                //getline(cin, input2);
                string cmd2=get_command(input2) ;
               // cout<<cmd2<<" "<<cmd1<<endl;
                if(cmd1== "mov" && cmd2 == "mov")
		{      
			/*cout<<"###"<<endl; 
			cout<<input1<<endl;
                        cout<<input2<<endl;
                        cout<<"srcs "<<get_src(input1)<<" !!! "<<get_src(input2)<<endl;
			cout<<"desa "<<get_des(input2)<<" !!! "<<get_des(input1)<<endl;*/
			if(get_src(input1) == get_des(input2) && get_src(input2) == get_des(input1))
			{
				
                               // cout<<"vitore Dhukse !!!!"<<endl;
				//cout << input1 << endl;
				//input1=input2;
				continue;
			}
		}
                //cout << input1 << endl;
		cout << input2 << endl;
		input1=input2;

        }

}

%}

%token CONST_INT CONST_FLOAT CONST_CHAR ID INCOP MULOP ADDOP RELOP LOGICOP ASSIGNOP LPAREN RPAREN RTHIRD LTHIRD LCURL RCURL COMMA SEMICOLON NOT DECOP IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE  STRING MAIN PRINTLN COMMENT

%error-verbose

%nonassoc NOELSE
%nonassoc ELSE


%%

start : program              {asm_file= fopen("normal_out.asm","w");
                               if(errorcount<1){
                              
                              start_code=".MODEL SMALL\n\n.STACK 100H\n\n.DATA\n\n";
                              fprintf(asm_file,"%s",(start_code).c_str());
                              fprintf(asm_file,"%s\n\n.CODE\n\n",(variable_declare).c_str());
                              fprintf(asm_file,"%s\n",($1->code).c_str());
                               fprintf(logout,"Line %d: start : program \n\n",linecount);
                               cout<<"declare "<<variable_declare<<endl;
                               printOutdec();
                               fprintf(asm_file,"%s\n\nEND MAIN\n",(outdec).c_str());
                               fclose(asm_file);}}
      ;                

program : program unit         {fprintf(logout,"Line %d: program : program unit\n\n",linecount);$$=new SymbolInfo($1);
                               $$->code+=$2->code;delete $1;delete $2;
                               printf("Line %d: program : program unit\n\n",linecount);
                               cout<<$$->code<<endl;}
	| unit                 {fprintf(logout,"Line %d: program : unit\n\n",linecount);$$=new SymbolInfo($1);
                               delete $1;}
	;
	
unit : var_declaration        {fprintf(logout,"Line %d: unit : var_declaration\n\n",linecount);$$=new SymbolInfo($1);
                              delete $1;}
     | func_declaration       {fprintf(logout,"Line %d: unit : func_declaration\n\n",linecount);$$=new SymbolInfo($1);
                              delete $1;}
     | func_definition        {fprintf(logout,"Line %d: unit : func_definition\n\n",linecount);$$=new SymbolInfo($1);
                              delete $1;}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON    
                          {fprintf(logout,"Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n%s\n\n",linecount,($2->Name).c_str());
			   insertFunctionDeclare($2,$1);parameterList.clear();
                           }
		 ;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
                         insertFunctionDefine($2,$1);/*table->EnterScope();scopeCreated=true;*/} compound_statement  
			{checkReturn();fprintf(logout,"Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n%s\n\n",linecount,($2->Name).c_str());
                        printf("Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n%s\n\n",linecount,($2->Name).c_str());
                        $$=gen_for_function($2,$7);
                        }
 		 ;

parameter_list: parameters     {fprintf(logout,"parameter_list: parameters\n\n"); }
              |
              ;
 		 
parameters  : parameters COMMA type_specifier ID   
			   {fprintf(logout,"Line %d: parameters  :parameters COMMA type_specifier ID\n%s\n\n",linecount,($4->Name).c_str());
			   parameterList.push_back(pii(variable_type,$4->Name));
                           }
		| parameters COMMA type_specifier	   
			   {fprintf(logout,"Line %d: parameters  :parameters COMMA type_specifier\n\n",linecount);
			   parameterList.push_back(pii(variable_type,""));
                           }
 		| type_specifier ID                        
			   {fprintf(logout,"Line %d: parameters  :type_specifier ID\n%s\n\n",linecount,($2->Name).c_str());
			   parameterList.push_back(pii(variable_type,$2->Name));
                           }
 		| type_specifier                           
                           {fprintf(logout,"Line %d: parameters  :type_specifier\n\n",linecount); 
                             parameterList.push_back(pii(variable_type,""));
                             }
 		;
 		
compound_statement : LCURL{curly_brace++;table->EnterScope();
                           if(curly_brace==1){insertParameter();}} statements RCURL
               {fprintf(logout,"Line %d: compound_statement : LCURL statements RCURL\n\n",linecount);
                printf("Line %d: compound_statement : LCURL statements RCURL\n\n",linecount);
                 $$=new SymbolInfo($3);
                cout<<$$->code<<endl;
                //$$->symbol=$2->symbol;
                //$$->code=$2->code;
		curly_brace--;
                table->PrintAllTable();
                fprintf(print_symbol,"Line %d:\n\n",linecount);                
                table->PrintAllTableforSymtab();
                table->ExitScope();cout<<"EKAHNEEEEE$###########################"<<endl;
                delete $3;}
 		    | LCURL{curly_brace++;table->EnterScope();
                           if(curly_brace==1){insertParameter();}}  RCURL                          
                           {fprintf(logout,"Line %d: compound_statement : LCURL  RCURL\n\n",linecount);
			   curly_brace--;
                	   table->PrintAllTable();
                           fprintf(print_symbol,"Line %d:\n\n",linecount);                
                           table->PrintAllTableforSymtab();
                           table->ExitScope();cout<<"EKAHNEEEEE$###########################"<<endl;}
                  
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON  {fprintf(logout,"Line %d: var_declaration : type_specifier declaration_list SEMICOLON \n\n",linecount);}
                 |type_specifier error SEMICOLON
                 |error declaration_list SEMICOLON
 		 ;
 		 
type_specifier	: INT                            {fprintf(logout,"Line %d: type_specifier : INT\n\n",linecount);
                                                 variable_type="int";$1->Type="int";$$=$1;function_return_type="int";}
 		| FLOAT                          {fprintf(logout,"Line %d: type_specifier : FLOAT\n\n",linecount);
						 variable_type="float";$$=$1;function_return_type="float";}
 		| VOID                           {fprintf(logout,"Line %d: type_specifier : VOID\n\n",linecount);
                                                 $$=$1;function_return_type="void";variable_type="void";}
 		;
 		
declaration_list : declaration_list COMMA ID        {
                       fprintf(logout,"Line %d: declaration_list : declaration_list COMMA ID\n%s\n\n",linecount,($3->Name).c_str());
                       insertVariable($3);}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD   {
                   fprintf(logout,"Line %d: declaration_list : declaration_list COMMA ID  LTHIRD CONST_INT RTHIRD\n%s\n%s\n\n",linecount,($3->Name).c_str(),($5->Value).c_str());
		   insertArray($3,$5);}

 		  | ID     {fprintf(logout,"Line %d: declaration_list : ID\n%s\n\n",linecount,($1->Name).c_str());
                            insertVariable($1);}
 		  | ID LTHIRD CONST_INT RTHIRD     {
                               fprintf(logout,"Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n%s\n%s\n\n",linecount,($1->Name).c_str(),($3->Value).c_str());
                                insertArray($1,$3);}
 		  ;
 		  
statements : statement                  {fprintf(logout,"Line %d: statements : statement\n\n",linecount);
                                        $$=new SymbolInfo($1);
                                        cout<<$$->code<<endl;
                                        printf("Line %d: statements :  statement\n\n",linecount);delete $1;}
	   | statements statement      {fprintf(logout,"Line %d: statements : statements statement\n\n",linecount);
                                       cout<<$1->code<<"  2 no !!!"<<$2->code<<"2 no sesh "<<endl;
                                       $$=new SymbolInfo($1);$$->code+=$2->code;cout<<$$->code<<endl;
                                    printf("Line %d: statements : statements statement\n\n",linecount);}
           

	   ;
	   
statement : var_declaration              {fprintf(logout,"Line %d: statement : var_declaration\n\n",linecount);
                                         $$=new SymbolInfo($1);cout<<$$->code<<endl;delete $1;}

	  | expression_statement         {fprintf(logout,"Line %d: statement : expression_statement\n\n",linecount);
                                   printf("Line %d: statement : expression_statement\n\n",linecount);
                                          $$=new SymbolInfo($1);cout<<$$->code<<endl;delete $1;
                              printf("Line %d: statement : expression_statement\n\n",linecount);}

	  | {notFunction=true;}compound_statement          {fprintf(logout,"Line %d: statement: compound_statement\n\n",linecount);
                                               $$=new SymbolInfo($2); 
                                              printf("Line %d: statement: compound_statement\n\n",linecount);
                                              cout<<$$->code<<endl; 
                                              printf("Line %d: statement: compound_statement\n\n",linecount);delete $2;}

	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement      
                               {fprintf(logout,"Line %d: statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",linecount);$$=generate_for($3,$4,$5,$7);
                              printf("Line %d: statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",linecount);delete $3;delete $4;delete $5;delete $7; }



	  | IF LPAREN expression RPAREN statement      %prec NOELSE     {fprintf(logout,"Line %d: statement: IF LPAREN expression RPAREN statement\n\n",linecount);$$=generate_if($3,$5);
          printf("Line %d: statement: IF LPAREN expression RPAREN statement\n\n",linecount);delete $3;delete $5;}

          | IF LPAREN error RPAREN statement      %prec NOELSE



	  | IF LPAREN expression RPAREN statement ELSE statement          {fprintf(logout,"Line %d: statement:IF LPAREN expression RPAREN statement ELSE statement\n\n",linecount);
                      printf("Line %d: statement:IF LPAREN expression RPAREN statement ELSE statement\n\n",linecount);
                      $$=generate_if_else($3,$5,$7);delete $3;delete $5;delete $7;}


          | IF LPAREN error RPAREN statement ELSE statement 


          
	  | WHILE LPAREN expression RPAREN statement            {fprintf(logout,"Line %d: statement: WHILE LPAREN expression RPAREN statement \n\n",linecount);$$=generate_while($3,$5);delete $3;delete $5;}

          | WHILE LPAREN error RPAREN statement



	  | PRINTLN LPAREN ID RPAREN SEMICOLON                  {fprintf(logout,"Line %d: statement: PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",linecount);$$=gen_println($3);}

	  | RETURN expression SEMICOLON  {notFunction=false;}                        {fprintf(logout,"Line %d: statement : RETURN expression SEMICOLON\n\n",linecount);cout<<workingFunction->Name<<"is working !!!!"<<workingFunction->function->returnType<<"  got!!! "<<$2->DataType<<endl;returned_type=$2->DataType;$$=new SymbolInfo($2);
          $$->code+="mov ax, "+$2->symbol+"\n";
          $$->code+="mov "+workingFunction->function->returned_asm_value+", ax\n";
          printf("Line %d: statement : RETURN expression SEMICOLON\n\n",linecount);delete $2;
          }
          | RETURN error SEMICOLON 
	  ;
	  
expression_statement 	: SEMICOLON			{fprintf(logout,"Line %d: expression_statement 	: SEMICOLON\n\n",linecount);}
			| expression SEMICOLON          {fprintf(logout,"Line %d: expression_statement 	: expression SEMICOLON\n\n",linecount);$$=new SymbolInfo($1); cout<<"express statement e hocche na  value!!!!!"<<$$->code<<endl;
                         printf("Line %d: expression_statement 	: expression SEMICOLON\n\n",linecount);
			delete $1;}
                        |error SEMICOLON                
                                    
			;
	  
variable : ID 		                                {fprintf(logout,"Line %d: variable: ID\n%s\n\n",linecount,($1->Name).c_str());
                                                         
                                                        $$=getSymbolInfo($1);cout<<$$->code<<endl;
                                                        printf("Line %d: variable: ID\n%s\n\n",linecount,($1->Name).c_str());}
	 | ID LTHIRD expression RTHIRD            {
                                                  fprintf(logout,"Line %d: variable:ID LTHIRD expression RTHIRD\n%s\n\n",linecount,($1->Name).c_str()); 
						   $$=getArrayIndex($1,$3);
                                                  $$->code=$3->code+"mov bx, " +$3->symbol +"\nadd bx, bx\n";
                                                  //$$->symbol=$1->symbol;
                                                  cout<<$$->code<<endl;
                                   printf("Line %d: variable:ID LTHIRD expression RTHIRD\n%s\n\n",linecount,($1->Name).c_str()); }
         | ID LTHIRD error RTHIRD 
	 ;
	 
 expression : logic_expression	                        {fprintf(logout,"Line %d: expression : logic_expression\n\n",linecount);
					                $$=new SymbolInfo($1);cout<<"express op value!!!!!"<<$$->Value<<endl;}
	   | variable ASSIGNOP logic_expression 	{fprintf(logout,"Line %d: expression : variable ASSIGNOP logic_expression\n\n",linecount);assignVariable($1,$3);table->PrintAllTable();cout<<"re op value!!!!!"<<$3->Value<<endl;
                                                        $$=new SymbolInfo($1);
				                        $$->code=$3->code+$1->code;
				                        $$->code+="mov ax, "+$3->symbol+"\n";
				                        if($$->isArray==false){ 
                                                                
								$$->code+= "mov "+$1->symbol+", ax\n";
							}
				
							else{
							       $$->code+= "mov  "+$1->symbol+"[bx], ax\n";
							}
							
                                                        cout<<$$->code<<endl;
							printf("Line %d: expression : variable ASSIGNOP logic_expression\n\n",linecount);delete $3;}
	   ;
			
logic_expression : rel_expression 	                 {fprintf(logout,"Line %d: logic_expression : rel_expression\n\n",linecount);
							$$=new SymbolInfo($1);cout<<"rel_express  value!!!!!"<<$$->code<<endl;
                    printf("Line %d: logic_expression : rel_expression\n\n",linecount);delete $1;}
		 | rel_expression LOGICOP rel_expression {fprintf(logout,"Line %d: logic_expression : rel_expression LOGICOP rel_expression\n\n",linecount);
                                                         $$=handleLogiclOp($1,$2,$3); cout<<"logic op value!!!!!"<<$$->code<<endl;
                           printf("Line %d: logic_expression : rel_expression LOGICOP rel_expression\n\n",linecount);
							delete $1;delete $3;}	
		 ;
			
rel_expression	: simple_expression                         {fprintf(logout,"Line %d: rel_expression: simple_expression\n\n",linecount);
                                                            $$=new SymbolInfo($1); cout<<$$->code<<endl;
                   printf("Line %d: rel_expression: simple_expression\n\n",linecount);delete $1;}
		| simple_expression RELOP simple_expression {fprintf(logout,"Line %d: rel_expression: simple_expression RELOP simple_expression\n\n",linecount);
                                                             $$=handleRelOp($1,$2,$3);cout<<"re op value!!!!!"<<$$->code<<endl;printf("Line %d: rel_expression: simple_expression RELOP simple_expression\n\n",linecount);
							delete $1;delete $3;}	
		;
				
simple_expression : term                                    {fprintf(logout,"Line %d: simple_expression : term\n\n",linecount);
							    $$=new SymbolInfo($1);cout<<$$->code<<endl;delete $1;}
		  | simple_expression ADDOP term            {fprintf(logout,"Line %d: simple_expression : simple_expression ADDOP term\n\n",linecount);$$=handleAddOp($1,$2,$3);cout<<"add op value!!!!!"<<$$->code<<endl;
printf("Line %d: simple_expression : simple_expression ADDOP term\n\n",linecount);delete $1;delete $3;}
		  ;
					
term :	unary_expression                                    {fprintf(logout,"Line %d: term :unary_expression\n\n",linecount);
							    printf("Line %d: term :unary_expression\n\n",linecount);
							    $$=new SymbolInfo($1);cout<<$$->code<<endl;delete $1;}
     |  term MULOP unary_expression                    {fprintf(logout,"Line %d: term :term MULOP unary_expression\n\n",linecount);
                                                      printf("Line %d: term :term MULOP unary_expression\n\n",linecount);
                                                      $$=handleMulOp($1,$2,$3); cout<<"mul op value!!!!!"<<$$->code<<endl;
                                                      delete $1;delete $3;}
     ;

unary_expression : ADDOP unary_expression                    {fprintf(logout,"Line %d: unary_expression : ADDOP unary_expression \n\n",linecount);
printf("Line %d: unary_expression : ADDOP unary_expression \n\n",linecount);
$$=handleUnaryAddNot($2,$1);cout<<$$->code<<endl;}
		 | NOT unary_expression                      {fprintf(logout,"Line %d: unary_expression : NOT unary_expression \n\n",linecount);
printf("Line %d: unary_expression : NOT unary_expression \n\n",linecount);
$$=handleUnaryAddNot($2,$1);cout<<$$->code<<endl;}
		 | factor                                     {fprintf(logout,"Line %d: unary_expression : factor\n\n",linecount);
							      $$=new SymbolInfo($1);cout<<"express value!!!!!"<<$$->code<<endl;}
		 ;
	
factor	: variable                  {fprintf(logout,"Line %d: factor: variable\n\n",linecount);
                                    printf("Line %d: factor: variable\n\n",linecount);
				    $$= $1;
			            if($$->isArray==false){
				    	cout<<"factor!!! array na"<<endl;
				    }
			            
			            else{
				         char *temp= newTemp();
				         $$->code+="mov ax, " + $1->symbol + "[bx]\n";
				         $$->code+= "mov " + string(temp) + ", ax\n";
				         $$->symbol=temp;
			            }
                                    cout<<"factor!!!"<<endl;
                                    cout<<$$->code<<endl;

}
	| ID LPAREN argument_list RPAREN                    {fprintf(logout,"Line %d: factor: ID LPAREN argument_list RPAREN\n\n",linecount);
                                                             $$=checkFunctionCall($1);}
	| LPAREN expression RPAREN                          {fprintf(logout,"Line %d: factor:LPAREN expression RPAREN\n\n",linecount);$$=$2;
                        printf("Line %d: factor:LPAREN expression RPAREN\n\n",linecount);}
	| CONST_INT                              {fprintf(logout,"Line %d: factor: CONST_INT\n%s\n\n",linecount,($1->Value).c_str());
					         $$=$1;}
	| CONST_FLOAT                           {
						fprintf(logout,"Line %d: factor: CONST_FLOAT\n%s\n\n",linecount,($1->Value).c_str());
						$$=$1;}
	
	| variable INCOP                                    {fprintf(logout,"Line %d: factor: variable INCOP\n\n",linecount);
                                                             printf("Line %d: factor: variable INCOP\n\n",linecount);
						            $$= variableInc($1,$2);}
	| variable DECOP                                    {fprintf(logout,"Line %d: factor: variable DECOP\n\n",linecount);
                                                            printf("Line %d: factor: variable DECOP\n\n",linecount);
							    $$= variableInc($1,$2);}
	;


argument_list : arguments                         {fprintf(logout,"Line %d: argument_list : arguments \n\n",linecount);}
              |
              ;
	
arguments : arguments COMMA logic_expression       {fprintf(logout,"Line %d: arguments : arguments COMMA logic_expression\n\n",linecount);argument_list.push_back($3);}
	      | logic_expression                           {fprintf(logout,"Line %d: arguments : logic_expression\n\n",linecount);$$=$1;argument_list.push_back($1);}
	      ;


%%

int main(int argc,char *argv[]){
   
    if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
        table = new SymbolTable(10);
        
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("log.txt","w");
	errorFile= fopen("error.txt","w");
        print_symbol= fopen("symtab.txt","w");

	yyin= fin;
	yyparse();
        //table->printAllTable();
        fprintf(logout,"Total Lines: %d\n\n",yylineno);
        fprintf(logout,"Total Errors: %d\n\n",errorcount);



        
	fclose(yyin);
	fclose(logout);
        optimize();
	return 0;

}
