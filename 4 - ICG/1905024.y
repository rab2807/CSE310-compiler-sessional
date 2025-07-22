%{
#include<iostream>
#include<string>
#include<sstream>
#include<fstream>
#include<cstdlib>
#include<vector>
#include "symbol_table.h"

using namespace std;

int yyparse(void);
int yylex(void);

extern FILE* yyin;

int line_count = 1;  // NOTICE
int error_count = 0;

int scopeTable::scope_count = 1;
symbolTable st(11);

FILE* input;
ofstream log;
ofstream error;
ofstream parseTree;

string type, name;
string type_final, name_final;
vector<symbolInfo*> param_list;

void yyerror(char*);

bool declare_function(string name, string type) 
{
	symbolInfo* s1 = new symbolInfo(name, type, "FUNCTION");

	if(!param_list.empty()) {
		for(int i = 0; i < param_list.size(); i++) {
			bool flag = 0;

			for(int j = 0; j < i; j++) 
				if(param_list[i]->getName() == param_list[j]->getName()) 
				{
					error << "Line# " <<  line_count << ": "  << "Redefinition of parameter '" << param_list[i]->getName() << "'\n";
					error_count++;
					flag |= 1;
				}
			if(param_list[i]->getType() == "VOID") 
			{
				error << "Line# " <<  line_count << ": " << "Function parameter cannot be void\n";
				error_count++;
				flag |= 1;
			}

			if(flag == 0)
				s1->add_param(param_list[i]);
		}
	}

	bool success = st.insert(s1);
	if(!success) {
		symbolInfo* s2 = st.lookup(name);

		if(s2->getExtra() == "") {
			error << "Line# " <<  line_count << ": "  << "'" << name << "' redeclared as different kind of symbol\n";
			error_count++;
			delete s1;
		}
		else if(s2->getType() != type) {
			error << "Line# " <<  line_count << ": "  << "Conflicting types for '" << name << "'\n";
			error_count++;
			delete s1;
		}
		else if(*s2 == *s1) {
			success = true;
		}
		else {
			error << "Line# " <<  line_count << ": "  << "'" << name << "' parameter mismatch with previous function declaration\n";
			error_count++;
			delete s1;
		}
	}

	return success;
}

void dfs(Node* node, string offset) {
	if(node->isTerminal > 0)
		parseTree << offset << node->text << "\t<Line: "<< node->firstLine << ">\n";
	else
		parseTree << offset << node->text << "\t<Line: "<< node->firstLine << "-" << node->lastLine << ">\n";

	for(int i = 0; i < node->children.size(); i++)
		dfs((node->children)[i], offset + " ");
}

void dfsDelete(Node* node) {
	if(node && node->children.size() == 0)
		delete node;
	else {
		for(int i = 0; i < node->children.size(); i++)
			dfsDelete((node->children)[i]);
	}
}

void debugLog(vector<symbolInfo*>* v) {
	cout<<"debug: ";
	for(auto it : *v) {
		cout << it->getType() << ' ';
	}
	cout<<endl<<endl;
}
%}

%name parse
%union {
	Node* node;
}

%token <node> CONST_INT CONST_FLOAT ID MULOP INT FLOAT VOID IF ELSE FOR WHILE PRINTLN RETURN ASSIGNOP NOT 
%token <node> INCOP DECOP LOGICOP RELOP ADDOP LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON 

%type <node> start program unit var_declaration func_declaration func_definition type_specifier parameter_list statements statement arguments argument_list 
%type <node> variable expression logic_expression rel_expression simple_expression term unary_expression factor declaration_list expression_statement
%type <node> compound_statement embedded_compound embedded embedded_out

%nonassoc THEN
%nonassoc ELSE

%%

