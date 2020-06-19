%{
#include<bits/stdc++.h>
#include "SymbolTable.h"
#include "optimizer.h"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *fp;
FILE *errorout;
FILE *codeout;
FILE *optimized_codeout;

extern int line_count;
int error_count = 0;
string init = ".MODEL small \n.STACK 100h \n";
string data_segment = ".DATA\n\tprint_var dw ?\n\tret_temp dw ?\n";

bool isMain = 0;
vector<SymbolInfo*> tempList;  //used to store variables for delcaration lists
vector<variableInfo> tempList2; //used to store variables for parameter list
vector<vector<string> > tempList3; //used to store variables for argument list
vector<string> tempList4; //used to store the symbol names of current function parameters
vector<vector<string> > tempList5; //used to store symbol names of function arguments

SymbolTable* table;
int ScopeTable::totalTables = 0;

void yyerror(const char *s)
{
	error_count++;
	fprintf(errorout, "\nError at line no %d: %s\n",line_count, s);
}

int label_count = 0;
int temp_count = 0;

string newLabel()
{
	string lb = "L";
	lb += to_string(label_count);
	label_count++;
	return lb;
}

string newTemp()
{
	string temp = "t";
	temp += to_string(temp_count);
	temp_count++;
	data_segment += "\t";
	data_segment += temp + " dw ?\n";
	return temp;	
}

%}

%union{
 SymbolInfo* si;
}

%token IF ELSE FOR WHILE DO BREAK 
%token ID INT CHAR FLOAT DOUBLE 
%token VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN
%token ADDOP MULOP ASSIGNOP RELOP LOGICOP BITOP INCOP DECOP
%token NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token CONST_INT CONST_FLOAT CONST_CHAR

%left ADDOP 
%left MULOP
%left RELOP 
%left LOGICOP 
%left BITOP 

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%error-verbose

%start start

%%

