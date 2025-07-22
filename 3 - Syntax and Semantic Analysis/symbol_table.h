#include <iostream>
#include <fstream>
#include <cstring>
#include <vector>
using namespace std;

class symbolInfo
{
    string name, type, extra;
    symbolInfo *next;
    vector<symbolInfo *> params;

public:
    bool global = false;
    int offset;
    int arrSize;
    string label = "";
    string labelHeading = "";

    symbolInfo(string name, string type, string extra = "")
    {
        this->name = name;
        this->type = type;
        this->extra = extra;
        next = nullptr;
    }


    symbolInfo(symbolInfo *si)
    {
        this->name = si->name;
        this->type = si->type;
        this->extra = si->extra;
        next = nullptr;
    }

    string getName()
    {
        return name;
    }

    string getType()
    {
        return type;
    }

    string getExtra()
    {
        return extra;
    }

    void setExtra(string s)
    {
        extra = s;
    }

    void setType(string s)
    {
        type = s;
    }

    void setNext(symbolInfo *s)
    {
        next = s;
    }

    vector<symbolInfo *> &getParams()
    {
        return params;
    }

    int get_params_length()
    {
        return params.size();
    }

    void add_param(symbolInfo *s)
    {
        params.push_back(s);
    }

    symbolInfo *getNext()
    {
        return this->next;
    }

    bool operator==(symbolInfo const &obj)
    {
        if (obj.name != name)
            return false;
        if (obj.type != type)
            return false;
        if (obj.params.size() != params.size()) 
            return false;
        for (int i = 0; i < params.size(); i++)
            if (obj.params[i]->type != params[i]->type)
                return false;
        return true;
    }

    friend ostream& operator<<(ostream& os, symbolInfo &s)
    {
        os << "[" << s.name << "," << s.type << "]";
        return os;
    }

    friend ostream& operator<<(ostream& os, symbolInfo* s)
    {
        os << "[" << s->name << "," << s->type << "]";
        return os;
    }
};

class scopeTable
{
    static int scope_count;
    int scope_num;
    int num_bucket;
    symbolInfo **arr;
    scopeTable *par;

    long long int SDBMHash(string str)
    {
        long long int hash = 0;
        long long int i = 0;
        long long int len = str.length();

        for (i = 0; i < len; i++)
        {
            hash = ((str[i]) + (hash << 6) + (hash << 16) - hash);
        }

        return abs(hash);
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
    }

    ~scopeTable()
    {
        for (int i = 0; i < num_bucket; i++)
        {
            if (arr[i])
                freeLinkedList(arr[i]);
        }
        delete[] arr;
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
            // printf("\tInserted in ScopeTable# %d at position %d, %d\n", scope_num, index + 1, 1);
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
            return false;
        }

        itr->setNext(s);
        // printf("\tInserted in ScopeTable# %d at position %d, %d\n", scope_num, index + 1, i);
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
            // printf("\tNot found in the current ScopeTable\n");
            return false;
        }

        if (itr->getName() == name)
        {
            arr[index] = nullptr;
            // cout << "\tDeleted '" << name;
            // printf("' from ScopeTable# %d at position %d, %d\n", scope_num, index + 1, 1);
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
                // printf("' from ScopeTable# %d at position %d, %d\n", scope_num, index + 1, i);
                return true;
            }
            itr = itr->getNext();
            i++;
        }
        // printf("\tNot found in the current ScopeTable\n");
        return false;
    }

    void print(ofstream &out)
    {
        out << "\tScopeTable# " << scope_num << endl;
        for (int i = 0; i < num_bucket; i++)
        {
            symbolInfo *itr = arr[i];

            if (itr == NULL)
                continue;
            out << "\t" << i + 1 << "--> ";
            while (itr) 
            {
                if (itr->getExtra() == "")
                    out << '<' << itr->getName() << ", " << itr->getType() << "> ";
                else
                    out << '<' << itr->getName() << ", " << itr->getExtra() << ", " << itr->getType() << "> ";

                // for(auto it : itr->getParams())
                //     out << "[" << it->getName() << "," << it->getType() << "] ";

                itr = itr->getNext();
            }
            out << '\n';
        }
    }
};

class symbolTable
{
    scopeTable *curr;
    int num;

public:
    symbolTable(int num)
    {
        this->num = num;
        curr = new scopeTable(num);
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
    }

    void exit()
    {
        if (curr->getParent() == nullptr)
        {
            return;
        }
        scopeTable *t = curr;
        curr = curr->getParent();
        delete t;
    }

    bool insert(string name, string type, string extra = "")
    {
        symbolInfo *val;
        if (extra != "")
            val = new symbolInfo(name, type, extra);
        else
            val = new symbolInfo(name, type);
        return curr->insert(val);
    }

    bool insert(symbolInfo* s)
    {
        return curr->insert(s);
    }

    bool remove(string name)
    {
        return curr->remove(name);
    }

    symbolInfo *lookupCurrent(string name)
    {
        scopeTable *itr = curr;
            symbolInfo *s = itr->lookup(name);
            if (s)
                return s;
        // cout << "\t'" << name << "' not found in any of the ScopeTables\n";
        return nullptr;
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

    void printCurrent(ofstream &out)
    {
        curr->print(out);
    }

    void printAll(ofstream &out)
    {
        scopeTable *itr = curr;
        while (itr)
        {
            itr->print(out);
            itr = itr->getParent();
        }
    }
};

class Node {
public:
	symbolInfo* si;
    vector<symbolInfo *>* siv;
    string text;
    vector<Node*> children;
    int firstLine, lastLine;
    int isTerminal;

    Node(symbolInfo* si, string text) {
		this->si = si;
        this->text = text;
        siv = nullptr;
        isTerminal = 0;
    }

    ~Node() {
        delete si;
    }
};
