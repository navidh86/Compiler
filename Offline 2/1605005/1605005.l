%option noyywrap

%{
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<bits/stdc++.h>

using namespace std;

int line_count = 1;
int error_count = 0;
FILE* logout;
FILE* tokenout;
int lines;
char str[5000];
char* strptr;
char logstr[5000];
char* logptr;

class SymbolInfo {
    string name, type;

public:
    SymbolInfo* next;

    SymbolInfo()
    {
        next = 0;
    }

    SymbolInfo(string name, string type)
    {
        this->name = name;
        this->type = type;
        next = 0;
    }

    void setName(string name)
    {
        this->name = name;
    }

    void setType(string type)
    {
        this->type = type;
    }

    string getName()
    {
        return name;
    }

    string getType()
    {
        return type;
    }
};

class ScopeTable
{
    int hashFunction(string s)
    {
        unsigned int key = 0;
        for(int i = 0; i < s.size(); i++)
        {
            key += s[i];
            key += (key << 10);
            key ^= (key >> 6);
        }
        key += (key << 3);
        key ^= (key >> 11);
        key += (key << 15);

        return key % size;
    }

    int id;
    int size;
    SymbolInfo** table;

public:
    static int totalTables;
    ScopeTable* parentScope;

    ScopeTable(int n)
    {
        size = n;
        table = new SymbolInfo*[size];

        for(int i=0; i<size; i++)
                table[i] = 0;

        id = ++totalTables;
        parentScope = 0;
    }

    ~ScopeTable()
    {
        totalTables--;
        for(int i=0; i<size; i++)
        {
            SymbolInfo *temp1, *temp2;
            temp1 = table[i];
            while(temp1)
            {
                temp2 = temp1;
                temp1 = temp1->next;
                delete temp2;
            }
        }

        delete[] table;
    }

    SymbolInfo* LookUp(string key)
    {
        int idx = hashFunction(key);
        SymbolInfo* temp = table[idx];
        int position = 0;

        while(temp)
        {
            if(temp->getName() == key)
            {
                break;
            }
            else
            {
                temp = temp->next;
                position++;
            }
        }

        return temp;
    }

    bool Insert(SymbolInfo si)
    {
        int idx = hashFunction(si.getName());
        SymbolInfo *temp = table[idx], *prev = 0;
        int position = 0;

        while(temp)
        {
            if(temp->getName() == si.getName())
            {
                return false;
            }
            else
            {
                prev = temp;
                temp = temp->next;
                position++;
            }
        }

        temp = new SymbolInfo(si.getName(), si.getType());

        if(prev)
            prev->next = temp;
        else table[idx] = temp;

        return true;
    }

    bool Delete(string key)
    {
        SymbolInfo* temp = LookUp(key);

        if(!temp)
        {
            return false;
        }

        int idx = hashFunction(key);
        temp = table[idx];
        SymbolInfo* prev = 0;
        int position = 0;

        while(temp)
        {
            if(temp->getName() == key)
            {
                if(prev)
                    prev->next = temp->next;
                else
                    table[idx] = temp->next;
                delete temp;
                break;
            }
            else
            {
                prev = temp;
                temp = temp->next;
                position++;
            }
        }

        return true;
    }

    void printTable()
    {
	fprintf(logout, "\nScopeTable# %d\n",this->id);
        for(int i=0; i<size; i++)
        {
	    if(table[i] == 0)
		continue;
	    fprintf(logout, "%d --> ", i);
            SymbolInfo* temp = table[i];
            while(temp)
            {
		char name[temp->getName().size()];
		int j = 0;
		for(j=0; j < temp->getName().size(); j++)
			name[j] = temp->getName()[j];
		name[j] = 0;

		char type[temp->getType().size()];
		for(j=0; j < temp->getType().size(); j++)
			type[j] = temp->getType()[j];
		type[j] = 0;
	
		fprintf(logout, "<%s, %s> ", name, type);
                temp = temp->next;
            }
            fprintf(logout,"\n");
        }
        fprintf(logout,"\n");
    }
};

    int ScopeTable::totalTables = 0;

class SymbolTable {
    ScopeTable* currentScope;
    int scopeTableSize;

public:
    SymbolTable(int n)
    {
        scopeTableSize = n;
        currentScope = new ScopeTable(scopeTableSize);
    }

    void enterScope()
    {
        ScopeTable* temp = new ScopeTable(scopeTableSize);
        temp->parentScope = currentScope;
        currentScope = temp;
    }

    void exitScope()
    {
        if(currentScope)
        {
            ScopeTable* temp = currentScope;
            currentScope = currentScope->parentScope;
            delete temp;
        }
        else
        {
            cout<<endl<<"No Scope Exists"<<endl;
        }
    }

    bool Insert(string name, string type) 
    {
	return currentScope->Insert(*(new SymbolInfo(name, type)));
    }
	
    bool Insert(SymbolInfo si)
    {
        return currentScope->Insert(si);
    }

    bool Remove(string key)
    {
        return currentScope->Delete(key);
    }

    SymbolInfo* LookUp(string key)
    {
        SymbolInfo* result = 0;
        ScopeTable* temp = currentScope;

        while(result == 0 && temp != 0)
        {
            result = temp->LookUp(key);
            temp = temp->parentScope;
        }

        return result;
    }

    void printCurrent()
    {
        currentScope->printTable();
    }

    void printAll()
    {
        ScopeTable* temp = currentScope;
        while(temp != 0)
        {
            temp->printTable();
            temp = temp->parentScope;
        }
    }
};

SymbolTable st(7);

%}

