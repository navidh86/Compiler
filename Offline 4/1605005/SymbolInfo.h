#include<bits/stdc++.h>
#include"funcInfo.h"

using namespace std;

class SymbolInfo {

    string name, type, decType = "void";
    int arraySize = 0;

public:
    SymbolInfo* next;
    bool isArray = 0, isFunc = 0;
    funcInfo fi;
    string code = "";
    string symbol = "";

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

    void makeArray()
    {
        isArray = 1;
    }

    void makeFunc()
    {
        isFunc = 1;
    }

    void setName(string name)
    {
        this->name = name;
    }

    void setType(string type)
    {
        this->type = type;
    }

    void setDecType(string decType)
    {
        this->decType = decType;
    }

    string getName()
    {
        return name;
    }

    string getType()
    {
        return type;
    }

    string getDecType()
    {
        return decType;
    }

    void setSymbol(string symbol) 
    {
        this->symbol = symbol;
    }

    string getSymbol() 
    {
        return symbol;
    }

    void setArraySize(int as)
    {
        arraySize = as;
    }

    int getArraySize()
    {
        return arraySize;
    }
};
