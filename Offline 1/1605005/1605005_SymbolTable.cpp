#include <bits/stdc++.h>

using namespace std;

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
        cout<<endl<<"New ScopeTable with id "<<id<<" created"<<endl;
    }

    ~ScopeTable()
    {
        cout<<endl<<"ScopeTable with id "<<id<<" removed"<<endl;
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

        if(temp)
            cout<<endl<<"Found in ScopeTable# "<<id<<" at position "<<idx<<", "<<position<<endl;
        else cout<<endl<<"Not Found"<<endl;

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
                cout<<endl<<"Entry already exists"<<endl;
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

        cout<<endl<<"Inserted in ScopeTable #"<<id<<" at position "<<idx<<", "<<position<<endl;
        return true;
    }

    bool Delete(string key)
    {
        SymbolInfo* temp = LookUp(key);

        if(!temp)
        {
            cout<<endl<<key<<" not found"<<endl;
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

        cout<<endl<<"Deleted entry at "<<idx<<", "<<position<<" from current ScopeTable"<<endl;

        return true;
    }

    void printTable()
    {
        cout<<endl<<"ScopeTable# "<<this->id<<endl;
        for(int i=0; i<size; i++)
        {
            cout<<i<<" --> ";
            SymbolInfo* temp = table[i];
            while(temp)
            {
                cout<<"< "<<temp->getName()<<" : "<<temp->getType()<<" >   ";
                temp = temp->next;
            }
            cout<<endl;
        }
        cout<<endl;
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

int main()
{
    freopen("input.txt", "r", stdin);
    //freopen("output.txt", "w", stdout);
    int size;
    cin>>size;
    SymbolTable* st = new SymbolTable(size);

    string command;
    while(cin>>command)
    {
        cout<<endl<<command<<" ";

        if(command == "I")
        {
            string name, type;
            cin>>name>>type;
            cout<<name<<" "<<type<<endl;
            st->Insert(*(new SymbolInfo(name, type)));
        }
        else if(command == "L")
        {
            string key;
            cin>>key;
            cout<<key<<endl;
            st->LookUp(key);
        }
        else if(command == "D")
        {
            string key;
            cin>>key;
            cout<<key<<endl;
            st->Remove(key);
        }
        else if(command == "P")
        {
            string type;
            cin>>type;
            cout<<type<<endl;
            if(type == "A")
                st->printAll();
            else if(type == "C")
                st->printCurrent();
        }
        else if(command == "S")
        {
            cout<<endl;
            st->enterScope();
        }
        else if(command == "E")
        {
            cout<<endl;
            st->exitScope();
        }
    }
}