%x commenttype1
%x commenttype2
%x string

WHITESPACE [ \t\f\r\v]+

%%

{WHITESPACE} //eat up

(\n)+ {line_count += strlen(yytext);}

"if" {	
	fprintf(tokenout, "<IF> "); 
	fprintf(logout,"\nLine no %d: TOKEN <IF> Lexeme %s found\n",line_count,yytext);	
	}

"else" { 
	fprintf(tokenout, "<ELSE> "); 
	fprintf(logout,"\nLine no %d: TOKEN <ELSE> Lexeme %s found\n",line_count,yytext);	
	}

"for" { 
	fprintf(tokenout, "<FOR> "); 
	fprintf(logout,"\nLine no %d: TOKEN <FOR> Lexeme %s found\n",line_count,yytext);	
	}

"while" { 
	fprintf(tokenout, "<WHILE> "); 
	fprintf(logout,"\nLine no %d: TOKEN <WHILE> Lexeme %s found\n",line_count,yytext);	
	}

"do" { 
	fprintf(tokenout, "<DO> "); 
	fprintf(logout,"\nLine no %d: TOKEN <DO> Lexeme %s found\n",line_count,yytext);	
	}
	
"break" { 
	fprintf(tokenout, "<BREAK> "); 
	fprintf(logout,"\nLine no %d: TOKEN <BREAK> Lexeme %s found\n",line_count,yytext);	
	}	

"int" { 
	fprintf(tokenout, "<INT> "); 
	fprintf(logout,"\nLine no %d: TOKEN <INT> Lexeme %s found\n",line_count,yytext);	
	}

"char" { 
	fprintf(tokenout, "<CHAR> "); 
	fprintf(logout,"\nLine no %d: TOKEN <CHAR> Lexeme %s found\n",line_count,yytext);	
	}

"float" { 
	fprintf(tokenout, "<FLOAT> "); 
	fprintf(logout,"\nLine no %d: TOKEN <FLOAT> Lexeme %s found\n",line_count,yytext);	
	}

"double" { 
	fprintf(tokenout, "<DOUBLE> "); 
	fprintf(logout,"\nLine no %d: TOKEN <DOUBLE> Lexeme %s found\n",line_count,yytext);	
	}

"void" { 
	fprintf(tokenout, "<VOID> "); 
	fprintf(logout,"\nLine no %d: TOKEN <VOID> Lexeme %s found\n",line_count,yytext);	
	}
	
"return" { 
	fprintf(tokenout, "<RETURN> "); 
	fprintf(logout,"\nLine no %d: TOKEN <RETURN> Lexeme %s found\n",line_count,yytext);	
	}

"switch" { 
	fprintf(tokenout, "<SWITCH> "); 
	fprintf(logout,"\nLine no %d: TOKEN <SWITCH> Lexeme %s found\n",line_count,yytext);	
	}

"case" { 
	fprintf(tokenout, "<CASE> "); 
	fprintf(logout,"\nLine no %d: TOKEN <CASE> Lexeme %s found\n",line_count,yytext);	
	}

"default" { 
	fprintf(tokenout, "<DEFAULT> "); 
	fprintf(logout,"\nLine no %d: TOKEN <DEFAULT> Lexeme %s found\n",line_count,yytext);	
	}