start : program {
				$<si>$ = new SymbolInfo($<si>1->getName(), "start");
				fprintf(errorout, "\nTotal lines : %d\n", line_count);
				fprintf(errorout, "\nTotal errors : %d\n", error_count);
				if(error_count == 0) 
				{
				fprintf(codeout, init.c_str());
				fprintf(codeout, data_segment.c_str());
				fprintf(codeout, ".CODE\n");
				//add the print procedure
				fprintf(codeout, "print PROC\n\t\\
push ax\n\t\\
push bx \n\t\\
push cx\n\t\\
push dx\n\t\\
mov ax, print_var\n\t\\
mov bx, 10\n\t\\
mov cx, 0\n\\
printLabel1:\n\t\\
mov dx, 0\n\t\\
div bx\n\t\\
push dx\n\t\\
inc cx\n\t\\
cmp ax, 0\n\t\\
jne printLabel1\n\\
printLabel2:\n\t\\
mov ah, 2\n\t\\
pop dx\n\tadd dl, '0'\n\t\\
int 21h\n\t\\
dec cx\n\t\\
cmp cx, 0\n\t\\
jne printLabel2\n\t\\
mov dl, 0Ah\n\t\\
int 21h\n\t\\
mov dl, 0Dh\n\t\\
int 21h\n\t\\
pop dx\n\t\\
pop cx\n\t\\
pop bx\n\t\\
pop ax\n\tret\n\\
print endp\n");
				fprintf(codeout, "%s",  $<si>1->code.c_str());
				fprintf(codeout, "END main_proc\n");


				//optimized version
				fprintf(optimized_codeout, init.c_str());
				fprintf(optimized_codeout, data_segment.c_str());
				fprintf(optimized_codeout, ".CODE\n");
				//add the print procedure
				fprintf(optimized_codeout, "print PROC\n\t\\
push ax\n\t\\
push bx \n\t\\
push cx\n\t\\
push dx\n\t\\
mov ax, print_var\n\t\\
mov bx, 10\n\t\\
mov cx, 0\n\\
printLabel1:\n\t\\
mov dx, 0\n\t\\
div bx\n\t\\
push dx\n\t\\
inc cx\n\t\\
cmp ax, 0\n\t\\
jne printLabel1\n\\
printLabel2:\n\t\\
mov ah, 2\n\t\\
pop dx\n\tadd dl, '0'\n\t\\
int 21h\n\t\\
dec cx\n\t\\
cmp cx, 0\n\t\\
jne printLabel2\n\t\\
mov dl, 0Ah\n\t\\
int 21h\n\t\\
mov dl, 0Dh\n\t\\
int 21h\n\t\\
pop dx\n\t\\
pop cx\n\t\\
pop bx\n\t\\
pop ax\n\tret\n\\
print endp\n");
				fprintf(optimized_codeout, "%s",  optimize($<si>1->code).c_str());
				fprintf(optimized_codeout, "END main_proc\n");
		} 
		}
	;

program : program unit {
				$<si>$ = new SymbolInfo($<si>1->getName() + "\n" + $<si>2->getName(), "program");

				//code
				$<si>$->code = $<si>1->code + $<si>2->code;
			}
	| unit {
				$<si>$ = new SymbolInfo($<si>1->getName(), "program");

				//code
				$<si>$->code = $<si>1->code;
		}
	;
	
unit : var_declaration {
				$<si>$ = new SymbolInfo($<si>1->getName(), "unit");
			}
    	| func_declaration {
				$<si>$ = new SymbolInfo($<si>1->getName(), "unit");
			}
    	| func_definition {
				$<si>$ = new SymbolInfo($<si>1->getName(), "unit");

				//code
				$<si>$->code = $<si>1->code;
			}
   		;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
				$<si>$ = new SymbolInfo($<si>1->getName() + " " + $<si>2->getName() + "(" + $<si>4->getName() + ")" + ";", "func_declaration");

				//check if declared as a variable before
				SymbolInfo* temp = table->LookUp($<si>2->getName());
				if(temp != 0 && temp->isFunc == 0)
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: ID %s has been declared as %s before\n",line_count, temp->getName().c_str(), temp->getDecType().c_str());
				}

				//if not then check if declared before
				else if(temp != 0 && temp->isFunc)
				{
					//if so, check if consistent with the previous one
					//match the return types
					if(temp->fi.getReturnType() != $<si>1->getName())
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: Function %s already declared or defined to have a return type of %s\n",line_count, $<si>2->getName().c_str(), temp->fi.getReturnType().c_str());
					}

					//match the parameter lists
					//first match the size of the lists
					if(tempList2.size() != temp->fi.getListSize())
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: Number of parameters of %s does not match with its previous declaration or definition\n",line_count, $<si>2->getName().c_str());
					}
					//now match all the types
					else {
						for(int i=0; i<tempList2.size(); i++)
						{
							if(tempList2[i].getDecType() != temp->fi.getItem(i).getDecType())
							{
								error_count++;
								fprintf(errorout, "\nError at line no %d: Parameter type mismatch : Parameter number %d was declared to be %s in the previous declaration or definition of %s\n",line_count, i+1, temp->fi.getItem(i).getDecType().c_str(), $<si>2->getName().c_str());
							}
						}
					}
				}
				else {
					//make id a function
					$<si>2->makeFunc();
					//set return type
					$<si>2->fi.setReturnType($<si>1->getName());
					//set the parameter list
					for(int i=0; i<tempList2.size(); i++)
					{
						$<si>2->fi.addItem(tempList2[i]);
					}			

					//mark as declared
					$<si>2->fi.makeDeclared();	

					//add to the symbol table
					table->Insert($<si>2);
				}
				//check the parameter list for multiple use of same name, this case is automatically handled in function definition in the compound 
				//statement embedded function
				for(int i=0; i<tempList2.size()-1; i++)
				{
					for(int j=i+1; j<tempList2.size(); j++)
					{
						if(tempList2[i].getName() != "n/a" && tempList2[j].getName() != "n/a" && tempList2[i].getName() == tempList2[j].getName())
						{
							error_count++;
							fprintf(errorout, "\nError at line no %d: Multiple declaration of variable %s\n",line_count, tempList2[i].getName().c_str());
						}
					}
				}
				//clear the templist
				tempList2.clear();
			}
		| type_specifier ID LPAREN RPAREN SEMICOLON {
				$<si>$ = new SymbolInfo($<si>1->getName() + " " + $<si>2->getName() + "()" + ";", "func_declaration");

				//check if declared as a variable before
				SymbolInfo* temp = table->LookUp($<si>2->getName());
				if(temp != 0 && temp->isFunc == 0)
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: ID %s has been declared as %s before\n",line_count, temp->getName().c_str(), temp->getDecType().c_str());
				}

				//if not then check if declared before
				else if(temp != 0 && temp->isFunc)
				{
					//if so, check if consistent with the previous one
					//match the return types
					if(temp->fi.getReturnType() != $<si>1->getName())
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: Function %s already declared or defined to have a return type of %s\n",line_count, $<si>2->getName().c_str(), temp->fi.getReturnType().c_str());
					}
					//check if previous declaration had 0 parameters
					if(temp->fi.getListSize() > 0)
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: Function %s already declared or defined to have %d parameter(s)\n",line_count, $<si>2->getName().c_str(), temp->fi.getListSize());
					}

				}
				else {
					//make id a function
					$<si>2->makeFunc();
					$<si>2->fi.setReturnType($<si>1->getName());
					//mark as declared
					$<si>2->fi.makeDeclared();
					//add to the symbol table
					table->Insert($<si>2);
				}
			}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
					//check if declared as a variable before
					SymbolInfo* temp = table->LookUp($<si>2->getName());
					if(temp != 0 && temp->isFunc == 0)
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: ID %s has been declared as %s before\n",line_count, temp->getName().c_str(), temp->getDecType().c_str());
					}
					//else if not declared, insert in symbol table
					else if(temp == 0)
					{
						//make id a function
						$<si>2->makeFunc();

						//make the function defined 
						$<si>2->fi.makeDefined();

						$<si>2->fi.setReturnType($<si>1->getName());

						//set the parameter list
						for(int i=0; i<tempList2.size(); i++)
						{
							$<si>2->fi.addItem(tempList2[i]);

							//also the parametersymbolname
							string symbol = tempList2[i].getName() + "_";
							symbol += to_string(ScopeTable::totalTables);
							$<si>2->fi.parameterSymbols.push_back(symbol);
							tempList4.push_back(symbol);
						}	

						//add to the symbol table
						table->Insert($<si>2);
						//cannot clear the templis2 yet, as the variables need to be added to the symbol table in compound statement action

						//check if main
						if($<si>2->getName() == "main")
							isMain = true;
					}
				} compound_statement {				
				bool flag = 0;  //to track if the function is defined properly

				$<si>$ = new SymbolInfo($<si>1->getName() + " " + $<si>2->getName() + "(" + $<si>4->getName() + ")" + $<si>7->getName(), "func_definition");

				//check if declared before
				SymbolInfo* temp = table->LookUp($<si>2->getName());
				
				if(temp != 0 && temp->isFunc && temp->fi.getIsDeclared())
				{
					//if so, check if consistent
					//match the return types
					if(temp->fi.getReturnType() != $<si>1->getName())
					{
						flag = 1;
						error_count++;
						fprintf(errorout, "\nError at line no %d: Function %s already declared to have a return type of %s\n",line_count, $<si>2->getName().c_str(), temp->fi.getReturnType().c_str());
					}

					//match the parameter lists
					//first match the size of the lists
					if(tempList2.size() != temp->fi.getListSize())
					{
						flag = 1;
						error_count++;
						fprintf(errorout, "\nError at line no %d: Number of parameters of %s does not match with its declaration\n",line_count, $<si>2->getName().c_str());
					}
					//now match all the types
					else {
						for(int i=0; i<tempList2.size(); i++)
						{
							if(tempList2[i].getDecType() != temp->fi.getItem(i).getDecType())
							{
								flag = 1;
								error_count++;
								fprintf(errorout, "\nError at line no %d: Parameter type mismatch : Parameter number %d was declared to be %s in the declaration of %s\n",line_count, i+1, temp->fi.getItem(i).getDecType().c_str(), $<si>2->getName().c_str());
							}
						}
					}
				}

				//code
				$<si>$->code = $<si>2->getName() + "_proc PROC\n";

				if($<si>2->getName() == "main") 
				{
					//initialize the data data_segment
					$<si>$->code += "\tmov ax, @data\n";
					$<si>$->code += "\tmov ds, ax\n";
				}
				else {
					//push the registers
					$<si>$->code += "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n\tpush di\n";
				}

				//body
				$<si>$->code += $<si>7->code;

				//add a ret for void functions
				if($<si>2->getName() != "main" && $<si>1->getName() == "void")
					$<si>$->code += "\tret\n";
				
				$<si>$->code += $<si>2->getName() + "_proc ENDP\n"; 

				isMain = false;

				//clear the templist
				tempList2.clear();
				tempList4.clear();
			}
		| type_specifier ID LPAREN RPAREN {
					//check if declared as a variable before
					SymbolInfo* temp = table->LookUp($<si>2->getName());
					if(temp != 0 && temp->isFunc == 0)
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: ID %s has been declared as %s before\n",line_count, temp->getName().c_str(), temp->getDecType().c_str());
					}
					//else if not declared, insert in symbol table
					else if(temp == 0)
					{
						//make id a function
						$<si>2->makeFunc();
						$<si>2->fi.setReturnType($<si>1->getName());

						//make the function defined 
						$<si>2->fi.makeDefined();

						if($<si>2->getName() == "main")
							isMain = true;

						//add to the symbol table
						table->Insert($<si>2);
					}
				} compound_statement {
				bool flag = 0;
				$<si>$ = new SymbolInfo($<si>1->getName() + " " + $<si>2->getName() + "()" + $<si>6->getName(), "func_definition");

				//check if declared before
				SymbolInfo* temp = table->LookUp($<si>2->getName());
				if(temp != 0 && temp->isFunc && temp->fi.getIsDeclared())
				{
					//if so, check if consistent
					//match the return types
					if(temp->fi.getReturnType() != $<si>1->getName())
					{
						flag = 1;
						error_count++;
						fprintf(errorout, "\nError at line no %d: Function %s already declared to have a return type of %s\n",line_count, $<si>2->getName().c_str(), temp->fi.getReturnType().c_str());
					}

					//check if declaration had 0 parameters
					if(temp->fi.getListSize() > 0)
					{
						flag = 1;
						error_count++;
						fprintf(errorout, "\nError at line no %d: Function %s already declared to have %d parameter(s)\n",line_count, $<si>2->getName().c_str(), temp->fi.getListSize());
					}
				}				

				//code
				$<si>$->code = $<si>2->getName() + "_proc PROC\n";

				if($<si>2->getName() == "main") 
				{
					//initialize the data data_segment
					$<si>$->code += "\tmov ax, @data\n";
					$<si>$->code += "\tmov ds, ax\n";
				}
				else {
					//push the registers
					$<si>$->code += "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n\tpush di\n";	
				}

				//body
				$<si>$->code += $<si>6->code;

				//add a ret for void functions
				if($<si>2->getName() != "main" && $<si>1->getName() == "void")
					$<si>$->code += "\tret\n";
				
				$<si>$->code += $<si>2->getName() + "_proc ENDP\n";

				isMain = false;
			}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID {
				$<si>$ = new SymbolInfo($<si>1->getName() + "," + $<si>3->getName() + " " + $<si>4->getName(), "parameter_list");

				//check if void
				if($<si>1->getName() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: void cannot be a parameter\n",line_count);
				}

				//add the type to the tempList
				tempList2.push_back(*new variableInfo($<si>3->getName(), $<si>4->getName()));
			}
		| parameter_list COMMA type_specifier {
				$<si>$ = new SymbolInfo($<si>1->getName() + "," + $<si>3->getName(), "parameter_list");

				//check if void
				if($<si>3->getName() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: void cannot be a parameter\n",line_count);
				}

				//add the type to the tempList
				tempList2.push_back(*new variableInfo($<si>3->getName(), "n/a"));
			}
 		| type_specifier ID {
				$<si>$ = new SymbolInfo($<si>1->getName() + " " + $<si>2->getName(), "parameter_list");

				//check if void
				if($<si>1->getName() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: void cannot be a parameter\n",line_count);
				}

				//add the type to the tempList
				tempList2.push_back(*new variableInfo($<si>1->getName(), $<si>2->getName()));
			}
		| type_specifier {
				$<si>$ = new SymbolInfo($<si>1->getName(), "parameter_list");

				//check if void
				if($<si>1->getName() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: void cannot be a parameter\n",line_count);
				}

				//add the type to the tempList
				tempList2.push_back(*new variableInfo($<si>1->getName(), "n/a"));
			}
 		;

 		
