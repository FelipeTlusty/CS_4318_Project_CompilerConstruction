
/* definitions */

%{
#include<stdio.h>
#include "tokendef.h"

int scancol = 1;
int yycol = 1;
int scanlineno = 1;

char* yyerror;

void updateCol(); //TODO: Implement this function to keep track of column numbers
void countLines(); //TODO: Implement this function to keep track of line numbers
int processString(); //TODO: Implement this function to check for illegal escape sequences in string literals and print out escape sequences correctly.
%}

newline         \n
whitespace      [ \t]+
integer         0|[1-9][0-9]*
integerlead0	0[0-9]*
character       \'([^\']|\\[\\nt\'])\'

/* String can contain any characters between the double quotes other than a newline or
// unescaped doublequotes.
*/
string       \"(\\.|[^\"\\\n])*\"

/* multiline string has \n somewhere in the middle */
multlnstring \"(\\.|[^\"\\])*(\n)+(\\.|[^\"\\])*\"

/* If the end quote is found, one of the two regexes above will be matched. Otherwise,
// the string is unterminated.
*/
untermstring \"(\\.|[^\"\\])*

comment         \/\/.*
multlncomment   \/\*[^\*]*(\*)+(?:[^\/\*][^\*]*(\*)+)*\/
untermcomment   \/\*[^\*]*(\*)*(?:[^\/\*][^\*]*(\*)*)*

identifier      [a-zA-Z][a-zA-Z0-9]*

 //regular expression for an illegal identifier
illidentifier   [0-9]+[a-zA-Z][a-zA-Z0-9]*

%%

 /* rules */

 /* Keywords */;
 //TODO: Support all keywords in mC
char		{ updateCol(); return KWD_CHAR; }
const		{ updateCol(); return KWD_CONST; }
double		{ updateCol(); return KWD_DOUBLE; }
else		{ updateCol(); return KWD_ELSE; }
enum		{ updateCol(); return KWD_ENUM; }
float		{ updateCol(); return KWD_FLOAT; }
for		{ updateCol(); return KWD_FOR; }
if		{ updateCol(); return KWD_IF; }
int		{ updateCol(); return KWD_INT; }
long		{ updateCol(); return KWD_LONG; }
return		{ updateCol(); return KWD_RETURN; }
short		{ updateCol(); return KWD_SHORT; }
static		{ updateCol(); return KWD_STATIC; }
struct		{ updateCol(); return KWD_STRUCT; }
switch		{ updateCol(); return KWD_SWTCH; }
void		{ updateCol(); return KWD_VOID; }
while		{ updateCol(); return KWD_WHILE; }
string		{ updateCol(); return KWD_STRING; }

 /* Operators */;

\+	{ updateCol(); return OPER_ADD; }
\-	{ updateCol(); return OPER_SUB; }
\*	{ updateCol(); return OPER_MUL; }
\/	{ updateCol(); return OPER_DIV; }
\%	{ updateCol(); return OPER_MOD; }
\+\+	{ updateCol(); return OPER_INC; }
\-\-	{ updateCol(); return OPER_DEC; }
\=\=	{ updateCol(); return OPER_EQ; }
\!\=	{ updateCol(); return OPER_NEQ; }
\>	{ updateCol(); return OPER_GT; }
\<	{ updateCol(); return OPER_LT; }
\>\=	{ updateCol(); return OPER_GTE; }
\<\=	{ updateCol(); return OPER_LTE; }
\&\&	{ updateCol(); return OPER_AND; }
\|\|	{ updateCol(); return OPER_OR; }
\!	{ updateCol(); return OPER_NOT; }
\=	{ updateCol(); return OPER_ASGN; }
\+\=	{ updateCol(); return OPER_ADDEQ; }
\-\=	{ updateCol(); return OPER_SUBEQ; }
\*\=	{ updateCol(); return OPER_MULEQ; }
\/\=	{ updateCol(); return OPER_DIVEQ; }
\%\=	{ updateCol(); return OPER_MODEQ; }
\@	{ updateCol(); return OPER_AT; }
\#	{ updateCol(); return OPER_HASH; }

 /* Brackets & parenthesis */;
\[		{ updateCol(); return LSQ_BRKT; }
\]		{ updateCol(); return RSQ_BRKT; }
\{		{ updateCol(); return LCRLY_BRKT; }
\}		{ updateCol(); return RCRLY_BRKT; }
\(		{ updateCol(); return LPAREN; }
\)		{ updateCol(); return RPAREN; }

 /* Punctuation */;
\,		{ updateCol(); return COMMA; }
\;		{ updateCol(); return SEMICLN; }
\.		{ updateCol(); return DOT; }

 /* Identifiers */;
{identifier}    { updateCol(); return ID; }
{illidentifier} { updateCol(); yyerror = "Illegal Identifier"; return ERROR; }

 /* Constants */;
{integer}       { updateCol(); return INTCONST; }
{integerlead0}  { updateCol(); yyerror = "Integers may not have leading zeros"; return ERROR;} 
{character}     { updateCol(); return CHARCONST; }
{string}        {updateCol(); return processString();}
{untermstring}  {updateCol(); yyerror = "Unterminated string"; return ERROR;}
{multlnstring}  {updateCol(); countLines(); yyerror = "String spans multiple lines"; return ERROR;} // Catching a multi-line string and generating an error.

 /* Comments */;
{comment}       { updateCol(); }
{untermcomment} { updateCol(); countLines(); yyerror = "Unterminated Comment"; return ERROR; } 
{multlncomment} { updateCol(); countLines(); }

 /* Other */;
{newline}       { scanlineno++; yycol = 1; scancol = 1; }
{whitespace}    { updateCol(); }
.               {return ILLEGAL_TOK;}

%%

 /* user routines */

void updateCol(){
	yycol = scancol;
    	scancol += yyleng;
	yylineno = scanlineno;
}

void countLines(){
	for (int i = 0; i < yyleng; i++){
		if (yytext[i] == '\n'){
			scanlineno++;
		}
	}
}


int processString(){
	// TODO: Process a string literal and return the appropriate microsyntax.
	for (int i = 0; i < yyleng - 1; i++){
		int counter = 0;
		if (yytext[i] == '\\'){
			counter++;
			if (yytext[i+1] == 'n'){
				yytext[i] = '\n';
				yytext[i+1] = ' ';
			}
			else if (yytext[i+1] == 't'){
				yytext[i] = '\t';
				yytext[i+1] = ' ';
			}
			else if (yytext[i+1] == '\"'){
				yytext[i] = '\"';
				yytext[i+1] = ' ';
			}
			else if (yytext[i+1] == '\\'){
				yytext[i] = '\\';
				yytext[i+1] = ' ';
			}
			else{
				yycol += i;
				yyerror = "Unrecognized Escape Character in String.";
				return ERROR;
			}
		}
	}
	return STRCONST;
}

