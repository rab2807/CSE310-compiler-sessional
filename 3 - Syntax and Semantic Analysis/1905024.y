%{
#include<iostream>
#include<string>
#include<sstream>
#include<fstream>
#include<cstdlib>
#include<vector>
#include<stack>
#include<utility>
#include "symbol_table.h"

using namespace std;

int yyparse(void);
int yylex(void);

extern FILE* yyin;

int line_count = 1;  
int error_count = 0;

int scopeTable::scope_count = 1;
symbolTable st(11);

FILE* input;
ofstream code;
ofstream error;
ofstream parseTree;

bool global_variable_flag = true;
bool inside_main = false;
int label_count = 0;
int params_num = 0;
int local_var_num = 0;
string func_end;

void yyerror(char*);

string newLabel() 
{
	string s = "L" + to_string(label_count);
	label_count++;
	return s;
}

string getVariable(string name, int index = -1)
{
	symbolInfo * s = st.lookup(name);

	if(s->global) {
		return name;
	}
	string sign = s->offset > 0 ? "+" : "";
	string str = "[BP" + sign + to_string(s->offset) + "]";
	return str;
}

string relopToJumpIns(string relop){
    if(relop == "<") return "JL";
    if(relop == "<=") return "JLE";
    if(relop == ">") return "JG";
    if(relop == ">=") return "JGE";
    if(relop == "==") return "JE";
    if(relop == "!=") return "JNE";
}

void dfs(Node* node, string offset, int level) {
	
	
	
	
	if(node->si && node->si->labelHeading != "") 
	{
		code << "\t" << node->si->labelHeading << ":\n";
		node->si->labelHeading = "";
	}
	if(node->text == "ELSE : else")
	{
		code << "\t" << node->si->label << ":\n";
	}
	else if(node->text == " start : program")
	{
		code << ".MODEL SMALL\n.STACK 100H\n";
		code << ".DATA\n\tCR EQU 0DH\n\tLF EQU 0AH\n\tnumber DB \"00000$\"\n";
	}
	else if(node->text == "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" ||
		node->text == "func_definition : type_specifier ID LPAREN RPAREN compound_statement")
	{
		symbolInfo* s = (node->children[1])->si;
		s->setExtra("FUNCTION");

		code << s->getName() << " " << "PROC\n";
		if(s->getName() == "main") {
			code << "\tMOV AX, @DATA\n\tMOV DS, AX\n";
			inside_main = true;
		}

		st.enter();
		global_variable_flag = false;
		func_end = newLabel();

		code << "\tPUSH BP\n\tMOV BP, SP\n";
	}
	else if(node->text == "statement : IF LPAREN expression RPAREN statement")
	{
		code << "\t; line " << node->firstLine << " start if\n";
		string endLabel = newLabel();
		(node->children[0])->si->label = endLabel;
		(node->children[2])->si->label = endLabel;
	}
	else if(node->text == "statement : IF LPAREN expression RPAREN statement ELSE statement")
	{
		code << "\t; line " << node->firstLine << " start if-else\n";
		string endLabel = newLabel();
		string falseLabel = newLabel();
		(node->children[0])->si->label = endLabel;
		(node->children[2])->si->label = falseLabel;
		(node->children[4])->si->label = endLabel;
		(node->children[5])->si->label = falseLabel;
	}
	else if(node->text == "statement : WHILE LPAREN expression RPAREN statement")
	{
		code << "\t; line " << node->firstLine << " start while\n";
		string beginLabel = newLabel();
		string endLabel = newLabel();
		code << "\t" << beginLabel << ":\n";
		(node->children[0])->si->label = endLabel;
		(node->children[2])->si->label = endLabel;
		(node->children[4])->si->label = beginLabel;
	}
	else if(node->text == "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement")
	{
		code << "\t; line " << node->firstLine << " start for\n";
		string conditionLabel = newLabel();
		string statementLabel = newLabel();
		string incrementLabel = newLabel();
		string endLabel = newLabel();

		(node->children[0])->si->label = endLabel;
		(node->children[3])->si->label = statementLabel + "," + endLabel;
		(node->children[4])->si->label = "f" + conditionLabel;
		(node->children[6])->si->label = incrementLabel;

		(node->children[3])->si->labelHeading = conditionLabel;
		(node->children[4])->si->labelHeading = incrementLabel;
		(node->children[6])->si->labelHeading = statementLabel;
	}
	else if(node->text == "statement : PRINTLN LPAREN ID RPAREN SEMICOLON") 
	{
		code << "\t; line " << node->firstLine << " print value\n";
		code << "\tMOV AX, " << getVariable((node->children)[2]->si->getName()) << endl;
		code << "\tCALL print_output\n";
		code << "\tCALL new_line\n";
	}


	for(int i = 0; i < node->children.size(); i++)
		dfs((node->children)[i], offset + " ", level + 1);



	if(node->text == " start : program")
	{
		code << "\nnew_line proc\n"
			<< "\tpush ax\n"
			<< "\tpush dx\n"
			<< "\tmov ah,2\n"
			<< "\tmov dl,cr\n"
			<< "\tint 21h\n"
			<< "\tmov ah,2\n"
			<< "\tmov dl,lf\n"
			<< "\tint 21h\n"
			<< "\tpop dx\n"
			<< "\tpop ax\n"
			<< "\tret\n"
		<< "new_line endp\n"
		<< "print_output proc  ;print what is in ax\n"
			<< "\tpush ax\n"
			<< "\tpush bx\n"
			<< "\tpush cx\n"
			<< "\tpush dx\n"
			<< "\tpush si\n"
			<< "\tlea si,number\n"
			<< "\tmov bx,10\n"
			<< "\tadd si,4\n"
			<< "\tcmp ax,0\n"
			<< "\tjnge negate\n"
			<< "\tprint:\n"
			<< "\txor dx,dx\n"
			<< "\tdiv bx\n"
			<< "\tmov [si],dl\n"
			<< "\tadd [si],'0'\n"
			<< "\tdec si\n"
			<< "\tcmp ax,0\n"
			<< "\tjne print\n"
			<< "\tinc si\n"
			<< "\tlea dx,si\n"
			<< "\tmov ah,9\n"
			<< "\tint 21h\n"
			<< "\tpop si\n"
			<< "\tpop dx\n"
			<< "\tpop cx\n"
			<< "\tpop bx\n"
			<< "\tpop ax\n"
			<< "\tret\n"
			<< "\tnegate:\n"
			<< "\tpush ax\n"
			<< "\tmov ah,2\n"
			<< "\tmov dl,'-'\n"
			<< "\tint 21h\n"
			<< "\tpop ax\n"
			<< "\tneg ax\n"
			<< "\tjmp print\n"
		<< "print_output endp\n\n";
		code << "END main\n";
	}
	else if(node->text == "var_declaration : type_specifier declaration_list SEMICOLON")
	{
		vector<symbolInfo*> v = *((node->children[1])->siv);

		if(global_variable_flag) {
			for(auto it : v) {
				it->global = true;
				st.insert(it);
				if(it->getExtra() != "ARRAY")
					code << "\t" << it->getName() << " DW " << 1 <<endl;
				else
					code << "\t" << it->getName() << " DW " << it->arrSize << " DUP (0)" << endl;
			}
		}
		else {
			int cnt = 1;
			for(auto it : v) {
				it->global = false;
				it->offset = -2 * cnt++;
				st.insert(it);
			}

			local_var_num = cnt - 1;
			code << "\t; line " << node->firstLine << " variable declaration\n";
			code << "\tSUB SP, " << local_var_num * 2 << endl;
		}
	}
	else if(node->text == "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"
		|| node->text == "func_definition : type_specifier ID LPAREN RPAREN compound_statement")
	{
		code << "\t" << func_end << ":\n";
		code << "\tADD SP, " << local_var_num * 2 << endl;
		code << "\tPOP BP\n";
		
		if(inside_main)
			code << "\tMOV AX, 4CH\n\tINT 21H\n";
		else 
			code << "\tRET " << params_num * 2 << endl;

		code << (node->children[1])->si->getName() << " " << "ENDP\n";

		global_variable_flag = true;
		inside_main = false;
		params_num = local_var_num = 0;
		st.exit();
	}
	else if(node->text == "parameter_list : parameter_list COMMA type_specifier ID" || node->text == "parameter_list : type_specifier ID") 
	{
		vector<symbolInfo*> v = *(node->siv);
		params_num = v.size();
		int n = 2 + params_num * 2;
		int cnt = 0;
	
		for(auto it : v) {
			it->global = false;
			it->offset = n - 2 * cnt++;
			st.insert(it);
		}
	}
	else if(node->text == "factor : ID LPAREN argument_list RPAREN")
	{
		code << "\tCALL " << (node->children[0])->si->getName() << endl;
		code << "\tPUSH AX\n";
	}
	else if(node->text == "factor : CONST_INT")
	{
		code << "\tPUSH " << (node->children)[0]->si->getName() << endl;
	}
	else if(node->text == "factor : variable")
	{
		Node* n = (node->children)[0];
		if((n->children).size() == 1)
			code << "\tPUSH " << getVariable((node->children)[0]->si->getName()) << endl;
		else
		{
			code << "\tPOP AX\n";
			code << "\tSHL AX, 1\n";
			code << "\tLEA SI, " << getVariable((node->children)[0]->si->getName()) << endl;
			code << "\tADD SI, AX\n";
			code << "\tPUSH [SI]\n";
		}
	}
	else if(node->text == "factor : variable INCOP" || node->text == "factor : variable DECOP")
	{
		symbolInfo * s = st.lookup((node->children)[0]->si->getName());

		string op = (node->children)[1]->si->getName() == "++" ? "INC" : "DEC";
		code << "\tPUSH " << getVariable((node->children)[0]->si->getName()) << endl;
		code << "\t" << op << " " << getVariable((node->children)[0]->si->getName()) << endl;
	}
	else if(node->text == "unary_expression : ADDOP unary_expression")
	{
		if((node->children)[0]->si->getName() == "-") {
			code << "\tPOP AX\n" << "\tNEG AX\n" << "\tPUSH AX\n";
		}
	}
	else if(node->text == "unary_expression : NOT unary_expression")
	{
		code << "\t; line " << node->firstLine << " NOT\n";

		string trueLabel = newLabel();
		string endLabel = newLabel();
		string op = relopToJumpIns((node->children)[1]->si->getName());

		code << "\tPOP AX\n";
		code << "\tCMP AX, 0\n";
		code << "JE " << trueLabel << endl;
		code << "\tPUSH 0\n\tJMP " << endLabel << endl;
		code << "\t" << trueLabel << ":\n";
		code << "\tPUSH 1\n";
		code << "\t" << endLabel << ":\n";
	}
	else if(node->text == "term : term MULOP unary_expression")
	{
		code << "\t; line " << node->firstLine << " MULOP\n";

		string sign = (node->children)[1]->si->getName();
		code << "\tPOP BX\n";
		code << "\tPOP AX\n";
		code << "\tXOR DX, DX\n";
		string op = sign == "*" ? "IMUL" : "IDIV";
		code << "\t" << op << " BX\n"; 
		string result = sign == "%" ? "DX" : "AX";
		code << "\tPUSH " << result << endl;
	}
	else if(node->text == "simple_expression : simple_expression ADDOP term")
	{
		code << "\t; line " << node->firstLine << " ADDOP\n";

		string sign = (node->children)[1]->si->getName();
		code << "\tPOP BX\n";
		code << "\tPOP AX\n";
		string op = sign == "+" ? "ADD" : "SUB";
		code << "\t" << op << " AX, BX\n";
		code << "\tPUSH AX\n";
	}
	else if(node->text == "rel_expression : simple_expression RELOP simple_expression")
	{
		code << "\t; line " << node->firstLine << " RELOP\n";

		string trueLabel = newLabel();
		string endLabel = newLabel();
		string op = relopToJumpIns((node->children)[1]->si->getName());

		code << "\tPOP BX\n";
		code << "\tPOP AX\n";
		code << "\tCMP AX, BX\n";
		code << "\t" << op << " " << trueLabel << endl;
		code << "\tPUSH 0\n\tJMP " << endLabel << endl;
		code << "\t" << trueLabel << ":\n\t\tPUSH 1" << endl;
		code << "\t" << endLabel << ":\n";
	}
	else if(node->text == "logic_expression : rel_expression LOGICOP rel_expression")
	{
		code << "\t; line " << node->firstLine << " LOGICOP\n";
		
		string logicop = (node->children)[1]->si->getName();
		string boolVal = logicop == "&&" ? "1" : "0";
		string jmpLabel = newLabel();
		string endLabel = newLabel();

		code << "\tPOP AX\n";
		code << "\tCMP AX, " << boolVal <<endl;
		code << "JNE " << jmpLabel << endl;
		code << "\tPOP AX\n";
		code << "\tCMP AX, " << boolVal <<endl;
		code << "\tJNE " << jmpLabel << endl;
		code << "\tPUSH " << boolVal <<endl;
		code << "\tJMP " << endLabel << endl;
		boolVal = logicop == "||" ? "1" : "0";
		code << "\t" << jmpLabel << ":\n";
		code << "\t\tPUSH " << boolVal << endl;
		code << "\t" << endLabel << ":\n";
	}
	else if(node->text == "expression : variable ASSIGNOP logic_expression")
	{
		Node* n = (node->children)[0];

		if((n->children).size() == 1) 
		{
			code << "\tPOP AX\n";
			code << "\tMOV " << getVariable((node->children)[0]->si->getName()) << ", AX\n";
			code << "\tPUSH AX\n";
		}
		else
		{
			code << "\tPOP AX\n";
			code << "\tPOP BX\n";
			code << "\tSHL BX, 1\n";
			code << "\tLEA SI, " << getVariable((node->children)[0]->si->getName()) << endl;
			code << "\tADD SI, BX\n";
			code << "\tMOV [SI], AX\n";
			code << "\tPUSH AX\n";
		}
	}
	else if(node->text == "expression : logic_expression") 
	{
		if(node->si->label != "")
		{
			if(node->si->label[0] == 'f') {
				code << "\tPOP AX\n";
				code << "\tJMP " << (node->si->label).substr(1) << endl;
			}
			else {
				code << "\tPOP AX\n";
				code << "\tCMP AX, 0\n";
				code << "\tJE " << node->si->label << endl;
			}
		}
	}
	else if(node->text == "expression_statement : expression SEMICOLON")
	{
		code << "\tPOP AX\n";

		if(node->si->label != "")
		{
			vector<string> v;
			string s = node->si->label;

			int end = s.find(","); 
			while (end != -1) {
				v.push_back(s.substr(0, end));
				s.erase(s.begin(), s.begin() + end + 1);
				end = s.find(",");
			}
			v.push_back(s.substr(0, end));

			if(v.size() == 2) {
				code << "\tCMP AX, 1\n";
				code << "\tJE " << v[0] << endl;
				code << "\tJMP " << v[1] << endl;
			}
			else {
				code << "\tJMP " << node->si->label << endl;
			}
		}
	}
	else if(node->text == "statement : compound_statement")
	{
		if(node->si->label != "")
		{
			code << "\tJMP " << node->si->label << endl;
		}
	}
	else if(node->text == "statement : IF LPAREN expression RPAREN statement" ||
		node->text == "statement : IF LPAREN expression RPAREN statement ELSE statement" ||
		node->text == "statement : WHILE LPAREN expression RPAREN statement" ||
		node->text == "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement")
	{
		code << "\t" << (node->children[0])->si->label << ":\n";
		code << "\t; end cond\n";
	} 
	else if(node->text == "statement : RETURN expression SEMICOLON") 
	{
		code << "\tPOP AX\n\tJMP " << func_end << endl;
	}
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
%type <node> compound_statement  

%nonassoc THEN
%nonassoc ELSE

%%

start : program { 
		$$ = new Node(new symbolInfo("", ""), " start : program");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		dfs($$, "", 0);
	}
	;
program : program unit {
		$$ = new Node(new symbolInfo("", ""), "program : program unit");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	| unit { 
		$$ = new Node(new symbolInfo("", ""), "program : unit");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	;
unit : var_declaration {
		$$ = new Node(new symbolInfo("", ""), "unit : var_declaration");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    | func_declaration { 
		$$ = new Node(new symbolInfo("", ""), "unit : func_declaration");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    | func_definition { 
		$$ = new Node(new symbolInfo("", ""), "unit : func_definition");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    ;
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
		$$ = new Node(new symbolInfo("", ""), "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		
		$$->firstLine = $1->firstLine;
		$$->lastLine = $6->lastLine;
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON {
		$$ = new Node(new symbolInfo("", ""), "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	;
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement {
		$$ = new Node(new symbolInfo("", ""), "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $6->lastLine;
	}
	| type_specifier ID LPAREN RPAREN compound_statement {
		$$ = new Node(new symbolInfo("", ""), "func_definition : type_specifier ID LPAREN RPAREN compound_statement");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	;	
parameter_list : parameter_list COMMA type_specifier ID {
		$$ = new Node(new symbolInfo("", ""), "parameter_list : parameter_list COMMA type_specifier ID");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;

		$4->si->setType($3->si->getType());
		$1->siv->push_back($4->si);
		$$->siv = $1->siv;
	}
	| parameter_list COMMA type_specifier {
		$$ = new Node(new symbolInfo("", ""), "parameter_list : parameter_list COMMA type_specifier");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	| type_specifier ID {
		$$ = new Node(new symbolInfo("", ""), "parameter_list : type_specifier ID");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;

		$2->si->setType($1->si->getType());
		$$->siv = new vector<symbolInfo*>();
		$$->siv->push_back($2->si);
	}
	
	| type_specifier {
		$$ = new Node(new symbolInfo("", ""), "parameter_list : type_specifier");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	;
compound_statement : LCURL statements RCURL {
		$$ = new Node(new symbolInfo("", ""), "compound_statement : LCURL statements RCURL");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	| LCURL RCURL {
		$$ = new Node(new symbolInfo("", ""), "compound_statement : LCURL RCURL");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	;
var_declaration : type_specifier declaration_list SEMICOLON {
		$$ = new Node(new symbolInfo("", ""), "var_declaration : type_specifier declaration_list SEMICOLON");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	;
type_specifier : INT {
		$$ = new Node($1->si, "type_specifier : INT");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| FLOAT {
		$$ = new Node($1->si, "type_specifier : FLOAT");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| VOID { 
		$$ = new Node($1->si, "type_specifier : VOID");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	;
declaration_list : declaration_list COMMA ID {
		$$ = new Node(new symbolInfo("", ""), "declaration_list : declaration_list COMMA ID");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		$1->siv->push_back($3->si);
		$$->siv = $1->siv;
	}
	| declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {


		$$ = new Node(new symbolInfo("", ""), "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $6->lastLine;

		$3->si->setExtra("ARRAY");
		$3->si->arrSize = stoi($5->si->getName());
		$1->siv->push_back($3->si);
		$$->siv = $1->siv;
	}
	| ID {
		$$ = new Node(new symbolInfo("", ""), "declaration_list : ID");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;

		$$->siv = new vector<symbolInfo*>();
		$$->siv->push_back($1->si);
	}
	
	
	| ID LSQUARE CONST_INT RSQUARE {
		$$ = new Node(new symbolInfo("", ""), "declaration_list : ID LSQUARE CONST_INT RSQUARE");
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
		$$ = new Node(new symbolInfo("", ""), "statements : statement");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| statements statement {
		$$ = new Node(new symbolInfo("", ""), "statements : statements statement");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	;
statement : var_declaration {
		$$ = new Node(new symbolInfo("", ""), "statement : var_declaration");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}	
	| expression_statement {
		$$ = new Node(new symbolInfo("", ""), "statement : expression_statement");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| compound_statement {
		$$ = new Node(new symbolInfo("", "") , "statement : compound_statement");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
		$$ = new Node(new symbolInfo("", ""), "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
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
		$$ = new Node(new symbolInfo("", ""), "statement : IF LPAREN expression RPAREN statement");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	| IF LPAREN expression RPAREN statement ELSE statement {
		$$ = new Node(new symbolInfo("", ""), "statement : IF LPAREN expression RPAREN statement ELSE statement");
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
		$$ = new Node(new symbolInfo("", ""), "statement : WHILE LPAREN expression RPAREN statement");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON {
		$$ = new Node(new symbolInfo("", ""), "statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $5->lastLine;
	}
	| RETURN expression SEMICOLON {
		$$ = new Node(new symbolInfo("", ""), "statement : RETURN expression SEMICOLON");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	;
expression_statement : SEMICOLON {
		$$ = new Node(new symbolInfo("", ""), "expression_statement : SEMICOLON");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}			
	| expression SEMICOLON {
		$$ = new Node(new symbolInfo("", ""), "expression_statement : expression SEMICOLON");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	;

variable : ID { 
		symbolInfo* s = st.lookup($1->si->getName());

		$$ = new Node(s ? s : $1->si, "variable : ID");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| ID LSQUARE expression RSQUARE {
		$$ = new Node($1->si, "variable : ID LSQUARE expression RSQUARE");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;
	}
	;

expression : logic_expression {
		$$ = new Node($1->si, "expression : logic_expression");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| variable ASSIGNOP logic_expression {
		$$ = new Node($1->si, "expression : variable ASSIGNOP logic_expression");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}	
	;

logic_expression : rel_expression { 
		$$ = new Node($1->si, "logic_expression : rel_expression");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}	
	| rel_expression LOGICOP rel_expression {
		symbolInfo* s = new symbolInfo("logicop", "INT");
		$$ = new Node(s, "logic_expression : rel_expression LOGICOP rel_expression");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}	
	;

rel_expression : simple_expression {
		$$ = new Node($1->si, "rel_expression : simple_expression");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| simple_expression RELOP simple_expression	{
		symbolInfo* s = new symbolInfo("relop", "INT");
		$$ = new Node(s, "rel_expression : simple_expression RELOP simple_expression");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	;

simple_expression : term {
		$$ = new Node($1->si, "simple_expression : term");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}	
	| simple_expression ADDOP term {
		$$ = new Node($1->si, "simple_expression : simple_expression ADDOP term");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	} 
	;

term :	unary_expression {
		$$ = new Node($1->si, "term : unary_expression");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
    |  term MULOP unary_expression {
		$$ = new Node($1->si, "term : term MULOP unary_expression");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
    ;
 
unary_expression : ADDOP unary_expression {
		$$ = new Node($2->si, "unary_expression : ADDOP unary_expression");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}  
	| NOT unary_expression {
		$$ = new Node($2->si, "unary_expression : NOT unary_expression");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	} 
	| factor {
		$$ = new Node($1->si, "unary_expression : factor");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	} 
	;
	
factor : variable {
		$$ = new Node($1->si, "factor : variable");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| ID LPAREN argument_list RPAREN { 
		$$ = new Node($1->si, "factor : ID LPAREN argument_list RPAREN");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $4->lastLine;
	}
	| LPAREN expression RPAREN {
		$$ = new Node($2->si, "factor : LPAREN expression RPAREN");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;
	}
	| CONST_INT { 
		symbolInfo* s = new symbolInfo($1->si->getName(), "INT");
		$$ = new Node(s, "factor : CONST_INT");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| CONST_FLOAT { 
		symbolInfo* s = new symbolInfo($1->si->getName(), "FLOAT");
		$$ = new Node(s, "factor : CONST_FLOAT");
		$$->children.push_back($1);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $1->lastLine;
	}
	| variable INCOP {
		$$ = new Node($1->si, "factor : variable INCOP");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	| variable DECOP {
		$$ = new Node($1->si, "factor : variable DECOP");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $2->lastLine;
	}
	;	
argument_list : arguments {
		$$ = new Node($1->si, "argument_list : arguments");
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
		$$ = new Node(new symbolInfo("", ""), "arguments : arguments COMMA logic_expression");
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->firstLine = $1->firstLine;
		$$->lastLine = $3->lastLine;

		$1->siv->push_back($3->si);
		$$->siv = $1->siv;
	}
	| logic_expression {
		$$ = new Node(new symbolInfo("", ""), "arguments : logic_expression");
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

	code.open("1905024_out_code.asm", ios::out);
	/* error.open("1905024_out_error.txt", ios::out);
	parseTree.open("1905024_out_parsetree.txt", ios::out); */
	
	if(code.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
	
	/* if(error.is_open() != true) {
		cout << "error file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
	
    if(parseTree.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	} */
	
	yyin = input;
    yyparse();


	
	fclose(yyin);
	code.close();
	/* error.close();
	parseTree.close(); */
	
	return 0;
} 

void yyerror(char* s) {
    

    line_count++;
    error_count++;
    
    return ;
}