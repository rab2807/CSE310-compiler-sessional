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
extern ofstream code;
extern ofstream error;

extern int line_count;
extern int error_count;  // NOTICE

extern string name;

extern bool func_definition_flag;

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

	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return IF;
}
"else"	{
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return ELSE;
}
"for"	{

	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return FOR;
}
"while"	{

	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return WHILE;
}
"int"	{

	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return INT;
}
"float"	{

	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return FLOAT;
}
"void"	{

	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return VOID;
}
"return"	{

	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RETURN;
}
"println" {
	symbolInfo* s = new symbolInfo(string(yytext), toUpper(yytext));
    yylval.node = new Node(s, toUpper(yytext) + " : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return PRINTLN;
}

"+"|"-" {

	symbolInfo* s = new symbolInfo(string(yytext), "ADDOP");
    yylval.node = new Node(s, "ADDOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return ADDOP;
}
"*"|"/"|"%" {

	symbolInfo* s = new symbolInfo(string(yytext), "MULOP");
    yylval.node = new Node(s, "MULOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return MULOP;
}
"++" {

	symbolInfo* s = new symbolInfo(string(yytext), "INCOP");
    yylval.node = new Node(s, "INCOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return INCOP;
}
"--" {

	symbolInfo* s = new symbolInfo(string(yytext), "DECOP");
    yylval.node = new Node(s, "DECOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return DECOP;
}
"<"|"<="|">"|">="|"=="|"!=" {

	symbolInfo* s = new symbolInfo(string(yytext), "RELOP");
    yylval.node = new Node(s, "RELOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RELOP;
}
"=" {

	symbolInfo* s = new symbolInfo(string(yytext), "ASSIGNOP");
    yylval.node = new Node(s, "ASSIGNOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return ASSIGNOP;
}
"&&"|"||" {

	symbolInfo* s = new symbolInfo(string(yytext), "LOGICOP");
    yylval.node = new Node(s, "LOGICOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LOGICOP;
}
"!" {

	symbolInfo* s = new symbolInfo(string(yytext), "LOGICOP");
    yylval.node = new Node(s, "LOGICOP : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return NOT;
}
"(" {

	symbolInfo* s = new symbolInfo(string(yytext), "LPAREN");
    yylval.node = new Node(s, "LPAREN : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LPAREN;
}
")" {

	symbolInfo* s = new symbolInfo(string(yytext), "RPAREN");
    yylval.node = new Node(s, "RPAREN : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RPAREN;
}
"{" {

	symbolInfo* s = new symbolInfo(string(yytext), "LCURL");
    yylval.node = new Node(s, "LCURL : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LCURL;
}
"}" {

	symbolInfo* s = new symbolInfo(string(yytext), "RCURL");
    yylval.node = new Node(s, "RCURL : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RCURL;
}
"[" {

	symbolInfo* s = new symbolInfo(string(yytext), "LSQUARE");
    yylval.node = new Node(s, "LSQUARE : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return LSQUARE;
}
"]" {

	symbolInfo* s = new symbolInfo(string(yytext), "RSQUARE");
    yylval.node = new Node(s, "RSQUARE : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return RSQUARE;
}
"," {

	symbolInfo* s = new symbolInfo(string(yytext), "COMMA");
    yylval.node = new Node(s, "COMMA : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return COMMA;
}
";" {

	symbolInfo* s = new symbolInfo(string(yytext), "SEMICOLON");
    yylval.node = new Node(s, "SEMICOLON : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	return SEMICOLON;
}

\n {
    line_count++;
}

\/\/[^\n]*\n {
}

"/*".*"*/" {
	cout<<"found";
}

{DIGIT}+ {
    
	symbolInfo* s = new symbolInfo(string(yytext), "CONST_INT");
    yylval.node = new Node(s, "CONST_INT : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
    return CONST_INT;
}

({DIGIT}+(\.{DIGIT}+)?|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)? {
    
	symbolInfo* s = new symbolInfo(string(yytext), "CONST_FLOAT");
    yylval.node = new Node(s, "CONST_FLOAT : " + string(yytext));
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
    return CONST_FLOAT;
}

[A-Za-z_][0-9A-Z_a-z]* {
	symbolInfo* s = new symbolInfo(string(yytext), "ID");
    yylval.node = new Node(s, "ID");
	yylval.node->firstLine = yylval.node->lastLine = yylval.node->isTerminal = line_count;
	name = string(yytext);
    return ID;
}

{WHITESPACE} {}
%%