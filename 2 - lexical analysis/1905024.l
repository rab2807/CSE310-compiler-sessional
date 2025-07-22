%option noyywrap

%x INSIDE_COMMENT
%x INSIDE_STRING

%{
#include <string>
#include <fstream>
#include <cstring>
#include <cstdlib>
using namespace std;

#include "symbol_table.h"

symbolTable st(10);

FILE *input;
ofstream token;

int line_count = 1;
int error_count = 0;

string comment = "";
string strContainer = "";

void insertPrint(string symbol, string type)
{
    bool x = st.insert(symbol, type);
    if (x)
        st.printAll();
}

char lexemeToChar(const char *ptr)
{
    if (ptr[1] != '\\')
        return ptr[1];

    if (ptr[2] == 'n')
        return (char)10;
    else if (ptr[2] == 't')
        return (char)9;
    else if (ptr[2] == 'v')
        return (char)11;
    else if (ptr[2] == 'f')
        return (char)12;
    else if (ptr[2] == 'r')
        return (char)13;
    else if (ptr[2] == 'a')
        return (char)7;
    else if (ptr[2] == 'b')
        return (char)8;
    else if (ptr[2] == '0')
        return (char)0;
    else if (ptr[2] == '\\')
        return (char)92;
    else if (ptr[2] == '\"')
        return (char)34;
    else if (ptr[2] == '\'')
        return (char)39;
}

int generateString(const char *ptr)
{
    int length = strlen(ptr);
    string str = "";

    for (int i = 0; i < length - 1; i++)
    { 
        if (ptr[i] != '\\')
            str.push_back(ptr[i]);
        else
        { 
            if (ptr[i + 1] == 'n')
                str.push_back('\n');
            else if (ptr[i + 1] == 't')
                str.push_back('\t');
            else if (ptr[i + 1] == 'v')
                str.push_back('\v');
            else if (ptr[i + 1] == 'f')
                str.push_back('\f');
            else if (ptr[i + 1] == 'r')
                str.push_back('\r');
            else if (ptr[i + 1] == 'a')
                str.push_back('\a');
            else if (ptr[i + 1] == 'b')
                str.push_back('\b');
            else if (ptr[i + 1] == '0')
                str.push_back('\0');
            else if (ptr[i + 1] == '\'')
                str.push_back('\'');
            else if(ptr[i + 1] == '\\')
                str.push_back('\\');
            else if(ptr[i + 1] == '\n') 
                i++;      
            else if(ptr[i + 1] == '\r' && ptr[i + 2] == '\n') {
                i++;      
            }
            i++;
        }
    }
    if(ptr[length - 1] == '\n')
        return false;
    strContainer = str;
    return true;
}

void countLine(const char *ptr)
{
    int l = strlen(ptr);
    for (int i = 0; i < l; i++)
        if (ptr[i] == '\n')
            line_count++;
}

string toUpper(const char* c) 
{
    string str(c);
    for (int i = 0; i < strlen(c); i++)
        str[i] = toupper(str[i]);
    return str;
}

string trimString(const char* c) {
    string str(c);
    if(str[str.size() - 1] == (char)13)
        str.pop_back();
    if(str[str.size() - 1] == (char)10 || str[str.size() - 2] == (char)13) {
        str.pop_back();
        str.pop_back();
    }
    return str;
}

void finalOut()
{
    st.printAll();
    st.exit();

    cout << "Total lines: " << line_count << endl;
    cout << "Total errors: " << error_count << endl;
}

%}

