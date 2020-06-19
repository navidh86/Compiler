#include<bits/stdc++.h>

using namespace std;

class variableInfo {
	string decType;
	string name;

public:
	variableInfo(string decType, string name)
	{
		this->decType = decType;
		this->name = name;
	}

	string getDecType()
	{
		return decType;
	}

	string getName()
	{
		return name;
	}
};

class funcInfo {
    string returnType;
    vector<variableInfo> parameters;
    bool isDeclared = 0, isDefined = 0;

public:
    vector<string> parameterSymbols;

    void setReturnType(string rt)
    {
    	returnType = rt;
    }

    string getReturnType()
    {
    	return returnType;
    }

    void addItem(string decType, string name)
    {
    	parameters.push_back(*(new variableInfo(decType, name)));
    }

    void addItem(variableInfo vi)
    {
    	addItem(vi.getDecType(), vi.getName());
    }

    variableInfo getItem(int idx)
    {
    	return parameters[idx];
    }

    void makeDeclared()
    {
    	isDeclared = 1;
    }

    bool getIsDeclared()
    {
    	return isDeclared;
    }

    void makeDefined()
    {
    	isDefined = 1;
    }

    bool getIsDefined()
    {
    	return isDefined;
    }

    int getListSize()
    {
    	return parameters.size();
    }
};