compound_statement : LCURL {  //embedded action
					table->enterScope();
					//add the variables of parameter list to the symbol table
					for(int i=0; i<tempList2.size(); i++)
					{
						//if named then try to insert
						if(tempList2[i].getName() != "n/a")
						{
							//if already inserted in current scope, show error message
							if(table->LookUpCurrentScope(tempList2[i].getName()) != 0)
							{
								error_count++;
								fprintf(errorout, "\nError at line no %d: Multiple declaration of %s\n",line_count, tempList2[i].getName().c_str());
							}
							else {
								SymbolInfo* temp = new SymbolInfo(tempList2[i].getName(), "ID");
								temp->setDecType(tempList2[i].getDecType());

								//now add the declaration in data data_segment
								string symbol = tempList2[i].getName() + "_";
								symbol += to_string(ScopeTable::totalTables - 1);
								data_segment += "\t" + symbol + " dw ?\n";

								//set the symbol
								temp->setSymbol(symbol);

								table->Insert(temp);
								delete temp;
							}
						}
						//else show error again
						else {
							error_count++;
							fprintf(errorout, "\nError at line no %d: Parameter cannot be unnamed in function definition\n",line_count);
						}
					}
					//no need to clear the list, will be cleared by func_definition					
				}	statements RCURL {
					$<si>$ = new SymbolInfo("{\n" + $<si>3->getName() + "\n}\n", "compound_statement");
					table->exitScope();

					//code
					$<si>$->code = $<si>3->code;
				}
			| LCURL {  //embedded action
					table->enterScope();
					//add the variables of parameter list to the symbol table
					for(int i=0; i<tempList2.size(); i++)
					{
						//if named then try to insert
						if(tempList2[i].getName() != "n/a")
						{
							//if already inserted in current scope, show error message
							if(table->LookUpCurrentScope(tempList2[i].getName()) != 0)
							{
								error_count++;
								fprintf(errorout, "\nError at line no %d: Multiple declaration of %s\n",line_count, tempList2[i].getName().c_str());
							}
							else {
								SymbolInfo* temp = new SymbolInfo(tempList2[i].getName(), "ID");
								temp->setDecType(tempList2[i].getDecType());

								//now add the declaration in data data_segment
								string symbol = tempList2[i].getName() + "_";
								symbol += to_string(ScopeTable::totalTables - 1);
								data_segment += "\t" + symbol + " dw ?\n";

								//set the symbol
								temp->setSymbol(symbol);

								table->Insert(temp);
								delete temp;
							}
						}
						//else show error again
						else {
							error_count++;
							fprintf(errorout, "\nError at line no %d: Parameter cannot be unnamed in function definition\n",line_count);
						}
					}
					//no need to clear the list, will be cleared by func_definition	
				}	RCURL {
					$<si>$ = new SymbolInfo("{\n}\n", "compound_statement");
					table->exitScope();
				}
			;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
				$<si>$ = new SymbolInfo($<si>1->getName() + " " + $<si>2->getName() + ";", "var_declaration");

				//check if void
				if($<si>1->getName() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: variable cannot be of type void\n",line_count);
					//set the type to integer, to avoid future errors
					$<si>1->setName("int");
				}

				//time to set the dec types of all variables in dec list
				for(int i=0; i<tempList.size(); i++)
					tempList[i]->setDecType($<si>1->getName());

				//now to add them to the symbol table
				for(int i=0; i<tempList.size(); i++)
				{
					if(table->LookUpCurrentScope(tempList[i]->getName()) != 0)
					{
						//already exists in the current scope
						error_count++;
						fprintf(errorout, "\nError at line no %d: Multiple declaration of %s\n",line_count, tempList[i]->getName().c_str());
					}
					else {
						//now add the declaration in data data_segment
						string symbol = tempList[i]->getName() + "_";
						symbol += to_string(ScopeTable::totalTables - 1);
						data_segment += "\t" + symbol + " dw ";
						if(tempList[i]->isArray)
						{
							data_segment += to_string(tempList[i]->getArraySize());
							data_segment += " dup(?)\n";
						}
						else data_segment += "?\n";

						//set the symbol
						tempList[i]->setSymbol(symbol);

						//insert now
						table->Insert(tempList[i]);
					}
				}

				//clear the list now
				//delete the items first
				for(int i=0; i<tempList.size(); i++)
					delete tempList[i];
				tempList.clear();
			}
 		;
 		 
