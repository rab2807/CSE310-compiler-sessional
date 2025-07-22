%option noyywrap

%{
#include<iostream>
#include <string>
#include <fstream>
#include <cstring>
using namespace std;

FILE *input;
ofstream log;
%}

%%

\n {
	log << endl;
}

"\tPUSH AX\n\tPOP AX\n" {
	// ignore
}

"\tJMP L"[0-9]"\n\tL"[0-9]":\n" {
	// ignore
	if(yytext[6] != yytext[10])
		log << yytext;
}

"" {

}

. {
	log << yytext;
}

%%

int main(int argc, char* argv[]) {	
	input = fopen(argv[1], "r");
	log.open("1905024_out_opt_code.asm", ios::out);
	
	if(log.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
			
	yyin = input;
	yylex();  // scanning input
	
	fclose(yyin);
	log.close();
	
	return 0;
} 