"continue" { 
	fprintf(tokenout, "<CONTINUE> ");
	fprintf(logout,"Line no %d: TOKEN <CONTINUE> Lexeme %s found\n",line_count,yytext);	
	}

[0-9]+ { 
	fprintf(tokenout, "<CONST_INT, %s> ", yytext); 
	fprintf(logout,"\nLine no %d: TOKEN <CONST_INT> Lexeme %s found\n",line_count,yytext);
	st.Insert(yytext, "CONST_INT");
	st.printCurrent();	
	}

[a-zA-Z_][a-zA-Z0-9_]* { 
	fprintf(tokenout,"<ID, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <ID> Lexeme %s found\n",line_count,yytext);
	if(st.LookUp(yytext) == 0)
	{
		st.Insert(yytext, "ID");
		st.printCurrent();
	}
     }

([0-9]+"."[0-9]*|"."[0-9]+)((E|e)[-+]?[0-9]+)? |
[0-9]+(E|e)[-+]?[0-9]+ { 
	fprintf(tokenout, "<CONST_FLOAT, %s> ", yytext); 
	fprintf(logout,"\nLine no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
	st.Insert(yytext, "CONST_FLOAT");
	st.printCurrent();	
	}

([0-9]+"."[0-9]*|"."[0-9]+)"."("."|[0-9])*((E|e)[-+]?[0-9]+)? |
".""."+[0-9]("."|[0-9])*((E|e)[-+]?[0-9]+)?  {
				error_count++;
				fprintf(logout, "\nError at line %d: Too many decimal points %s\n", line_count, yytext);		
			}

(([0-9]+"."[0-9]*|"."[0-9]+)|[0-9]+)(E|e)[-+]?([0-9]+"."[0-9]*)? |
(E|e)[-+]?[0-9]+ {
		error_count++;
		fprintf(logout, "\nError at line %d: Ill formed number %s\n", line_count, yytext);
	}

\'[^\n\t\'\"\\]\' { 
	fprintf(tokenout, "<CONST_CHAR, %c> ",yytext[1]); 
	fprintf(logout,"\nLine no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
	st.Insert(yytext, "CONST_CHAR");
	st.printCurrent();	
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
	fprintf(tokenout, "<CONST_CHAR, %c> ",c); 
	fprintf(logout,"\nLine no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);	
	st.Insert(yytext, "CONST_CHAR");
	st.printCurrent();	
	}

\'\' {
	error_count++;
	fprintf(logout,"\nError at line no %d: Empty character constant error %s\n", line_count, yytext);	
     }


\'\\\' {
	error_count++;
	fprintf(logout,"\nError at line no %d: Unterminated character %s\n", line_count, yytext);	
   }

\'[^\n\t\'\"]*/[\n\t<<EOF>>] |
\' {
	error_count++;
	fprintf(logout,"\nError at line no %d: Unterminated character %s\n", line_count, yytext);	
	}

\'[^\\\n\t\'\"][^\n\t\'\"]+\' |
\'\\[^\n\t][^\n\t\'\"]+\' |
\'\t\' {
	error_count++;
	fprintf(logout,"\nError at line no %d: Multi character constant error %s\n", line_count, yytext);	
	}


[-+] { 
	fprintf(tokenout,"<ADDOP, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <ADDOP> Lexeme %s found\n",line_count,yytext);	
	}

[*/%] { 
	fprintf(tokenout,"<MULOP, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <MULOP> Lexeme %s found\n",line_count,yytext);	
	}

"++"|"--" { 
	fprintf(tokenout,"<INCOP, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <INCOP> Lexeme %s found\n",line_count,yytext);	
	}

"<"|"<="|">"|">="|"=="|"!=" { 
	fprintf(tokenout,"<RELOP, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <RELOP> Lexeme %s found\n",line_count,yytext);	
	}

"=" { 
	fprintf(tokenout,"<ASSIGNOP, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",line_count,yytext);	
	}

"&&"|"||" { 
	fprintf(tokenout,"<LOGICOP, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <LOGICOP> Lexeme %s found\n",line_count,yytext);	
	}

"&"|"|"|"^"|"<<"|">>"|"~" { 
	fprintf(tokenout,"<BITOP, %s> ",yytext);
	fprintf(logout,"\nLine no %d: TOKEN <BITOP> Lexeme %s found\n",line_count,yytext);	
	}