type_specifier	: INT {
					$<si>$ = new SymbolInfo("int", "type_specifier");
				}
	 		| FLOAT {
					$<si>$ = new SymbolInfo("float", "type_specifier");
				}
 			| VOID {
					$<si>$ = new SymbolInfo("void", "type_specifier");
				}
 		;
 		
declaration_list : declaration_list COMMA ID {
				tempList.push_back($<si>3);
				$<si>$ = new SymbolInfo($<si>1->getName() + "," + $<si>3->getName(), "declaration_list");
			}
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
				$<si>3->makeArray();
				$<si>3->setArraySize(stoi($<si>5->getName()));
				tempList.push_back($<si>3);
				$<si>$ = new SymbolInfo($<si>1->getName() + "," + $<si>3->getName() + "[" + $<si>5->getName() + "]", "declaration_list");
			}
	    | ID {
			$<si>$ = new SymbolInfo($<si>1->getName(), "declaration_list");
			tempList.push_back($<si>1); 
		}
 		| ID LTHIRD CONST_INT RTHIRD {
			$<si>$ = new SymbolInfo($<si>1->getName() + "[" + $<si>3->getName() + "]", "declaration_list");
			$<si>1->makeArray();
			$<si>1->setArraySize(stoi($<si>3->getName()));
			tempList.push_back($<si>1);
	 	}
 		;
 		  
statements : statement {
				$<si>$ = new SymbolInfo($<si>1->getName(), "statements");

				//code
				$<si>$->code = $<si>1->code;
			}
	    | statements statement {
				$<si>$ = new SymbolInfo($<si>1->getName() + "\n" + $<si>2->getName() , "statements");

				//code
				$<si>$->code = $<si>1->code + $<si>2->code;
			}
	   ;
	   
