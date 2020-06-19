#include<bits/stdc++.h>
#include"SymbolInfo.h"

using namespace std;

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
        //totalTables--;
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

    bool Insert(SymbolInfo* si)
    {
        int idx = hashFunction(si->getName());
        SymbolInfo *temp = table[idx], *prev = 0;
        int position = 0;

        while(temp)
        {
            if(temp->getName() == si->getName())
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

        temp = new SymbolInfo(si->getName(), si->getType());

        //copy other attributes as well
        temp->isArray = si->isArray;
        if(temp->isArray)
            temp->setArraySize(si->getArraySize());

        temp->isFunc = si->isFunc;
        if(temp->isFunc)
            temp->fi = si->fi;

        temp->setDecType(si->getDecType());
        temp->code = si->code;
        temp->symbol = si->symbol;

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

    void printTable(FILE* file)
    {
    	fprintf(file, "\nScopeTable# %d\n",this->id);

        for(int i=0; i<size; i++)
        {
    	    if(table[i] == 0)
    		continue;
    	    fprintf(file, "%d --> ", i);
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
        	    fprintf(file, "<%s, %s> ", name, type);
                temp = temp->next;
            }

            fprintf(file,"\n");
        }

        fprintf(file,"\n");
    }
};
