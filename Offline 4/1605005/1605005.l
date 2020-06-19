%option noyywrap

%{
#include<bits/stdc++.h>
#include"SymbolTable.h"
#include "y.tab.h"

using namespace std;

extern YYSTYPE yylval;
extern SymbolTable *table;
void yyerror(char *);

int line_count = 1;
extern int error_count;
extern FILE* errorout;

int lines;
char str[5000];
char* strptr;
char logstr[5000];
char* logptr;
%}

%x commenttype1
%x commenttype2
%x string1

WHITESPACE [ \t\f\r\v]+

%%

{WHITESPACE} //eat up

(\n) {line_count ++;}

"if" {	
	return IF;
	}

"else" { 
		return ELSE;	
	}

"for" { 
		return FOR;	
	}

"while" { 
		return WHILE;	
	}

"do" { 
		return DO;
	}
	
"break" { 
		return BREAK;	
	}	

"int" { 
	return INT;	
	}

"char" { 
		return CHAR;	
	}

"float" { 
		return FLOAT;	
	}

"double" { 
		return DOUBLE;	
	}

"void" { 
		return VOID;	
	}
	
"return" { 
		return RETURN;	
	}

"SWITCH" { 
		return SWITCH;
	}

"case" { 
 		return CASE;	
	}

"default" { 
		return DEFAULT;
	}

"continue" { 
		return CONTINUE;	
	}

"println" {
		return PRINTLN;
	}

[0-9]+ { 
		yylval.si = new SymbolInfo(yytext, "CONST_INT");
		return CONST_INT;
	}

[a-zA-Z_][a-zA-Z0-9_]* { 
		yylval.si = new SymbolInfo(yytext, "ID");
		return ID;
    }

([0-9]+"."[0-9]*|"."[0-9]+)((E|e)[-+]?[0-9]+)? |
[0-9]+(E|e)[-+]?[0-9]+ { 
		yylval.si = new SymbolInfo(yytext, "CONST_FLOAT");
		return CONST_FLOAT;
	}

([0-9]+"."[0-9]*|"."[0-9]+)"."("."|[0-9])*((E|e)[-+]?[0-9]+)? |
".""."+[0-9]("."|[0-9])*((E|e)[-+]?[0-9]+)?  {
				error_count++;
				fprintf(errorout, "\nError at line %d: Lexical error: Too many decimal points %s\n", line_count, yytext);		
	}

(([0-9]+"."[0-9]*|"."[0-9]+)|[0-9]+)(E|e)[-+]?([0-9]|(E|e)|".")* |
(E|e)[-+]?[0-9]+([0-9]|(E|e)|".")* {
		error_count++;
		fprintf(errorout, "\nError at line %d: Lexical error: Ill formed number %s\n", line_count, yytext);
	}

\'[^\n\t\'\"\\]\' {
		string s;
		s.push_back(yytext[1]); 
		yylval.si = new SymbolInfo(s, "CONST_CHAR");
		return CONST_CHAR;
	}

\'(\\)[^\n\t]\' { 
		char c = yytext[2];
		switch(c) 
		{
			case 'n': c = '\n'; break;
			case 't': c = '\t'; break;
			case 'a': c = '\a'; break;
			case 'v': c = '\v'; break;
			case 'f': c = '\f'; break;
			case 'r': c = '\r'; break;
			case 'b': c = '\b'; break;
			case '0': c = '\0'; break;
			default: break;	
		}
		string s;
		s.push_back(c);
		yylval.si = new SymbolInfo(s, "CONST_CHAR");
		return CONST_CHAR;	
	}

\'\' {
		error_count++;
		fprintf(errorout,"\nError at line no %d: Lexical error: Empty character constant error %s\n", line_count, yytext);	
    }


\'\\\' {
		error_count++;
		fprintf(errorout,"\nError at line no %d: Lexical error: Unterminated character %s\n", line_count, yytext);	
    } 

\'[^\n\t\'\"]*/[\n\t<<EOF>>] {
		error_count++;
		fprintf(errorout,"\nError at line no %d: Lexical error: Unterminated character %s\n", line_count, yytext);	
	}

\'[^\\\n\t\'\"][^\n\t\'\"]+\' |
\'\\[^\n\t][^\n\t\'\"]+\' |
\'\t\' {
		error_count++;
		fprintf(errorout,"\nError at line no %d: Lexical error: Multi character constant error %s\n", line_count, yytext);	
	}


[-+] { 
		yylval.si = new SymbolInfo(yytext, "ADDOP");
		return ADDOP;
	}

[*/%] { 
		yylval.si = new SymbolInfo(yytext, "MULOP");
		return MULOP;	
	}

"++" { 
		return INCOP;	
	}

"--" {
		return DECOP;
	}

"<"|"<="|">"|">="|"=="|"!=" { 
		yylval.si = new SymbolInfo(yytext, "RELOP");
		return RELOP;
	}

"=" { 
		return ASSIGNOP;
   }

"&&"|"||" { 
		yylval.si = new SymbolInfo(yytext, "LOGICOP");
		return LOGICOP;
	}

