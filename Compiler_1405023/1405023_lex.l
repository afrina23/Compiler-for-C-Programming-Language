%option yylineno
%x MultiLineComment1
%x MultiLineComment2
%x MultiLineString
%{
#define YYSTYPE SymbolInfo*
#include<bits/stdc++.h>
#include<iostream>
#include<cstdlib>
#include<string>

#include "1405023_SymbolTable.h"
#include "y.tab.h"


using namespace std;

extern YYSTYPE yylval;
extern FILE *logout;
extern FILE *errorFile;

void yyerror(char *);

int linecount=1;

int errorcount=0;
//SymbolTable symbol(6);
char* str;
char* comment;
int first;
string toPrint;
void yyerror(char *);
void replace( string &s, const string &search,const string &replace ) {
    for( size_t pos = 0; ; pos += replace.length() ) {
        pos = s.find( search, pos );
        if( pos == string::npos ) break;
        // Replace by erasing and inserting
        s.erase( pos, search.length() );
        s.insert( pos, replace );
    }
}
void lexError(string msg,string err){
        string str=msg+err;
       cout << "ERROR at Line " << linecount << " : " << str << endl << endl << endl;
        fprintf(logout,"ERROR at Line  %d : %s\n\n",linecount,str.c_str());
	fprintf(errorFile,"ERROR at Line  %d : %s\n\n",linecount,str.c_str());
        errorcount++;

}

%}
TooDecimalNumber {Digit}*([\.]{Digit}+)([\.]{Digit}*)+(E[+-]?{Digit}+)?
IllNumber       {Digit}*([\.]?{Digit}+)(E[+-]?{Digit}+)+([\.]?{Digit}*)+
   
