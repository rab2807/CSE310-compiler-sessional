%option noyywrap

%{
#include <iostream>
#include <string>
#include <fstream>
using namespace std;

#include "symbol_table.h"
#include "y.tab.h"

extern YYSTYPE yylval;  
extern symbolTable st;   // NOTICE
extern ofstream log;
extern ofstream error;

extern int line_count;
extern int error_count;  // NOTICE

extern string name;

string toUpper(const char* c) 
{
    string str(c);
    for (int i = 0; i < strlen(c); i++)
        str[i] = toupper(str[i]);
    return str;
}
%}

WHITESPACE [ \t\v\f\r]+
DIGIT [0-9]

%%

"if" {
	log << "Line# " << line_count << ": Token <IF> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return IF;
}
"else"	{
	log << "Line# " << line_count << ": Token <ELSE> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return ELSE;
}
"for"	{
	log << "Line# " << line_count << ": Token <FOR> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return FOR;
}
"while"	{
	log << "Line# " << line_count << ": Token <WHILE> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return WHILE;
}
"int"	{
	log << "Line# " << line_count << ": Token <INT> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return INT;
}
"float"	{
	log << "Line# " << line_count << ": Token <FLOAT> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return FLOAT;
}
"void"	{
	log << "Line# " << line_count << ": Token <VOID> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return VOID;
}
"return"	{
	log << "Line# " << line_count << ": Token <RETURN> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RETURN;
}


"+"|"-" {
	log << "Line# " << line_count << ": Token <ADDOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "ADDOP");
    yylval.node = new Node(s, "ADDOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return ADDOP;
}
"*"|"/"|"%" {
	log << "Line# " << line_count << ": Token <MULOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "MULOP");
    yylval.node = new Node(s, "MULOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return MULOP;
}
"++" {
	log << "Line# " << line_count << ": Token <INCOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "INCOP");
    yylval.node = new Node(s, "INCOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return INCOP;
}
"--" {
	log << "Line# " << line_count << ": Token <DECOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "DECOP");
    yylval.node = new Node(s, "DECOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return DECOP;
}
"<"|"<="|">"|">="|"=="|"!=" {
	log << "Line# " << line_count << ": Token <RELOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "RELOP");
    yylval.node = new Node(s, "RELOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RELOP;
}
"=" {
	log << "Line# " << line_count << ": Token <ASSIGNOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "ASSIGNOP");
    yylval.node = new Node(s, "ASSIGNOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return ASSIGNOP;
}
"&&"|"||" {
	log << "Line# " << line_count << ": Token <LOGICOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "LOGICOP");
    yylval.node = new Node(s, "LOGICOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LOGICOP;
}
"!" {
	log << "Line# " << line_count << ": Token <LOGICOP> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "LOGICOP");
    yylval.node = new Node(s, "LOGICOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return NOT;
}
"(" {
	log << "Line# " << line_count << ": Token <LPAREN> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "LPAREN");
    yylval.node = new Node(s, "LPAREN : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LPAREN;
}
")" {
	log << "Line# " << line_count << ": Token <RPAREN> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "RPAREN");
    yylval.node = new Node(s, "RPAREN : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RPAREN;
}
"{" {
	log << "Line# " << line_count << ": Token <LCURL> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "LCURL");
    yylval.node = new Node(s, "LCURL : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LCURL;
}
"}" {
	log << "Line# " << line_count << ": Token <RCURL> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "RCURL");
    yylval.node = new Node(s, "RCURL : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RCURL;
}
"[" {
	log << "Line# " << line_count << ": Token <LSQUARE> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "LSQUARE");
    yylval.node = new Node(s, "LSQUARE : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LSQUARE;
}
"]" {
	log << "Line# " << line_count << ": Token <RSQUARE> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "RSQUARE");
    yylval.node = new Node(s, "RSQUARE : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RSQUARE;
}
"," {
	log << "Line# " << line_count << ": Token <COMMA> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "COMMA");
    yylval.node = new Node(s, "COMMA : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return COMMA;
}
";" {
	log << "Line# " << line_count << ": Token <SEMICOLON> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "SEMICOLON");
    yylval.node = new Node(s, "SEMICOLON : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return SEMICOLON;
}

\n {
    line_count++;
}

{DIGIT}+ {
    log << "Line# " << line_count << ": Token <CONST_INT> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "CONST_INT");
    yylval.node = new Node(s, "CONST_INT : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
    return CONST_INT;
}

({DIGIT}+(\.{DIGIT}+)?|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)? {
    log << "Line# " << line_count << ": Token <CONST_FLOAT> Lexeme " << yytext << " found" << endl;
	symbolInfo* s = new symbolInfo(string(yytext), "CONST_FLOAT");
    yylval.node = new Node(s, "CONST_FLOAT : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
    return CONST_FLOAT;
}

[A-Za-z_][0-9A-Z_a-z]* {
    log << "Line# " << line_count << ": Token <ID> Lexeme " << yytext << " found" << endl;

	// log<<"before::";
	// st.printAll(log);
	
	symbolInfo* s = new symbolInfo(string(yytext), "ID");

	// log<<"after::";
	// st.printAll(log);
	
    yylval.node = new Node(s, "ID : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	name = string(yytext);
    return ID;
}

{WHITESPACE} {}

({DIGIT}+\.{DIGIT}+|\.{DIGIT}+)(\.{DIGIT}*)+ {
    error << "Error at line# " << line_count << ": TOO_MANY_DECIMAL_POINTS " << yytext << endl;
    error_count++;
}

({DIGIT}+(\.{DIGIT}+)?|\.{DIGIT}+)([Ee][+-]?{DIGIT}+(\.{DIGIT}*)+) {
    error << "Error at line# " << line_count << ": ILLFORMED_NUMBER " << yytext << endl;
    error_count++;
}

[0-9][0-9A-Z_a-z]* {
    error << "Error at line# " << line_count << ": INVALID_ID_SUFFIX_NUM_PREFIX " << yytext << endl;
    error_count++;
}

. {
    error << "Error at line# " << line_count << ": UNRECOGNIZED_CHAR " << yytext << endl;
    error_count++;
}

%%