"&"|"|"|"^"|"<<"|">>"|"~" { 
		yylval.si = new SymbolInfo(yytext, "BITOP");
		return BITOP;
	}

"!"|"("|")"|"{"|"}"|"["|"]"|","|";" { 
		char c = yytext[0];
		switch(c)
		{
			case '!': return NOT;
			case '(': return LPAREN;
			case ')': return RPAREN;
			case '{': return LCURL;
			case '}': return RCURL;
			case '[': return LTHIRD;
			case ']': return RTHIRD;
			case ',': return COMMA;
			case ';': return SEMICOLON;
			default: cout<<"won't happen";
		}
		
	}

[0-9]+[a-zA-Z_][a-zA-Z0-9_]* {
				error_count++;
				fprintf(errorout, "\nError at line %d: Lexical error:  Invalid prefix on ID or invalid suffix on Number %s\n", line_count, yytext);
	}

\" { lines = 0; strptr = str; logptr = logstr; *logptr++ = '\"'; BEGIN(string1);}

<string1>[^\"\\\n]+ {
			char* yptr = yytext;
			while(*yptr)
				{ *strptr++ = *yptr; *logptr++ = *yptr++;}
		}

<string1>\\. {
		switch(yytext[1]) 
		{
			case 'n' : *strptr++ = '\n'; break;
			case 'a' : *strptr++ = '\a'; break;		
			case 'f' : *strptr++ = '\f'; break;
			case 'r' : *strptr++ = '\r'; break;
			case 't' : *strptr++ = '\t'; break;
			case 'b' : *strptr++ = '\b'; break;
			case 'v' : *strptr++ = '\v'; break;
			case '0' : *strptr++ = '\0'; break;
			default: *strptr++ = yytext[1]; break;
		}
		*logptr++ = yytext[0];
		*logptr++ = yytext[1];
	}

<string1>\\[\r]*\n { lines++; *logptr++ = yytext[0]; *logptr++ = yytext[1]; } 

<string1>\n {
		*strptr = '\0';
		*logptr = '\0';
		lines++;
		error_count++;
		//fprintf(errorout, "\nError at line no %d: Unterminated String %s\n",line_count, logstr);
		line_count += lines;
		BEGIN(INITIAL);
	}

<string1><<EOF>> {
		*strptr = '\0';
		*logptr = '\0';
		error_count++;
		//fprintf(errorout, "\nError at line no %d: Unterminated String %s\n",line_count, logstr);
		line_count += lines;
		BEGIN(INITIAL);
	}

<string1>\" {
		*strptr = '\0';
		*logptr++ = '\"';
		*logptr = '\0';
		//fprintf(errorout,"\nLine no %d: TOKEN <STRING> Lexeme %s found\n",line_count,logstr);
		line_count += lines;
		BEGIN(INITIAL);
	}


"/*" { lines = 0; logptr = logstr; *logptr++ = '/'; *logptr++ = '*'; BEGIN(commenttype1);}

<commenttype1>[^*\n]+ {
			char* yptr = yytext;
			while(*yptr)
				*logptr++ = *yptr++;
		 } 

<commenttype1>\n { lines++; *logptr++ = '\n';}

<commenttype1>"*"+[^*/\n] {
				char* yptr = yytext;
				while(*yptr)
				   *logptr++ = *yptr++;
			 } 

<commenttype1>"*/" {  
			*logptr++ = '*';
			*logptr++ = '/';
			*logptr = '\0'; 
			//fprintf(errorout, "\nLine no %d: Token <COMMENT> lexeme %s found\n", line_count, logstr);
			line_count += lines; 
			BEGIN(INITIAL);
		}

<commenttype1><<EOF>> { 
			error_count++;	
			*logptr = '\0';
			//fprintf(errorout, "\nError at line %d: Unterminated comment %s\n", line_count, logstr);
			line_count += lines;
			BEGIN(INITIAL);
		}
 
"//" { lines = 0; logptr = logstr; *logptr++ = '/'; *logptr++ = '/'; BEGIN(commenttype2);}

<commenttype2>[^\n\\]* {
				char* yptr = yytext;
				while(*yptr)
				   *logptr++ = *yptr++;
			 } 

<commenttype2>(\\)+(\r)*(\n) {
				lines++;
				char* yptr = yytext;
				while(*yptr)
				   *logptr++ = *yptr++; 
			}

<commenttype2>(\\)+ {
				char* yptr = yytext;
				while(*yptr)
				   *logptr++ = *yptr++;
			 } 

<commenttype2>\n {
			lines++;  
			*logptr = '\0'; 
			//fprintf(errorout, "\nLine no %d: Token <COMMENT> lexeme %s found\n", line_count, logstr);
			line_count += lines;
			BEGIN(INITIAL);
		} 

<commenttype2><<EOF>> {
			*logptr = '\0';
			//fprintf(errorout, "\nLine no %d: Token <COMMENT> lexeme %s found\n", line_count, logstr);
			line_count += lines;
			BEGIN(INITIAL);
		}

. { error_count++; fprintf(errorout,"\nError at Line no %d: Lexical error: Unrecognized character %s found\n",line_count,yytext);}

%%