statement : var_declaration {
				$<si>$ = new SymbolInfo($<si>1->getName(), "statement");

				//code
				$<si>$->code = $<si>1->code;
			}
	    | expression_statement {
				$<si>$ = new SymbolInfo($<si>1->getName(), "statement");

				//code
				$<si>$->code = $<si>1->code;
			}
	    | compound_statement {
				$<si>$ = new SymbolInfo($<si>1->getName(), "statement");

				//code
				$<si>$->code = $<si>1->code;
			}
	    | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
				$<si>$ = new SymbolInfo("for(" + $<si>3->getName() + $<si>4->getName() + $<si>5->getName() + ")" + $<si>7->getName(), "statement");

				//code
				$<si>$->code = $<si>3->code;

				string l1 = newLabel(), l2 = newLabel();

				//start of loop
				$<si>$->code += l1 + ":\n";

				//check condition
				$<si>$->code += $<si>4->code;

				//cmp with 0
				$<si>$->code += "\tmov ax, " + $<si>4->symbol + "\n";	
				$<si>$->code += "\tcmp ax, 0\n";
				$<si>$->code += "\tje " + l2 + "\n";

				$<si>$->code += $<si>7->code;
				$<si>$->code += $<si>5->code;
				$<si>$->code += "\tjmp " + l1 + "\n";
				$<si>$->code += l2 + ":\n";
			}
	    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
				$<si>$ = new SymbolInfo("if(" + $<si>3->getName() + ") " + $<si>5->getName(), "statement");

				//code
				$<si>$->code = $<si>3->code;

				string l1 = newLabel();

				$<si>$->code += "\tmov ax, " + $<si>3->symbol + "\n";
				$<si>$->code += "\tcmp ax, 0\n";
				$<si>$->code += "\tje " + l1 + "\n";
				//true
				$<si>$->code += $<si>5->code;

				//exit
				$<si>$->code += l1 + ":\n";
			}
	    | IF LPAREN expression RPAREN statement ELSE statement {
				$<si>$ = new SymbolInfo("if(" + $<si>3->getName() + ") " + $<si>5->getName() + " else " + $<si>7->getName(), "statement");

				//code
				$<si>$->code = $<si>3->code;

				string l1 = newLabel(), l2 = newLabel();

				$<si>$->code += "\tmov ax, " + $<si>3->symbol + "\n";
				$<si>$->code += "\tcmp ax, 0\n";
				$<si>$->code += "\tje " + l1 + "\n";
				//true
				$<si>$->code += $<si>5->code;
				$<si>$->code += "\tjmp " + l2 + "\n";

				//false
				$<si>$->code += l1 + ":\n";
				$<si>$->code += $<si>7->code;

				$<si>$->code += l2 + ":\n";
			}
	    | WHILE LPAREN expression RPAREN statement {
				$<si>$ = new SymbolInfo("while(" + $<si>3->getName() + ") " + $<si>5->getName(), "statement");

				//code
				string l1 = newLabel(), l2 = newLabel();
				$<si>$->code = l1 + ":\n";
				$<si>$->code += $<si>3->code;

				//cmp with 0
				$<si>$->code += "\tmov ax, " + $<si>3->symbol + "\n";
				$<si>$->code += "\tcmp ax, 0\n";
				$<si>$->code += "\tje " + l2 + "\n"; //exit loop
				
				$<si>$->code += $<si>5->code;
				$<si>$->code += "\tjmp " + l1 + "\n";

				$<si>$->code += l2 + ":\n";
			}
	    | PRINTLN LPAREN ID RPAREN SEMICOLON {
				$<si>$ = new SymbolInfo("println(" + $<si>3->getName() + ");" , "statement");

				//code
				SymbolInfo* temp = table->LookUp($<si>3->getName());
				if(temp) 
				{
					$<si>$->code = "\tmov ax, " + temp->symbol + "\n";
					$<si>$->code += "\tmov print_var, ax\n";
					$<si>$->code += "\tcall print\n";
				}
				else {
					error_count++;
					fprintf(errorout, "\nError at line no %d: Undeclared variable: %s\n",line_count, $<si>3->getName().c_str());
				}
			}
	    | RETURN expression SEMICOLON {
				$<si>$ = new SymbolInfo("return " + $<si>2->getName() + ";", "statement");

				//code
				$<si>$->code = $<si>2->code;
				if($<si>2->isArray == 0)
				{
					$<si>$->code += "\tmov ax, " + $<si>2->symbol + "\n";
					$<si>$->code += "\tmov ret_temp, ax\n";
				}
				else {
					//for "return a[i] = 5" types
					$<si>$->code += "\tmov ax, " + $<si>2->symbol + "[di]\n";
					$<si>$->code += "\tmov ret_temp, ax\n";
				}
				
				if(isMain == 0)
				{
					//pop the registers
					$<si>$->code += "\tpop di\n\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n";
					$<si>$->code += "\tret\n";
				}
			}
	    ;
	  
expression_statement : SEMICOLON {
				$<si>$ = new SymbolInfo(";", "expression_statement");
			}			
		| expression SEMICOLON {
				$<si>$ = new SymbolInfo($<si>1->getName() + ";", "expression_statement");

				//code
				$<si>$->code = $<si>1->code;
				$<si>$->symbol = $<si>1->symbol;
			}		
		;
  
variable : ID  {
			$<si>$ = new SymbolInfo($<si>1->getName(), "variable");

			//check if declared
			SymbolInfo* temp = table->LookUp($<si>1->getName());
				
			if(temp == 0)
			{
				error_count++;
				fprintf(errorout, "\nError at line no %d: Undeclared variable: %s\n",line_count, $<si>1->getName().c_str());
				//make variable int by default
				$<si>$->setDecType("int");
			}
			else{
				//check if array
				if(temp->isArray)
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: Variable %s is an array \n",line_count, $<si>1->getName().c_str());
				}
				//check if function
				else if(temp->isFunc)
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: Variable %s is a function \n",line_count, $<si>1->getName().c_str());
				}

				//set the declaration type of variable = declaration type of id
				$<si>$->setDecType(temp->getDecType());

				//set symbol
				$<si>$->setSymbol(temp->getSymbol());
			}
		}
	| ID LTHIRD expression RTHIRD {
			$<si>$ = new SymbolInfo($<si>1->getName() + "[" + $<si>3->getName() + "]", "variable");

			//check if declared
			SymbolInfo* temp = table->LookUp($<si>1->getName());
			if(temp == 0)
			{
				error_count++;
				fprintf(errorout, "\nError at line no %d: Undeclared variable: %s\n",line_count, $<si>1->getName().c_str());
				//make variable int by default
				$<si>$->setDecType("int");
			}
			else {
				//check if array
				if(!temp->isArray)
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: Variable %s is not an array \n",line_count, $<si>1->getName().c_str());
				}
				//check if valid index
				else if($<si>3->getDecType() != "int")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: Non-integer array index \n",line_count);
				}

				//set the declaration type of variable = declaration type of id
				$<si>$->setDecType(temp->getDecType());
				
				//make array
				$<si>$->makeArray();

				//set symbol
				$<si>$->symbol = temp->symbol;

				//set code
				$<si>$->code = $<si>3->code;
				$<si>$->code +=  "\tmov di, " + $<si>3->getSymbol() + "\n\tadd di, di\n";
			}
	 	}
	 ;
	 
 expression : logic_expression {
				$<si>$ = new SymbolInfo($<si>1->getName(), "expression");
				//set type
				$<si>$->setDecType($<si>1->getDecType());

				//code
				$<si>$->code = $<si>1->code;
				$<si>$->symbol = $<si>1->symbol;

				//for return statements later
				$<si>$->isArray = $<si>1->isArray;
			}	
	   | variable ASSIGNOP logic_expression {
				$<si>$ = new SymbolInfo($<si>1->getName() + " = " + $<si>3->getName(), "expression");

				//check if type == void
				if($<si>1->getDecType() == "void" || $<si>3->getDecType() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: ASSIGNOP cannot be applied to void\n", line_count);
					if($<si>1->getDecType() == "void")
						$<si>1->setDecType("int");
					if($<si>3->getDecType() == "void")
						$<si>3->setDecType("int"); 
				}

				//check if wrong assignment
				if($<si>1->getDecType() != $<si>3->getDecType())
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: Type Mismatch \n",line_count);
				}

				//set type
				$<si>$->setDecType($<si>1->getDecType());

				//code 
				$<si>$->code = $<si>3->code + $<si>1->code; //3 first, then 1
				$<si>$->code += "\tmov ax, " + $<si>3->symbol + "\n";

				if($<si>1->isArray == 0)
				{
					$<si>$->code += "\tmov " + $<si>1->symbol + ", ax\n";
					$<si>$->symbol = $<si>1->symbol; //might be needed
				}
				else {
					$<si>$->code += "\tmov " + $<si>1->symbol + "[di], ax\n";
					$<si>$->symbol = $<si>1->symbol;
					$<si>$->isArray = true;
				}
			}		 
	   ;
			