"!"|"("|")"|"{"|"}"|"["|"]"|","|";" { 
	char c = yytext[0];
	const char *str;
	switch(c)
	{
		case '!': str = "NOT"; break;
		case '(': str = "LPAREN"; break;
		case ')': str = "RPAREN"; break;
		case '{': str = "LCURL"; break;
		case '}': str = "RCURL"; break;
		case '[': str = "LTHIRD"; break;
		case ']': str = "RTHIRD"; break;
		case ',': str = "COMMA"; break;
		case ';': str = "SEMICOLON"; break;
		default: str = ""; break;
		
	}
	fprintf(tokenout,"<%s, %s> ",str, yytext);
	fprintf(logout,"\nLine no %d: TOKEN <%s> Lexeme %s found\n",line_count, str, yytext);	
	}

[0-9]+[a-zA-Z_][a-zA-Z0-9_]* {
				error_count++;
				fprintf(logout, "\nError at line %d: Invalid prefix on ID or invalid suffix on Number %s\n", line_count, yytext);
			}

\" { lines = 0; strptr = str; logptr = logstr; *logptr++ = '\"'; BEGIN(string);}

<string>[^\"\\\n]+ {
			char* yptr = yytext;
			while(*yptr)
				{ *strptr++ = *yptr; *logptr++ = *yptr++;}
		}

<string>\\. {
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

<string>\\(\r)*\n { lines++; *logptr++ = yytext[0]; *logptr++ = yytext[1]; } 

<string>\n {
		*strptr = '\0';
		*logptr = '\0';
		lines++;
		error_count++;
		fprintf(logout, "\nError at line no %d: Unterminated String %s\n",line_count, logstr);
		line_count += lines;
		BEGIN(INITIAL);
	}

<string><<EOF>> {
		*strptr = '\0';
		*logptr = '\0';
		error_count++;
		fprintf(logout, "\nError at line no %d: Unterminated String %s\n",line_count, logstr);
		line_count += lines;
		BEGIN(INITIAL);
	}

<string>\" {
		*strptr = '\0';
		*logptr++ = '\"';
		*logptr = '\0';
		fprintf(tokenout,"<STRING, %s> ",str);
		fprintf(logout,"\nLine no %d: TOKEN <STRING> Lexeme %s found\n",line_count,logstr);
		line_count += lines;
		BEGIN(INITIAL);
	}


"/*" { lines = 0; logptr = logstr; *logptr++ = '/'; *logptr++ = '*'; BEGIN(commenttype1);}

<commenttype1>[^*\n]+ {
			char* yptr = yytext;
			while(*yptr)
				*logptr++ = *yptr++;
			cout<<"found "<<yytext<<endl;
		 } 

<commenttype1>\n { lines++; *logptr++ = '\n';}

<commenttype1>"*"+[^*/\n] {
				char* yptr = yytext;
				while(*yptr)
				   *logptr++ = *yptr++;
				cout<<"found "<<yytext<<endl;
			 } 

<commenttype1>"*/" {  
			*logptr++ = '*';
			*logptr++ = '/';
			*logptr = '\0'; 
			fprintf(logout, "\nLine no %d: Token <COMMENT> lexeme %s found\n", line_count, logstr);
			line_count += lines; 
			BEGIN(INITIAL);
		}

<commenttype1><<EOF>> { 
			error_count++;	
			*logptr = '\0';
			fprintf(logout, "\nError at line %d: Unterminated comment %s\n", line_count, logstr);
			cout<<line_count<<endl;
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
			fprintf(logout, "\nLine no %d: Token <COMMENT> lexeme %s found\n", line_count, logstr);
			line_count += lines;
			BEGIN(INITIAL);
		} 

<commenttype2><<EOF>> {
			*logptr = '\0';
			fprintf(logout, "\nLine no %d: Token <COMMENT> lexeme %s found\n", line_count, logstr);
			line_count += lines;
			BEGIN(INITIAL);
		}

. { error_count++; fprintf(logout,"\nError at Line no %d: Unrecognized character %s found\n",line_count,yytext);}


%%

int main(int argc,char *argv[]){
	
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
	fclose(yyin);
	st.printCurrent();
	fprintf(logout, "Total lines: %d\n", line_count - 1);
	fprintf(logout, "Total errors: %d\n", error_count);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
