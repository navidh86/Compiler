#include<bits/stdc++.h>
#include"ScopeTable.h"

using namespace std;

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
	   return currentScope->Insert((new SymbolInfo(name, type)));
    }
	
    bool Insert(SymbolInfo* si)
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

    SymbolInfo* LookUpCurrentScope(string key)
    {
        SymbolInfo* result = 0;
        result = currentScope->LookUp(key);

        return result;
    }

    void printCurrent(FILE* file)
    {
        currentScope->printTable(file);
    }

    void printAll(FILE* file)
    {
        ScopeTable* temp = currentScope;
        while(temp != 0)
        {
            temp->printTable(file);
            temp = temp->parentScope;
        }
    }

    string getCurrentScopeNumber() 
    {
        
    }
};