logic_expression : rel_expression {
				$<si>$ = new SymbolInfo($<si>1->getName(), "logic_expression");
				//set type
				$<si>$->setDecType($<si>1->getDecType());

				//code
				$<si>$->code = $<si>1->code;
				$<si>$->symbol = $<si>1->symbol;
			}	
		| rel_expression LOGICOP rel_expression {
				$<si>$ = new SymbolInfo($<si>1->getName() + $<si>2->getName() + $<si>3->getName(), "logic_expression");

				//set dectype
				$<si>$->setDecType("int"); //result is always integer

				//check if both are int
				if(!($<si>1->getDecType() == "int" && $<si>3->getDecType() == "int"))
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: Both operands of logicop must be integers \n",line_count);
				}

				//code
				$<si>$->code = $<si>1->code + $<si>3->code;

				string l1 = newLabel(), l2 = newLabel(), temp = newTemp();
				$<si>$->symbol = temp;

				if($<si>2->getName() == "&&")
				{
					$<si>$->code += "\tcmp " + $<si>1->symbol + ", 0\n";
					$<si>$->code += "\tje " + l1 + "\n";
					$<si>$->code += "\tcmp " + $<si>3->symbol + ", 0\n";
					$<si>$->code += "\tje " + l1 + "\n";

					//true
					$<si>$->code += "\tmov " + temp + ", 1\n";
					$<si>$->code += "\tjmp " + l2 + "\n";

					//false
					$<si>$->code += l1 + ":\n";
					$<si>$->code += "\tmov " + temp + ", 0\n";

					$<si>$->code += l2 + ":\n";
				}
				else {
					$<si>$->code += "\tcmp " + $<si>1->symbol + ", 0\n";
					$<si>$->code += "\tjne " + l1 + "\n";
					$<si>$->code += "\tcmp " + $<si>3->symbol + ", 0\n";
					$<si>$->code += "\tjne " + l1 + "\n";

					//false
					$<si>$->code += "\tmov " + temp + ", 0\n";
					$<si>$->code += "\tjmp " + l2 + "\n";

					//true
					$<si>$->code += l1 + ":\n";
					$<si>$->code += "\tmov " + temp + ", 1\n";

					$<si>$->code += l2 + ":\n";
				}
			}	
		;
			
rel_expression : simple_expression {
				$<si>$ = new SymbolInfo($<si>1->getName(), "rel_expression");
				//set type
				$<si>$->setDecType($<si>1->getDecType());

				//code
				$<si>$->code = $<si>1->code;
				$<si>$->symbol = $<si>1->symbol;
			}
		| simple_expression RELOP simple_expression	{
				$<si>$ = new SymbolInfo($<si>1->getName() + $<si>2->getName() + $<si>3->getName(), "rel_expression");

				//check if type == void
				if($<si>1->getDecType() == "void" || $<si>3->getDecType() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: RELOP cannot be applied to void\n", line_count);
				}

				//set type
				$<si>$->setDecType("int"); //result of relop is always int

				//code
				$<si>$->code = $<si>1->code + $<si>3->code;
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "\n";

				$<si>$->code += "\tcmp ax, " + $<si>3->symbol + "\n";

				string l1 = newLabel(), l2 = newLabel();

				if($<si>2->getName() == "<")
				{
					$<si>$->code += "\tjge " + l1 + "\n";
				}
				else if($<si>2->getName() == "<=")
				{
					$<si>$->code += "\tjg " + l1 + "\n";
				}
				else if($<si>2->getName() == ">")
				{
					$<si>$->code += "\tjle " + l1 + "\n";
				}
				else if($<si>2->getName() == ">=")
				{
					$<si>$->code += "\tjl " + l1 + "\n";
				}
				else if($<si>2->getName() == "==")
				{
					$<si>$->code += "\tjne " + l1 + "\n";
				}
				else
				{
					$<si>$->code += "\tje " + l1 + "\n";
				}

				string temp = newTemp();
				$<si>$->symbol = temp;

				//true
				$<si>$->code += "\tmov " + temp + ", 1\n";
				$<si>$->code += "\tjmp " + l2 + "\n";

				//false
				$<si>$->code += l1 + ":\n";
				$<si>$->code += "\tmov " + temp + ", 0\n";

				$<si>$->code += l2 + ":\n";
			}
		;
				
simple_expression : term {
				$<si>$ = new SymbolInfo($<si>1->getName(), "simple_expression");
				//set type
				$<si>$->setDecType($<si>1->getDecType());

				//code
				$<si>$->code = $<si>1->code;
				$<si>$->symbol = $<si>1->symbol;
		}
	| simple_expression ADDOP term {
				$<si>$ = new SymbolInfo($<si>1->getName() + $<si>2->getName() + $<si>3->getName(), "simple_expression");

				//check if type == void
				if($<si>1->getDecType() == "void" || $<si>3->getDecType() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: ADDOP cannot be applied to void\n", line_count);
				}

				//set dectype
				if($<si>1->getDecType() == "float" || $<si>3->getDecType() == "float")
					$<si>$->setDecType("float");
				else $<si>$->setDecType("int");

				//code
				$<si>$->code = $<si>1->code + $<si>3->code;
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "\n";

				string temp = newTemp();
				$<si>$->symbol = temp;

				if($<si>2->getName() == "+")
				{
					$<si>$->code += "\tadd ax, " + $<si>3->symbol + "\n";
				}
				else {
					$<si>$->code += "\tsub ax, " + $<si>3->symbol + "\n";
				}

				$<si>$->code += "\tmov " + temp + ", ax\n";				
		}
	;
					