start : program { 
		log << "start : program\n";
		$$ = new Node(nullptr, "start : program ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		dfs($$, "");
	}
	;
program : program unit {
		log << "program : program unit\n";
		$$ = new Node(nullptr, "program : program unit ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	| unit { 
		log << "program : unit\n";
		$$ = new Node(nullptr, "program : unit ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	;
unit : var_declaration {
		log << "unit : var_declaration\n";
		$$ = new Node(nullptr, "unit : var_declaration ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    | func_declaration { 
		log << "unit : func_declaration\n";
		$$ = new Node(nullptr, "unit : func_declaration ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    | func_definition { 
		log << "unit : func_definition\n";
		$$ = new Node(nullptr, "unit : func_definition ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    ;
func_declaration : type_specifier ID embedded LPAREN parameter_list RPAREN embedded_out SEMICOLON {
		log << "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n";

		$$ = new Node(nullptr, "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		// $$->children.push_back($7);
		$$->children.push_back($8);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $7->lastLine;

		// declare_function($2->si->getName(), $1->si->getType());
		param_list.clear();
	}
	| type_specifier ID embedded LPAREN RPAREN embedded_out SEMICOLON {
		log << "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n";

		$$ = new Node(nullptr, "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($4);
		$$->children.push_back($5);
		// $$->children.push_back($6);
		$$->children.push_back($7);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $6->lastLine;

		declare_function($2->si->getName(), $1->si->getType());
		param_list.clear();
	}
	;
func_definition : type_specifier ID embedded LPAREN parameter_list RPAREN embedded_out compound_statement {
		log << "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n";

		$$ = new Node(nullptr, "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->children.push_back($8);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $8->lastLine;
	}
	| type_specifier ID embedded LPAREN RPAREN embedded_out compound_statement {
		log << "func_definition : type_specifier ID LPAREN RPAREN compound_statement\n";

		$$ = new Node(nullptr, "func_definition : type_specifier ID LPAREN RPAREN compound_statement ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($7);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $7->lastLine;
	}
	;	
embedded : {
		type_final = type;
		name_final = name;
	}	
	;
embedded_out : {
		declare_function(name_final, type_final);
	}
	;
parameter_list : parameter_list COMMA type_specifier ID {
		log << "parameter_list : parameter_list COMMA type_specifier ID\n";

		$$ = new Node(nullptr, "parameter_list : parameter_list COMMA type_specifier ID ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;

		$4->si->setType($3->si->getType());
		param_list.push_back(new symbolInfo($4->si));
	}
	| parameter_list COMMA type_specifier {
		log << "parameter_list : parameter_list COMMA type_specifier\n";

		$$ = new Node(nullptr, "parameter_list : parameter_list COMMA type_specifier ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		param_list.push_back(new symbolInfo("", $3->si->getType()));
	}
	| type_specifier ID {
		log << "parameter_list : type_specifier ID\n";

		$$ = new Node(nullptr, "parameter_list : type_specifier ID ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;

		$2->si->setType($1->si->getType());
		param_list.push_back(new symbolInfo($2->si));
	}
	// start of paramter list
	| type_specifier {
		log << "parameter_list : type_specifier\n";

		$$ = new Node(nullptr, "parameter_list : type_specifier ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		param_list.push_back(new symbolInfo("", $1->si->getType()));
	}
	;
compound_statement : LCURL embedded_compound statements RCURL {
		log << "compound_statement : LCURL statements RCURL\n";

		$$ = new Node(nullptr, "compound_statement : LCURL statements RCURL ");
		$$->children.push_back($1);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;

		st.printAll(log);
		st.exit();
	}
	| LCURL embedded_compound RCURL {
		log << "compound_statement : LCURL RCURL\n";

		$$ = new Node(nullptr, "compound_statement : LCURL RCURL ");
		$$->children.push_back($1);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		st.printAll(log);
		st.exit();
	}
	;
embedded_compound : {
		st.enter();
		if(!param_list.empty()) {
			for(auto it : param_list) {
				st.insert(it);
			}
			param_list.clear();
		}
	}
	;
var_declaration : type_specifier declaration_list SEMICOLON {
		log << "var_declaration : type_specifier declaration_list SEMICOLON\n";

		$$ = new Node(nullptr, "var_declaration : type_specifier declaration_list SEMICOLON ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		if($1->si->getType() == "VOID") {
			for(int i = 0; i < $2->siv->size(); i++) {
				error << "Line# " <<  line_count << ": "  << "Variable or field " << "'" << (*($2->siv))[i]->getName() << "'" <<  "declared void\n";
				error_count++;
			}
		}
		else {
			for(auto it : *($2->siv)) {
				it->setType($1->si->getType());
				bool success = st.insert(it);

				if(!success) {
					symbolInfo* s1 = st.lookup(it->getName());
					if((s1->getType() != $1->si->getType()) || (s1->getType() == $1->si->getType() && s1->getExtra() != it->getExtra())) {
						error << "Line# " <<  line_count << ": "  << "Conflicting types for '" << it->getName() << "'\n";
						error_count++;
					}
					else {
						error << "Line# " <<  line_count << ": "  << "Redeclaration of variable '" << it->getName() << "'\n";
						error_count++;
					}
				}
			}
		}
	}
	;
type_specifier : INT {
		log << "type_specifier : INT\n";

		$$ = new Node($1->si, "type_specifier : INT ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		type = $1->si->getType();
	}
	| FLOAT {
		log << "type_specifier : FLOAT\n";

		$$ = new Node($1->si, "type_specifier : FLOAT ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		type = $1->si->getType();
	}
	| VOID { 
		log << "type_specifier : VOID\n";

		$$ = new Node($1->si, "type_specifier : VOID ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		type = $1->si->getType();
	}
	;
declaration_list : declaration_list COMMA ID {
		log << "declaration_list : declaration_list COMMA ID\n";

		$$ = new Node(nullptr, "declaration_list : declaration_list COMMA ID ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		$1->siv->push_back($3->si);
		$$->siv = $1->siv;
	}
	| declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
		log << "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE\n";

		$$ = new Node(nullptr, "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $6->lastLine;

		$3->si->setExtra("ARRAY");
		$1->siv->push_back($3->si);
		$$->siv = $1->siv;
	}
	| ID {
		log << "declaration_list : ID\n";

		$$ = new Node(nullptr, "declaration_list : ID ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		$$->siv = new vector<symbolInfo*>();
		$$->siv->push_back($1->si);
	}
	// for array declaration
	// for first declaration
	| ID LSQUARE CONST_INT RSQUARE {
		log << "declaration_list : ID LSQUARE CONST_INT RSQUARE\n";

		$$ = new Node(nullptr, "declaration_list : ID LSQUARE CONST_INT RSQUARE ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;

		$1->si->setExtra("ARRAY");
		$$->siv = new vector<symbolInfo*>();
		$$->siv->push_back($1->si);
	}
	;
statements : statement {
		log << "statements : statement\n";	

		$$ = new Node(nullptr, "statements : statement ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| statements statement {
		log << "statements : statements statement\n";

		$$ = new Node(nullptr, "statements : statements statement ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	;
statement : var_declaration {
		log << "statement : var_declaration\n";

		$$ = new Node(nullptr, "statement : var_declaration ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}	
	| expression_statement {
		log << "statement : expression_statement\n";

		$$ = new Node(nullptr, "statement : expression_statement ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| compound_statement {
		log << "statement : compound_statement\n";

		$$ = new Node(nullptr, "statement : compound_statement ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
		log << "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n";

		$$ = new Node(nullptr, "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->children.push_back($7);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $7->lastLine;
	}
	| IF LPAREN expression RPAREN statement %prec THEN {
		log << "statement : IF LPAREN expression RPAREN statement %prec THEN\n";

		$$ = new Node(nullptr, "statement : IF LPAREN expression RPAREN statement ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	| IF LPAREN expression RPAREN statement ELSE statement {
		log << "statement : IF LPAREN expression RPAREN statement ELSE statement\n";

		$$ = new Node(nullptr, "statement : IF LPAREN expression RPAREN statement ELSE statement ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->children.push_back($7);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $7->lastLine;
	}
	| WHILE LPAREN expression RPAREN statement {
		log << "statement : WHILE LPAREN expression RPAREN statement\n";

		$$ = new Node(nullptr, "statement : WHILE LPAREN expression RPAREN statement ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON {
		log << "statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n";

		$$ = new Node(nullptr, "statement : PRINTLN LPAREN ID RPAREN SEMICOLON ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	| RETURN expression SEMICOLON {
		log << "statement : RETURN expression SEMICOLON\n";

		$$ = new Node(nullptr, "statement : RETURN expression SEMICOLON ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	;
expression_statement : SEMICOLON {
		log << "expression_statement : SEMICOLON\n";

		$$ = new Node(nullptr, "expression_statement : SEMICOLON ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}			
	| expression SEMICOLON {
		log << "expression_statement : expression SEMICOLON\n";

		$$ = new Node(nullptr, "expression_statement : expression SEMICOLON ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	;

variable : ID { 
		log << "variable : ID\n";

		symbolInfo* s = st.lookup($1->si->getName());

		$$ = new Node(s ? s : $1->si, "variable : ID ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		if(!s) {
			error << "Line# " <<  line_count << ": "  << "Undeclared variable '" << $1->si->getName() << "'\n";
			error_count++;
		}
	}
	| ID LSQUARE expression RSQUARE {
		log << "variable : ID LSQUARE expression RSQUARE\n";

		$$ = new Node($1->si, "variable : ID LSQUARE expression RSQUARE ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;

		symbolInfo* s = st.lookup($1->si->getName());
		if(!s) {
			error << "Line# " <<  line_count << ": "  << "Undeclared variable '" << $1->si->getName() << "'\n";
			error_count++;
		}
		else if(s && s->getExtra() != "ARRAY") {
			error << "Line# " <<  line_count << ": "  << "'" << s->getName() << "' is not an array\n";
			error_count++;
		}
		else if($3->si->getType() != "INT") {
			error << "Line# " <<  line_count << ": "  << "Array subscript is not an integer\n";
			error_count++;
		}	
	}
	;

expression : logic_expression {
		log << "expression : logic_expression\n";


		$$ = new Node($1->si, "expression : logic_expression ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| variable ASSIGNOP logic_expression {
		log << "expression : variable ASSIGNOP logic_expression\n";

		$$ = new Node($1->si, "expression : variable ASSIGNOP logic_expression ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		if($3->si->getType() == "VOID ") {
			error << "Line# " <<  line_count << ": "  << "Void cannot be used in expression\n";
			error_count++;
		}
		if($1->si->getType() == "INT" && $1->si->getType() == "FLOAT") {
			error << "Line# " <<  line_count << ": "  << "Warning: possible loss of data in assignment of FLOAT to INT\n";
			error_count++;
		}
	}	
	;

logic_expression : rel_expression { 
		log << "logic_expression : rel_expression\n";

		$$ = new Node($1->si, "logic_expression : rel_expression ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}	
	| rel_expression LOGICOP rel_expression {
		log << "logic_expression : rel_expression LOGICOP rel_expression\n";

		symbolInfo* s = new symbolInfo("logicop", "INT");
		$$ = new Node(s, "logic_expression : rel_expression LOGICOP rel_expression ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}	
	;

rel_expression : simple_expression {
		log << "rel_expression : simple_expression\n";

		$$ = new Node($1->si, "rel_expression : simple_expression ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| simple_expression RELOP simple_expression	{
		log << "rel_expression : simple_expression RELOP simple_expression\n";

		symbolInfo* s = new symbolInfo("relop", "INT");
		$$ = new Node(s, "rel_expression : simple_expression RELOP simple_expression ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	;

simple_expression : term {
		log << "simple_expression : term\n";

		$$ = new Node($1->si, "simple_expression : term ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}	
	| simple_expression ADDOP term {
		log << "simple_expression : simple_expression ADDOP term\n";

		if($1->si->getType() == "FLOAT" || $3->si->getType() == "FLOAT")
			$1->si->setType("FLOAT");

		$$ = new Node($1->si, "simple_expression : simple_expression ADDOP term ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	} 
	;

term :	unary_expression {
		log << "term : unary_expression\n";


		$$ = new Node($1->si, "term : unary_expression ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    |  term MULOP unary_expression {
		log << "term : term MULOP unary_expression\n";

		$$ = new Node($1->si, "term : term MULOP unary_expression ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		if($2->si->getName() == "%")
			if($1->si->getType() != "INT" || $3->si->getType() != "INT") {
				error << "Line# " <<  line_count << ": "  << "Operands of modulus must be integers\n";
				error_count++;
			}
		if($2->si->getName() == "%" || $2->si->getName() == "/")
			if($3->si->getName() == "0") {
				error << "Line# " <<  line_count << ": "  << "Warning: division by zero\n";
				error_count++;
			}
	}
    ;
 
unary_expression : ADDOP unary_expression {
		log << "unary_expression : ADDOP unary_expression\n";

		$$ = new Node($2->si, "unary_expression : ADDOP unary_expression ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}  
	| NOT unary_expression {
		log << "unary_expression : NOT unary_expression\n";

		$$ = new Node($2->si, "unary_expression : NOT unary_expression ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	} 
	| factor {
		log << "unary_expression : factor\n";


		$$ = new Node($1->si, "unary_expression : factor ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	} 
	;
	
factor : variable {
		log << "factor : variable\n";


		$$ = new Node($1->si, "factor : variable ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| ID LPAREN argument_list RPAREN { // function call
		log << "factor : ID LPAREN argument_list RPAREN\n";

		$$ = new Node($1->si, "factor : ID LPAREN argument_list RPAREN ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;

		symbolInfo* s = st.lookup($1->si->getName());
		if(!s) {
			error << "Line# " <<  line_count << ": "  << "Undeclared function '" << $1->si->getName() << "'\n";
			error_count++;
		}
		else if(s->getExtra() != "FUNCTION") {
			error << "Line# " <<  line_count << ": "  << "'" << s->getName() << "' is not a function\n";
			error_count++;
		}
		else if(s->get_params_length() > $3->siv->size()) {
			error << "Line# " <<  line_count << ": "  << "Too few arguments to function '" << s->getName() << "'\n";
			error_count++;
		}
		else if(s->get_params_length() < $3->siv->size()) {
			error << "Line# " <<  line_count << ": "  << "Too many arguments to function '" << s->getName() << "'\n";
			error_count++;
		} 
		else {
			auto v1 = s->getParams();
			auto v2 = *($3->siv);

			for(int i = 0; i < v1.size(); i++) {
				if(v1[i]->getType() != v2[i]->getType()) {
					error << "Line# " <<  line_count << ": "  << "Type mismatch for argument " << (i+1) << " of '" << s->getName() << "'\n";
					error_count++;
				}
			}
		}
	}
	| LPAREN expression RPAREN {
		log << "factor : LPAREN expression RPAREN\n";

		$$ = new Node($2->si, "factor : LPAREN expression RPAREN ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	| CONST_INT { // terminal
		log << "factor : CONST_INT\n";

		symbolInfo* s = new symbolInfo($1->si->getName(), "INT");
		$$ = new Node(s, "factor : CONST_INT ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| CONST_FLOAT { // terminal
		log << "factor : CONST_FLOAT\n";

		symbolInfo* s = new symbolInfo($1->si->getName(), "FLOAT");
		$$ = new Node(s, "factor : CONST_FLOAT ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| variable INCOP {
		log << "factor : variable INCOP\n";

		$$ = new Node($1->si, "factor : variable INCOP ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	| variable DECOP {
		log << "factor : variable DECOP\n";

		$$ = new Node($1->si, "factor : variable DECOP ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	;	
argument_list : arguments {
		log << "argument_list : arguments\n";

		$$ = new Node($1->si, "argument_list : arguments ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		$$->siv = $1->siv;	
	}
	| //empty 
	{
		$$->siv = new vector<symbolInfo*>(); 
	}
	;
arguments : arguments COMMA logic_expression {
		log << "arguments : arguments COMMA logic_expression\n";

		$$ = new Node(nullptr, "arguments : arguments COMMA logic_expression ");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		$1->siv->push_back($3->si);
		$$->siv = $1->siv;
	}
	| logic_expression {
		log << "arguments : logic_expression\n";

		$$ = new Node(nullptr, "arguments : logic_expression ");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		$$->siv = new vector<symbolInfo*>();
		$$->siv->push_back($1->si);
	}
	;
%%

int main(int argc, char* argv[]) {
	if(argc != 2) {
		cout << "input file name not provided, terminating program..." << endl;
		return 0;
	}

    input = fopen(argv[1], "r");

    if(input == NULL) {
		cout << "input file not opened properly, terminating program..." << endl;
		exit(EXIT_FAILURE);
	}

	log.open("1905024_out_log.txt", ios::out);
	error.open("1905024_out_error.txt", ios::out);
	parseTree.open("1905024_out_parsetree.txt", ios::out);
	
	if(log.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
	
	if(error.is_open() != true) {
		cout << "error file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
	
    if(parseTree.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
	
	yyin = input;
    yyparse();

	log << "Total Lines: " << line_count << endl;  
	log << "Total Errors: " << error_count << endl;
    error << "Total Errors: " << error_count << endl;
	
	fclose(yyin);
	log.close();
	error.close();
	parseTree.close();
	
	return 0;
} 

void yyerror(char* s) {
    log << "At line no: " << line_count << " " << s << endl;

    line_count++;
    error_count++;
    
    return ;
}