WHITESPACE [ \t\v\f\r]+
LETTER [A-Za-z]
DIGIT [0-9]
ESCAPE_CHAR \\[ntvfrab0\\"']
CHAR [^\\\'\"\n\t]

%%

"if" |
"else" |
"for" |
"while" |
"do" |
"break" |
"int" |
"char" |
"float" |
"double" |
"void" |
"return" |
"continue" |
"switch" |
"case" |
"default" {
    token << "<" << toUpper(yytext) << ", " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <" << toUpper(yytext) << "> Lexeme " << yytext << " found" << endl;
}

"+"|"-" {
    token << "<ADDOP, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <ADDOP> Lexeme " << yytext << " found" << endl;
}
"*"|"/"|"%" {
    token << "<MULOP, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <MULOP> Lexeme " << yytext << " found" << endl;
}
"++"|"--" {
    token << "<INCOP, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <INCOP> Lexeme " << yytext << " found" << endl;
}
"<"|"<="|">"|">="|"=="|"!=" {
    token << "<RELOP, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <RELOP> Lexeme " << yytext << " found" << endl;
}
"=" {
    token << "<ASSIGNOP, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <ASSIGNOP> Lexeme " << yytext << " found" << endl;
}
"&&"|"||" {
    token << "<LOGICOP, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <coutICOP> Lexeme " << yytext << " found" << endl;
}
"&"|"|"|"^"|"<<"|">>" {
    token << "<BITOP, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <BITOP> Lexeme " << yytext << " found" << endl;
}
"!" {
    token << "<NOT, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <NOT> Lexeme " << yytext << " found" << endl;
}
"(" {
    token << "<LPAREN, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <LPAREN> Lexeme " << yytext << " found" << endl;
}
")" {
    token << "<RPAREN, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <RPAREN> Lexeme " << yytext << " found" << endl;
}
"{" {
    st.enter();
    token << "<LCURL, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <LCURL> Lexeme " << yytext << " found" << endl;
}
"}" {
    st.exit();
    token << "<RCURL, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <RCURL> Lexeme " << yytext << " found" << endl;
}
"[" {
    token << "<LSQUARE, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <LSQUARE> Lexeme " << yytext << " found" << endl;
}
"]" {
    token << "<RSQUARE, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <RSQUARE> Lexeme " << yytext << " found" << endl;
}
"," {
    token << "<COMMA, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <COMMA> Lexeme " << yytext << " found" << endl;
}
";" {
    token << "<SEMICOLON, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <SEMICOLON> Lexeme " << yytext << " found" << endl;
}

\r\n|\n {
    line_count++;
}

{DIGIT}+ {
    token << "<CONST_INT, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <CONST_INT> Lexeme " << yytext << " found" << endl;
}

({DIGIT}+(\.{DIGIT}+)?|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)? {
    token << "<CONST_FLOAT, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <CONST_FLOAT> Lexeme " << yytext << " found" << endl;
}

\'{CHAR}\'|\'{ESCAPE_CHAR}\' {
    token << "<CONST_CHAR, " << lexemeToChar(yytext) << ">\n";
    cout << "Line# " << line_count << ": Token <CONST_CHAR> Lexeme " << lexemeToChar(yytext) << " found" << endl;
}

[A-Za-z_][0-9A-Z_a-z]* {
    token << "<ID, " << yytext << ">\n";
    cout << "Line# " << line_count << ": Token <ID> Lexeme " << yytext << " found" << endl;
    insertPrint(yytext, "ID");	
}

\/\/([^\n]*\\\r\n)*[^\n]* {
    cout << "Line# " << line_count << ": Token <SINGLE LINE COMMENT> Lexeme " << trimString(yytext) << " found" << endl;
    countLine(yytext);
}

{WHITESPACE} {}

\" {
    BEGIN INSIDE_STRING;
}