term :	unary_expression {
				$<si>$ = new SymbolInfo($<si>1->getName(), "term");
				//set type
				$<si>$->setDecType($<si>1->getDecType());

				//code
				$<si>$->code = $<si>1->code;
				$<si>$->symbol = $<si>1->symbol;
		}
    |  term MULOP unary_expression {
				$<si>$ = new SymbolInfo($<si>1->getName() + $<si>2->getName() + $<si>3->getName(), "term");

				//check if type == void
				if($<si>1->getDecType() == "void" || $<si>3->getDecType() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: MULOP cannot be applied to void\n", line_count);
				}

				//set type
				if($<si>2->getName() == "*" || $<si>2->getName() == "/")
				{
					if($<si>1->getDecType() == "float" || $<si>3->getDecType() == "float")
						$<si>$->setDecType("float");
					else $<si>$->setDecType("int");
				}
				else {
					//check if both operands are int
					if(!($<si>1->getDecType() == "int" && $<si>3->getDecType() == "int"))
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: Both operands of modulus must be integers \n",line_count);
					}
					//result is always integer
					$<si>$->setDecType("int");
				}

				//code
				$<si>$->code = $<si>1->code + $<si>3->code;
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "\n";
				$<si>$->code += "\tmov bx, " + $<si>3->symbol + "\n";

				string temp = newTemp();
				$<si>$->symbol = temp;

				if($<si>2->getName() == "*") 
				{
					$<si>$->code += "\tmul bx\n";
					$<si>$->code += "\tmov " + temp + ", ax\n";
				}	
				else if($<si>2->getName() == "/")
				{
					$<si>$->code += "\txor dx, dx\n";
					$<si>$->code += "\tdiv bx\n";
					$<si>$->code += "\tmov " + temp + ", ax\n";
				}
				else
				{
					$<si>$->code += "\txor dx, dx\n";
					$<si>$->code += "\tdiv bx\n";
					$<si>$->code += "\tmov " + temp + ", dx\n";
				}
		}
    ;

unary_expression : ADDOP unary_expression  {
				$<si>$ = new SymbolInfo($<si>1->getName().c_str() + $<si>2->getName(), "factor");
				//check if type == void
				if($<si>2->getDecType() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: ADDOP cannot be applied to void\n", line_count);
					//set to int by default
					$<si>$->setDecType("int");
				}
				else {
					//set type
					$<si>$->setDecType($<si>2->getDecType());
				}

				//code
				$<si>$->code = $<si>2->code;

				if($<si>1->getName() == "-")
				{
					$<si>$->code += "\tmov ax, " + $<si>2->symbol + "\n";
					$<si>$->code += "\tneg ax\n";
					string temp = newTemp();
					$<si>$->code += "\tmov " + temp + ", ax\n";
					$<si>$->symbol = temp;
				}
				else $<si>$->symbol = $<si>2->symbol;
			}
		| NOT unary_expression {
				$<si>$ = new SymbolInfo("!" + $<si>2->getName(), "factor");
				//check if type == void
				if($<si>2->getDecType() == "void")
				{
					error_count++;
					fprintf(errorout, "\nError at line no %d: NOT cannot be applied to void\n", line_count);
				}
				//set type
				$<si>$->setDecType("int");  //result of not is integer

				//code
				$<si>$->code = $<si>2->code + "\tmov ax, " + $<si>2->symbol + "\n";
				$<si>$->code += "\tnot ax\n";
				string temp = newTemp();
				$<si>$->code += "\tmov " + temp + ", ax\n";
				$<si>$->symbol = temp;
			}

		| factor {
				$<si>$ = new SymbolInfo($<si>1->getName(), "unary_expression");
				//set type
				$<si>$->setDecType($<si>1->getDecType());

				//code
				$<si>$->code = $<si>1->code;
				$<si>$->symbol = $<si>1->symbol;
			}
		;
	
