#include <iostream>
#include <cstring>
using namespace std;

class symbolInfo
{
    string name, type;
    symbolInfo *next;

public:
    symbolInfo(string name, string type)
    {
        this->name = name;
        this->type = type;
        next = nullptr;
    }

    string getName()
    {
        return name;
    }

    void setNext(symbolInfo *s)
    {
        next = s;
    }

    string getType()
    {
        return type;
    }

    symbolInfo *getNext()
    {
        return this->next;
    }
};

class scopeTable
{
    static int scope_count;
    int scope_num;
    int num_bucket;
    symbolInfo **arr;
    scopeTable *par;

    unsigned int SDBMHash(string str)
    {
        unsigned int hash = 0;
        unsigned int i = 0;
        unsigned int len = str.length();

        for (i = 0; i < len; i++)
        {
            hash = ((str[i]) + (hash << 6) + (hash << 16) - hash);
        }

        return hash;
    }

    void freeLinkedList(symbolInfo *s)
    {
        if (s->getNext() == nullptr)
        {
            delete s;
            s = nullptr;
        }
        else
            freeLinkedList(s->getNext());
    }

public:
    scopeTable(int num)
    {
        scope_num = scope_count++;
        num_bucket = num;
        arr = new symbolInfo *[num_bucket];
        for (int i = 0; i < num_bucket; i++)
            arr[i] = nullptr;
        par = nullptr;
        //printf("\tScopeTable# %d created\n", scope_num);
    }

    ~scopeTable()
    {
        for (int i = 0; i < num_bucket; i++)
        {
            if (arr[i])
                freeLinkedList(arr[i]);
        }
        delete[] arr;
        //printf("\tScopeTable# %d removed\n", scope_num);
    }

    scopeTable *getParent()
    {
        return par;
    }

    void setParent(scopeTable *s)
    {
        par = s;
    }

    bool insert(symbolInfo *s)
    {
        int index = SDBMHash(s->getName()) % num_bucket;

        symbolInfo *itr = arr[index];
        if (itr == nullptr)
        {
            arr[index] = s;
            //printf("\tInserted in ScopeTable# %d at position %d, %d\n", scope_num, index + 1, 1);
            return true;
        }

        int i = 2;
        bool copyFlag = 0;
        while (itr->getNext() != nullptr)
        {
            copyFlag |= (itr->getName() == s->getName());
            itr = itr->getNext();
            i++;
        }
        copyFlag |= (itr->getName() == s->getName());

        if (copyFlag)
        {
            cout << "\t" << s->getName();
            printf(" already exists in the current ScopeTable\n");
            return false;
        }

        itr->setNext(s);
        //printf("\tInserted in ScopeTable# %d at position %d, %d\n", scope_num, index + 1, i);
        return true;
    }

    symbolInfo *lookup(string name)
    {
        int index = SDBMHash(name) % num_bucket;

        symbolInfo *itr = arr[index];
        int i = 1;
        while (itr)
        {
            if (name == itr->getName())
            {
                // cout << "\t'" << name;
                //printf("' found in ScopeTable# %d at position %d, %d\n", scope_num, index + 1, i);
                return itr;
            }
            itr = itr->getNext();
            i++;
        }
        return nullptr;
    }

    bool remove(string name)
    {
        int index = SDBMHash(name) % num_bucket;

        symbolInfo *itr = arr[index];
        if (itr == nullptr)
        {
            //printf("\tNot found in the current ScopeTable\n");
            return false;
        }

        if (itr->getName() == name)
        {
            arr[index] = nullptr;
            // cout << "\tDeleted '" << name;
            //printf("' from ScopeTable# %d at position %d, %d\n", scope_num, index + 1, 1);
            return true;
        }

        int i = 2;
        while (itr->getNext())
        {
            if (itr->getNext()->getName() == name)
            {
                symbolInfo *t = itr->getNext();
                itr->setNext(t->getNext());
                t->setNext(nullptr);
                delete t;
                // cout << "\tDeleted '" << name;
                //printf("' from ScopeTable# %d at position %d, %d\n", scope_num, index + 1, i);
                return true;
            }
            itr = itr->getNext();
            i++;
        }
        //printf("\tNot found in the current ScopeTable\n");
        return false;
    }

    void print()
    {
        cout << "\tScopeTable# " << scope_num << endl;
        for (int i = 0; i < num_bucket; i++)
        {
            symbolInfo *itr = arr[i];
            if(!itr) continue;
            cout << "\t" << i + 1 << "--> ";
            while (itr)
            {
                cout << '<' << itr->getName() << ',' << itr->getType() << "> ";
                itr = itr->getNext();
            }
            cout << '\n';
        }
    }
};

int scopeTable::scope_count = 1;

class symbolTable
{
    scopeTable *curr;
    int num;
    int count;

public:
    symbolTable(int num)
    {
        this->num = num;
        curr = new scopeTable(num);
        count = 1;
    }

    ~symbolTable()
    {
        do
        {
            scopeTable *t = curr->getParent();
            delete curr;
            curr = t;
        } while (curr);
    }

    void enter()
    {
        scopeTable *st = new scopeTable(num);
        st->setParent(curr);
        curr = st;
        count++;
    }

    void exit()
    {
        if (curr->getParent() == nullptr)
        {
            //printf("\tScopeTable# 1 cannot be removed\n");
            return;
        }
        scopeTable *t = curr;
        curr = curr->getParent();
        delete t;
        count--;
    }

    bool insert(string name, string type)
    {
        symbolInfo *val = new symbolInfo(name, type);
        return curr->insert(val);
    }

    bool remove(string name)
    {
        return curr->remove(name);
    }

    symbolInfo *lookup(string name)
    {
        scopeTable *itr = curr;
        while (itr != nullptr)
        {
            symbolInfo *s = itr->lookup(name);
            if (s)
                return s;
            itr = itr->getParent();
        }
        // cout << "\t'" << name << "' not found in any of the ScopeTables\n";
        return nullptr;
    }

    void printCurrent()
    {
        curr->print();
    }

    void printAll()
    {
        scopeTable *itr = curr;
        while (itr)
        {
            itr->print();
            itr = itr->getParent();
        }
    }
};

int takeInput(char str[], string arr[])
{
    char *token = strtok(str, " ");

    int cnt = 0;
    while (token != NULL)
    {
        if (cnt < 4)
            arr[cnt] = token;
        token = strtok(NULL, " ");
        cnt++;
    }
    return cnt;
}