NormalNumber   {Digit}*([\.]?{Digit}+)(E[+-]?{Digit}+)? 
Letter [a-zA-Z]
Character [ -~]{-}[']
SingleCharacter  [ -~]{-}[\\]
CommentChar [ -~]{-}[\\\n]
StringChar [ -~]{-}[\"\n\\]
CommentChars {CommentChar}+
Digit [0-9]
AlphaNumeric  [_a-zA-Z0-9] 


InvalidSuffix  {Digit}+{Letter}{AlphaNumeric}*
MultiChar      '{Character}+'
UnfinishedCharacter   ('{Character}*)|'\\'
EmptyCharacter     ''

Whitespace [ \t\v\f\r]
tin [tin]
NewLine [\n]
slashNewLine  [\\]{NewLine}
SingleComment "//"{CommentChars}$


MultiComment1Start "//"({CommentChar}|(\\[tvar"afb0]))*
MultiComment1Middle ({CommentChar}|(\\[tvar"afb0]))*
MultiComment1End   ({CommentChar}|(\\[tvar"afb0]))*

MultiComment2Start "/*"
MultiComment2Middle {CommentChars}
MultiComment2End   {CommentChar}*"*/"
UnfinishedComment ({MultiComment2Start}[^"*/"]*)

UnfinishedSingleString   \"[^\"\n\\]*$
SingleLineString  \"(["\""]|[^\"\n])*\"

MultiLineStringStart   (\"((\\[tvar"afb0])|{StringChar})*)
MultiLineStringMiddle   (((\\[tvar"afb0])|{StringChar})*)
MultiLineStringEnd     ((\\[tvar"afb0])|{StringChar})*[\"]
UnfinishedMultiString  ((\\[tvar"afb0])|{StringChar})*



%%
if                               {printf("i got from IF and the identifier is %s\n",yytext);
				  return IF;}

else                             {printf("i got from IF and the identifier is %s\n",yytext);
				  return ELSE;}
  
for                              {printf("i got from FOR and the identifier is %s\n",yytext);
				 return FOR;}

while                            {printf("i got from WHILE and the identifier is %s\n",yytext);
				 return WHILE;}


do                               {return DO;}

break                            { return BREAK;}


int                              {SymbolInfo *s= new SymbolInfo(); s->setType("int");
                                  yylval=(YYSTYPE)s;return INT;}

char                             {SymbolInfo *s= new SymbolInfo(); s->setType("char");
                                  yylval=(YYSTYPE)s; return CHAR;}

float                            {SymbolInfo *s= new SymbolInfo(); s->setType("float");
                                  yylval=(YYSTYPE)s; return FLOAT;}

double                           {SymbolInfo *s= new SymbolInfo(); s->setType("double");
                                  yylval=(YYSTYPE)s;return DOUBLE;}

void                             { return VOID;}

return                           { return RETURN;}

switch                           { return SWITCH;}


case                             { return CASE;}

default                          { return DEFAULT;}

continue                         { return CONTINUE;}

println                          {return PRINTLN;}


{TooDecimalNumber}               {lexError("Too many decimal number detected ",yytext);
			         SymbolInfo *s= new SymbolInfo(); s->setType("CONST_FLOAT"),s->setValue("-1e+007");
				 s->DataType="float";
                                  yylval=(YYSTYPE) s;
                                  return CONST_FLOAT;}

{IllNumber}                      {lexError("ILL number detected ",yytext);
			          SymbolInfo *s= new SymbolInfo(); s->setType("CONST_FLOAT"),s->setValue("-1e+007");
				  s->DataType="float";
                                  yylval=(YYSTYPE) s;
                                  return CONST_FLOAT;}

{InvalidSuffix}                  {lexError("Invalid suffix ",yytext);
			         SymbolInfo *s= new SymbolInfo(); s->setType("ID"),
                              //printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!%s-- %s ---%s\n",(s->Name).c_str(),(s->Type).c_str(),yytext);
                              yylval=(YYSTYPE)s; return ID;}


{Digit}+                         {printf("i got from CONST_INT %s\n",yytext);
                                  SymbolInfo *s= new SymbolInfo(); s->setType("CONST_INT"),s->setValue(yytext);
                                  s->DataType="int";s->symbol=yytext;
                                  yylval=(YYSTYPE)s;
                                  return CONST_INT;}

{NormalNumber}                   {printf("i got from CONST_FLOAT %s\n",yytext);
				 SymbolInfo *s= new SymbolInfo(); s->setType("CONST_FLOAT"),s->setValue(yytext);
				 s->DataType="float";s->symbol=yytext;
                                  yylval=(YYSTYPE) s;
                                  return CONST_FLOAT;}

{NewLine}                        {linecount++;printf("i got from   %d\n",linecount);}



{UnfinishedSingleString}         {lexError("Unfinished string ",yytext);
                                 SymbolInfo *s= new SymbolInfo(); s->setType("STRING"),s->setValue(toPrint);
                                              yylval=(YYSTYPE) s;  
                                              BEGIN INITIAL; return STRING;} 

{MultiLineStringStart}          {strcpy(str,yytext);
                                toPrint=yytext;
                                replace(toPrint ,"\\", "");
                                
                                
                                printf("%s  Starting Multiline String %s\n",str,yytext);
				first=linecount;
                                BEGIN MultiLineString;}

<MultiLineString>{MultiLineStringMiddle}     {strcat(str,yytext);toPrint+=yytext;
					      
					      printf("%s Middle in the MultilineString %s\n",yytext,str);}

<MultiLineString>{slashNewLine}                   {linecount++; printf("%s I go to new Line %s\n",yytext,str);
					      strcat(str,"\\\n");}



<MultiLineString>{MultiLineStringEnd}        {strcat(str,yytext);toPrint+=yytext;
					      printf("%s END in the MultilineString %s\n",str,yytext);
                                              //fprintf(logout," Line No. %d: Token <STRING> Lexeme %s\n\n",first,str);
                                              replace(toPrint ,"\\t", "\t"); 
                                 	      replace(toPrint ,"\\\\", "\\");replace(toPrint ,"\\\"", "\"");
                                              replace(toPrint ,"\\a", "\a");replace(toPrint ,"\\f", "\f");
                                              replace(toPrint ,"\\r", "\r");replace(toPrint ,"\\b", "\b");
                                              replace(toPrint ,"\\v", "\v");replace(toPrint ,"\\0", "");
                                              replace(toPrint ,"\\", "");
                                              
                                              SymbolInfo *s= new SymbolInfo(); s->setType("STRING"),s->setValue(toPrint);
                                              yylval=(YYSTYPE) s;  
                                              BEGIN INITIAL; return STRING;} 

<MultiLineString>.                           {printf("it is comming here\n");}



<MultiLineString>[\n]                        {printf("%s ERROR END in the MultilineString \n",yytext);
                                              
                                              strcat(str,yytext);linecount++;
					      lexError("Unfinished string ",str);
                                              SymbolInfo *s= new SymbolInfo(); s->setType("STRING"),s->setValue(toPrint);
                                              yylval=(YYSTYPE) s;  
                                              BEGIN INITIAL; return STRING;
                                              BEGIN INITIAL;}



{SingleLineString}               {printf("i got from  StRING  %s\n",yytext);
				 
                                 toPrint=yytext;replace(toPrint ,"\\t", "\t");
                                 replace(toPrint ,"\\\\", "\\");replace(toPrint ,"\\\"", "\"");
                                 replace(toPrint ,"\\a", "\a");replace(toPrint ,"\\f", "\f");
                                 replace(toPrint ,"\\r", "\r");replace(toPrint ,"\\b", "\b");
                                 replace(toPrint ,"\\v", "\v");replace(toPrint ,"\\0", "");
				 
                                 SymbolInfo *s= new SymbolInfo(); s->setType("STRING"),s->setValue(toPrint);
                                              yylval=(YYSTYPE) s; return STRING;}



{SingleComment}                 {printf("i got from  SingleComment  %s\n",yytext);} 

{MultiComment1Start}              {printf("this is a multiline comment %s\n",yytext);
                                  first=linecount;strcpy(comment,yytext);BEGIN MultiLineComment1;
                                  }
<MultiLineComment1>{MultiComment1Middle}   {printf("this is middle %s\n",yytext);strcat(comment,yytext);} 
<MultiLineComment1>[\\]{NewLine}             {linecount++; printf("new line \n");strcat(comment,"\n");}

<MultiLineComment1>{NewLine}              {printf("%s  state ending \n",yytext);linecount++;
                                          
                                          BEGIN INITIAL;}  




<MultiLineComment1>.                  {}
<MultiLineComment1>{Whitespace}+                    {}







{MultiComment2Start}              {printf("this is a multiline comment2 %s",yytext);
				  BEGIN MultiLineComment2;
                                  }


<MultiLineComment2>{MultiComment2End}    {strcat(comment,yytext);printf("%s  state ending ",yytext);
                                          BEGIN INITIAL;}  

<MultiLineComment2>{MultiComment2Middle}   {printf("this is middle %s",yytext);strcat(comment,yytext);} 
<MultiLineComment2>{NewLine}             {linecount++; printf("new line \n");strcat(comment,"\n");}
<MultiLineComment2><<EOF>>                 {printf("END of file and undefinied comment line no %d \n",linecount);
					    lexError("Unfinished comment ",comment);
					    
 
                                           BEGIN INITIAL;return 1 ;}
       
<MultiLineComment2>{Whitespace}+                    {}
<MultiLineComment2>.                  {}




 




{Whitespace}+                    {}

'\\0'                   {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
                        s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}

'\\n'                   {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
                        s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}

"\'\\t\'"                {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
                        s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}
'\\\\'                  {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
                        s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}
'\\\"'                  {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
                        s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}


'\\a'                   {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
			s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}

'\\f'                   {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo();s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
			s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}
'\\r'                   {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
			s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}

'\\b'                   {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
			s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}

'\\v'                   {printf("i got from CONST_CHAR %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);s->DataType="char";
			s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;}

{EmptyCharacter}        {printf("Empty Character\n");lexError("Empty Character ",yytext);
                        SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),
			s->DataType="ILL_char";
                        yylval=(YYSTYPE) s; return CONST_CHAR;}


[']{SingleCharacter}[']      { string ch= yytext;
                         //symbol.Insert(str.substr(1,1), "CHAR");
                         printf("i got from CONST_CHAR NORMAL %s \n",yytext);
			SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),s->setValue(yytext);
			s->DataType="char";s->symbol=yytext;
                        yylval=(YYSTYPE) s; return CONST_CHAR;} 

{UnfinishedCharacter}            {printf("Unfinished Character\n");lexError("Unfinished Character ",yytext);
                                 SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),
			         s->DataType="char";
                        	 yylval=(YYSTYPE) s; return CONST_CHAR;}

{MultiChar}                                  {printf("Multiple Character\n");lexError("Multiple Character ",yytext);
					     SymbolInfo *s= new SymbolInfo(); s->setType("CONST_CHAR"),
					     s->DataType="ILL_char";
                        		     yylval=(YYSTYPE) s; return CONST_CHAR;}


("++")                    {printf("i got from  INCOP  %s\n",yytext);
			   SymbolInfo *s= new SymbolInfo();s->setType("INCOP"),s->setName(yytext);
                          yylval=(YYSTYPE)s;
			   return INCOP;}

("--")                    {printf("i got from  DECOP  %s\n",yytext);
			   SymbolInfo *s= new SymbolInfo();s->setType("DECOP"),s->setName(yytext);
                          yylval=(YYSTYPE) s;
			   return DECOP;}

[+] |
[-]                       {printf("i got from  ADDOP  %s\n",yytext);
                           SymbolInfo *s= new SymbolInfo();s->setType("ADDOP"),s->setName(yytext);
                        yylval=(YYSTYPE) s; return ADDOP;}         

"\*"|"/"|"\%"                 {printf("i got from  MULOP  %s\n",yytext);
			      SymbolInfo *s= new SymbolInfo(); s->setType("MULOP"),s->setName(yytext);
                              yylval=(YYSTYPE) s; return MULOP;} 

"<"|"<="|">"|">="|"=="|"!="   {printf("i got from  RELOP  %s\n",yytext);
                              SymbolInfo *s= new SymbolInfo(); s->setType("RELOP"),s->setName(yytext);
                              yylval=(YYSTYPE) s; return RELOP;}
 
"="                           {printf("i got from  ASSIGNOP  %s\n",yytext);
                              return ASSIGNOP;}
 
"&&"|"\|\|"                   {printf("i got from  LOGICOP  %s\n",yytext);
                              SymbolInfo *s= new SymbolInfo(); s->setType("LOGICOP"),s->setName(yytext);
                              yylval=(YYSTYPE) s; return LOGICOP;} 

"!"                           {printf("i got from  NOTOP  %s\n",yytext);
                              SymbolInfo *s= new SymbolInfo(); s->setType("NOTOP"),s->setName(yytext);
                              yylval=(YYSTYPE) s;
                              return NOT;}

"("                           {printf("i got from  LPARER  %s\n",yytext);
                              return LPAREN;}
 
")"                           {printf("i got from  RPARER  %s\n",yytext);
                              return RPAREN;}

"\{"                          {printf("i got from  LCURL  %s\n",yytext);
                              return LCURL;}
"\}"                          {printf("i got from  RCURL  %s\n",yytext);
                              return RCURL;} 
 
"\["                          {printf("i got from  LTHIRD  %s\n",yytext);
                              return LTHIRD;} 

"\]"                          {printf("i got from  RTHIRD  %s\n",yytext);
                              return RTHIRD;}

,                             {printf("i got from  COMMA  %s\n",yytext);
                              return COMMA;}

;                             {printf("i got from  SEMICOLON  %s\n",yytext);
                              return SEMICOLON;}


[_a-zA-Z]{AlphaNumeric}*      {printf("i got from  IDENTIFIER  %s\n",yytext);
                              string name="";
                              
                              SymbolInfo *s= new SymbolInfo(); s->setType("ID"),s->Name=yytext;s->symbol=yytext;
                              //printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!%s-- %s ---%s\n",(s->Name).c_str(),(s->Type).c_str(),yytext);
                              yylval=(YYSTYPE)s; return ID;}

            
              

.                             {printf("i got from nothing %s\n",yytext);lexError("Unrecognized Character ",yytext);
			      SymbolInfo *s= new SymbolInfo(); s->setType("ILL_CHAR"),
			      s->DataType="ILL_char";
                              yylval=(YYSTYPE) s; return CONST_CHAR;}

%%

int yywrap(void)
{
	return 1;
}
/*
int main(int argc,char *argv[]){
    str= new char[100];
    comment= new char[1000];
   if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
        
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("log.txt","w");
	tokenout= fopen("token.txt","w");

	yyin= fin;
	yylex();
        symbol.PrintAllTable();
        fprintf(logout,"Total Lines: %d\nTotal Errors: %d\n",linecount-1,errorcount);
        
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;

}*/