<INSIDE_STRING>((\\[^\n]|[^\"\n\\])*\\\r\n)+(\\[^\n]|[^"\n\\])*[\"\n] {
    bool x = generateString(yytext);
    if(x)
    {
        token << "<MULTI LINE STRING, " << strContainer << ">\n";
        cout << "Line# " << line_count << ": Token <MULTI LINE STRING> Lexeme \"" << yytext << " found" << endl;
        countLine(yytext);
    }
    else
    {
        string str(yytext);
        if(str[str.size() - 1] == (char)13)
            str.pop_back();
        if(str[str.size() - 1] == (char)10 || str[str.size() - 2] == (char)13) {
            str.pop_back();
            str.pop_back();
        }

        cout << "Error at line# " << line_count << ": UNFINISHED_STRING " << trimString(yytext) << endl;
        error_count++;
    }
    BEGIN INITIAL;
}

<INSIDE_STRING>(\\[^\n]|[^\"\n\\])*[\"\n] {
    bool x = generateString(yytext);
    if(x) 
    {
        token << "<SINGLE LINE STRING, " << strContainer << ">\n";
        cout << "Line# " << line_count << ": Token <SINGLE LINE STRING> Lexeme \"" << yytext << " found" << endl;
    }
    else
    {
        string str(yytext);
        
        if(str[str.size() - 1] == (char)13 || str[str.size() - 1] == (char)10)
            str.pop_back();
        if(str[str.size() - 1] == (char)10 || str[str.size() - 2] == (char)13) {
            str.pop_back();
            str.pop_back();
        }        
        
        cout << "Error at line# " << line_count << ": UNFINISHED_STRING \"" << trimString(yytext) << endl;
        countLine(yytext);
        error_count++;
    }
    BEGIN INITIAL;
}

<INSIDE_STRING><<EOF>> {
    cout << "\nError at line# " << line_count << ": UNFINISHED_STRING \"" << yytext << endl;
    countLine(yytext);
    error_count++;
    BEGIN INITIAL;
}

"/*" {
    comment.clear();
    BEGIN INSIDE_COMMENT;
}

<INSIDE_COMMENT>([^\n\r]) {
    string str(yytext);
    comment += (str);
}

<INSIDE_COMMENT>\n|\r\n {
    string str(yytext);
    comment += (str);
}

<INSIDE_COMMENT>"*/" {
    cout << "Line# " << line_count << ": Token <MULTI LINE COMMENT> Lexeme /*" << comment << "*/ found" << endl;
    countLine(comment.c_str());
    BEGIN INITIAL;
}

<INSIDE_COMMENT><<EOF>> {
    cout << "\nError at line# " << line_count << ": UNFINISHED_COMMENT /*" << trimString(comment.c_str()) << endl;
    countLine(comment.c_str());
    error_count++;
    BEGIN INITIAL;
}

({DIGIT}+\.{DIGIT}+|\.{DIGIT}+)(\.{DIGIT}*)+ {
    cout << "Error at line# " << line_count << ": TOO_MANY_DECIMAL_POINTS " << yytext << endl;
    error_count++;
}

({DIGIT}+(\.{DIGIT}+)?|\.{DIGIT}+)([Ee][+-]?{DIGIT}+(\.{DIGIT}*)+) {
    cout << "Error at line# " << line_count << ": ILLFORMED_NUMBER " << yytext << endl;
    error_count++;
}

[0-9][0-9A-Z_a-z]* {
    cout << "Error at line# " << line_count << ": INVALID_ID_SUFFIX_NUM_PREFIX " << yytext << endl;
    error_count++;
}

"''" {
    cout << "Error at line# " << line_count << ": EMPTY_CONST_CHAR " << yytext << endl;
    error_count++;
}

\'{CHAR}{CHAR}+\'|\'{CHAR}*\\[ntvfrab0\\"']{CHAR}*\' {
    cout << "Error at line# " << line_count << ": MULTICHAR_CONST_CHAR " << yytext << endl;
    error_count++;
}

\'{CHAR}*\n|\'{CHAR}*\\[ntvfrab0\\"']{CHAR}*\n {
    cout << "Error at line# " << line_count << ": UNFINISHED_CONST_CHAR " << trimString(yytext) << endl;
    countLine(yytext);
    error_count++;
}

. {
    cout << "Error at line# " << line_count << ": UNRECOGNIZED_CHAR " << yytext << endl;
    error_count++;
}

%%

int main() {	
	input = fopen("in.txt", "r");
    freopen("log.txt", "w", stdout);
	token.open("token.txt", ios::out);
		
	if(token.is_open() != true) {
		fclose(input);
		token.close();
	}
		
	yyin = input;
	yylex(); 
    finalOut();

	fclose(yyin);
	token.close();
	
	return 0;
} 