factor	: variable {
			$<si>$ = new SymbolInfo($<si>1->getName(), "factor");
			//set type
			$<si>$->setDecType($<si>1->getDecType());

			//code
			$<si>$->code = $<si>1->code;
			if($<si>1->isArray == 0)
			{
				$<si>$->symbol = $<si>1->symbol;
			}
			else {
				string temp = newTemp();
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "[di]\n";
				$<si>$->code += "\tmov " + temp + ", ax\n";
				$<si>$->symbol = temp;
			}
		}
	| ID LPAREN argument_list RPAREN {
			$<si>$ = new SymbolInfo($<si>1->getName() + "(" + $<si>3->getName() + ")", "variable");

			//check if id declared
			SymbolInfo* temp = table->LookUp($<si>1->getName());
			if(!temp)
			{
				error_count++;
				fprintf(errorout, "\nError at line no %d: Undeclared variable %s \n",line_count, $<si>1->getName().c_str());
				//set to integer by default
				$<si>$->setDecType("int");
			}
			//check if actually a function
			else if(temp->isFunc == 0)
			{
				error_count++;
				fprintf(errorout, "\nError at line no %d: ID %s is not a function\n", line_count, temp->getName().c_str());
				//set to the type of id
				$<si>$->setDecType($<si>1->getDecType());
			}
			//check if defined
			else if(temp->fi.getIsDefined() == 0)
			{
				error_count++;
				fprintf(errorout, "\nError at line no %d: Function %s has not been defined\n", line_count, temp->getName().c_str());
				//assign the return type of the function to the factor
				$<si>$->setDecType(temp->fi.getReturnType());
			}
			//match the number of arguments with the number of parameters
			else if(tempList3[tempList3.size()-1].size() != temp->fi.getListSize())
			{
				error_count++;
				fprintf(errorout, "\nError at line no %d: Number of arguments does not match with number of parameters of %s\n",line_count, temp->getName().c_str());
				//assign the return type of the function to the factor
				$<si>$->setDecType(temp->fi.getReturnType());
			}
			//match the argument list with the parameter list
			else {
				for(int i=0; i<tempList3[tempList3.size()-1].size(); i++)
				{
					if(tempList3[tempList3.size()-1][i] != temp->fi.getItem(i).getDecType())
					{
						error_count++;
						fprintf(errorout, "\nError at line no %d: Argument type mismatch : Argument number %d of %s has to be %s\n",line_count, i+1, $<si>2->getName().c_str(), temp->fi.getItem(i).getDecType().c_str());
					}
				}
				//assign the return type of the function to the factor
				$<si>$->setDecType(temp->fi.getReturnType());
			}

			//clear the templist3
			tempList3.pop_back();

			//code
			//first of all push all current parameters stored in tempList4 to the stack
			for(int i=0; i<tempList4.size(); i++)
			{
				$<si>$->code += "\tpush " + tempList4[i] + "\n";
			}

			int count = temp_count;

			//push the temporary values to a stack as well
			for(int i = 0; i < temp_count; i++)
			{
				$<si>$->code += "\tpush t" + to_string(i) + "\n";
			}


			//if not main, push the registers as well
			$<si>$->code += $<si>3->code;

			//move the arguments to the parameters of function
			for(int i = 0; i < temp->fi.parameterSymbols.size(); i++)
			{
				$<si>$->code += "\tmov ax, " +  tempList5[tempList5.size()-1][i] + "\n";
				$<si>$->code += "\tmov " + temp->fi.parameterSymbols[i] + ", ax\n";
			}
			
			//call the function
			$<si>$->code += "\tcall " + $<si>1->getName() + "_proc \n";

			//pop from stack 
			string tmp = newTemp();
			if(temp->fi.getReturnType() != "void")
			{
				$<si>$->code += "\tmov ax, ret_temp\n";
				$<si>$->code += "\tmov " + tmp + ", ax\n";
			}

			//assign the symbol
			$<si>$->symbol = tmp;
			tempList5.pop_back();

			//pop the temporary variables
			for(int i = count - 1; i >= 0; i--)
			{
				$<si>$->code += "\tpop t" + to_string(i) + "\n";
			}

			//now pop back the parameters
			//first of all push all current parameters stored in tempList4 to the stack
			for(int i = tempList4.size()-1; i >= 0; i--)
			{
				$<si>$->code += "\tpop " + tempList4[i] + "\n";
			}
	 	}
	| LPAREN expression RPAREN  {
			$<si>$ = new SymbolInfo("(" + $<si>2->getName() + ")", "factor");
			//set type
			$<si>$->setDecType($<si>2->getDecType());

			$<si>$->code = $<si>2->code;
			$<si>$->symbol = $<si>2->symbol;
		}
	| CONST_INT {
			$<si>$ = new SymbolInfo($<si>1->getName(), "factor");
			//set type = int
			$<si>$->setDecType("int");

			$<si>$->symbol = $<si>1->getName();
			//string temp = newTemp();
			//$<si>$->symbol = temp;
			//$<si>$->code = "\tmov " + temp + ", " + $<si>1->getName() + "\n";
		}
	| CONST_FLOAT {
			$<si>$ = new SymbolInfo($<si>1->getName(), "factor");
			//dectype = float
			$<si>$->setDecType("float");

			$<si>$->symbol = $<si>1->getName();
			//string tp = newTemp();
			//$<si>$->symbol = tp;
			//$<si>$->code = "\tmov " + tp + ", " + $<si>1->getName() + "\n";
		}
	| variable INCOP {
			$<si>$ = new SymbolInfo($<si>1->getName() + "++", "factor");
			//set type
			$<si>$->setDecType($<si>1->getDecType());

			//code
			$<si>$->code = $<si>1->code;
			if($<si>1->isArray == 0)
			{
				string temp = newTemp();
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "\n";
				$<si>$->code += "\tmov " + temp + ", ax\n";
				$<si>$->code += "\tinc " + $<si>1->symbol + "\n";
				$<si>$->symbol = temp;
			}
			else {
				string temp = newTemp();
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "[di]\n";
				$<si>$->code += "\tmov " + temp + ", ax\n";
				$<si>$->code += "\tinc " + $<si>1->symbol + "[di]\n";
				$<si>$->symbol = temp;
			}
		}
	| variable DECOP {
			$<si>$ = new SymbolInfo($<si>1->getName() + "--", "factor");
			//set type
			$<si>$->setDecType($<si>1->getDecType());

			//code
			$<si>$->code = $<si>1->code;
			if($<si>1->isArray == 0)
			{
				string temp = newTemp();
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "\n";
				$<si>$->code += "\tmov " + temp + ", ax\n";
				$<si>$->code += "\tdec " + $<si>1->symbol + "\n";
				$<si>$->symbol = temp;
			}
			else {
				string temp = newTemp();
				$<si>$->code += "\tmov ax, " + $<si>1->symbol + "[di]\n";
				$<si>$->code += "\tmov " + temp + ", ax\n";
				$<si>$->code += "\tdec " + $<si>1->symbol + "[di]\n";
				$<si>$->symbol = temp;
			}
		}
	;
	
argument_list : arguments {
				$<si>$ = new SymbolInfo($<si>1->getName(), "argument_list");

				//code
				$<si>$->code = $<si>1->code;
			}
			| {
				$<si>$ = new SymbolInfo("", "argument_list");
			}
			;
	
arguments : arguments COMMA logic_expression {
				$<si>$ = new SymbolInfo($<si>1->getName() + "," + $<si>3->getName().c_str(), "arguments");

				//add the type to the tempList3
				//tempList3.push_back($<si>3->getDecType());
				tempList3[tempList3.size() - 1].push_back($<si>3->getDecType());

				//code
				tempList5[tempList5.size() - 1].push_back($<si>3->symbol);

				$<si>$->code = $<si>1->code + $<si>3->code;
			}
	 	| logic_expression {
				$<si>$ = new SymbolInfo($<si>1->getName(), "arguments");

				//new vector in tempList3
				vector<string> v;
				v.push_back($<si>1->getDecType());
				tempList3.push_back(v);

				//add the type to the tempList3
				//tempList3.push_back($<si>1->getDecType());

				//code
				v.pop_back();
				v.push_back($<si>1->symbol);
				tempList5.push_back(v);

				//tempList5.push_back($<si>1->symbol);

				$<si>$->code = $<si>1->code;
			}	
	    ;
 

%%

int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	errorout = fopen("log.txt","w");
	fclose(errorout);
	codeout = fopen("code.asm","w");
	fclose(codeout);
	optimized_codeout = fopen("optimized_code.asm","w");
	fclose(optimized_codeout);

	errorout = fopen("log.txt","a");
	codeout = fopen("code.asm","a");
	optimized_codeout = fopen("optimized_code.asm", "a");
	
	table = new SymbolTable(25);

	yyin = fp;
	yyparse();
	
	fclose(errorout);
	fclose(codeout);
	fclose(optimized_codeout);
	
	return 0;
}
