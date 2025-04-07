%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<../src/tree.h>
//#include<../src/strtab.h>

extern int yylineno;
/* nodeTypes refer to different types of internal and external nodes that can be part of the abstract syntax tree.*/
enum nodeTypes {PROGRAM, DECLLIST, DECL, VARDECL, TYPESPEC, FUNDECL,
                FORMALDECLLIST, FORMALDECL, FUNBODY, LOCALDECLLIST,
                STATEMENTLIST, STATEMENT, COMPOUNDSTMT, ASSIGNSTMT,
                CONDSTMT, LOOPSTMT, RETURNSTMT, EXPRESSION, RELOP,
                ADDEXPR, ADDOP, TERM, MULOP, FACTOR, FUNCCALLEXPR,
                ARGLIST, INTEGER, IDENTIFIER, VAR, ARRAYDECL, CHAR,
                FUNCTYPENAME, FUNHEADER};

enum opType {ADD, SUB, MUL, DIV, LT, LTE, EQ, GTE, GT, NEQ};

/* NOTE: mC has two kinds of scopes for variables : local and global. Variables declared outside any
function are considered globals, whereas variables (and parameters) declared inside a function foo are local to foo. You should update the scope variable whenever you are inside a production that matches function definition (funDecl production). The rationale is that you are entering that function, so all variables, arrays, and other functions should be within this scope. You should pass this variable whenever you are calling the ST_insert or ST_lookup functions. This variable should be updated to scope = "" to indicate global scope whenever funDecl finishes. Treat these hints as helpful directions only. You may implement all of the functions as you like and not adhere to my instructions. As long as the directory structure is correct and the file names are correct, we are okay with it. */
char* scope = "";
%}

/* the union describes the fields available in the yylval variable */
%union
{
    int value;
    struct treenode *node;
    char *strval;
}

/*Add token declarations below. The type <value> indicates that the associated token will be of a value type such as integer, float etc., and <strval> indicates that the associated token will be of string type.*/
%token <strval> ID
%token <value> INTCONST
/* TODO: Add the rest of the tokens below.*/
%token <value> KWD_IF
%token <value> KWD_WHILE
%token <value> KWD_ELSE
%token <value> KWD_INT
%token <value> KWD_CHAR
%token <value> KWD_RETURN
%token <value> KWD_VOID
%token <value> OPER_ADD
%token <value> OPER_SUB
%token <value> OPER_MUL
%token <value> OPER_DIV
%token <value> OPER_LTE
%token <value> OPER_GTE
%token <value> OPER_LT
%token <value> OPER_GT
%token <value> OPER_EQ
%token <value> OPER_NEQ
%token <value> OPER_ASGN
%token <value> LSQ_BRKT
%token <value> RSQ_BRKT
%token <value> LCRLY_BRKT
%token <value> RCRLY_BRKT
%token <value> LPAREN RPAREN
%token <value> COMMA SEMICLN
%token <value> CHARCONST
%token <value> ERROR
%token <value> ILLEGAL_TOKEN
%token <value> STRCONST

/* TODO: Declare non-terminal symbols as of type node. Provided below is one example. node is defined as 'struct treenode *node' in the above union data structure. This declaration indicates to parser that these non-terminal variables will be implemented using a 'treenode *' type data structure. Hence, the circles you draw when drawing a parse tree, the following lines are telling yacc that these will eventually become circles in an AST. This is one of the connections between the AST you draw by hand and how yacc implements code to concretize that. We provide with two examples: program and declList from the grammar. Make sure to add the rest.  */

%type <node> program declList decl varDecl typeSpecifier funDecl formalDeclList formalDecl funBody localDeclList statementList statement
%type <node> compoundStmt assignStmt condStmt loopStmt returnStmt expression var relop addExpr addop term mulop factor funcCallExpr argList
%type <node> funHeader

%start program

%%
/* TODO: Your grammar and semantic actions go here. We provide with two example productions and their associated code for adding non-terminals to the AST.*/

program         : declList
                 {
                    tree* progNode = maketree(PROGRAM);
                    addChild(progNode, $1);
                    ast = progNode;
                 }
                ;

declList        : decl
                 {
                    tree* declListNode = maketree(DECLLIST);
                    addChild(declListNode, $1);
                    $$ = declListNode;
                 }
                | declList decl
                 {
                    tree* declListNode = maketree(DECLLIST);
                    addChild(declListNode, $1);
                    addChild(declListNode, $2);
                    $$ = declListNode;
                 }
                ;

decl            : varDecl
                 {
                    tree* declNode = maketree(DECL);
                    addChild(declNode, $1);
                    $$ = declNode;
                 }
                | funDecl
                 {
                    tree* declNode = maketree(DECL);
                    addChild(declNode, $1);
                    $$ = declNode;
                 }
                ;

varDecl         : typeSpecifier ID LSQ_BRKT INTCONST RSQ_BRKT SEMICLN
                 {
                    tree* varDeclNode = maketree(VARDECL);
                    addChild(varDeclNode, $1);
                    int index = ST_insert($2, scope, $1->val, 1);
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(varDeclNode, maketreeWithVal(IDENTIFIER, index));
                    addChild(varDeclNode, maketreeWithVal(INTEGER, $4));
                    $$ = varDeclNode;
                 }
                | typeSpecifier ID SEMICLN
                 {
                    tree* varDeclNode = maketree(VARDECL);
                    addChild(varDeclNode, $1);
                    int index = ST_insert($2, scope, $1->val, 0);
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(varDeclNode, maketreeWithVal(IDENTIFIER, index));
                    $$ = varDeclNode;
                 }
                ;
                
typeSpecifier   : KWD_INT
                 {
                    $$ = maketreeWithVal(TYPESPEC, INT_TYPE);
                 }
                | KWD_CHAR
                 {
                    $$ = maketreeWithVal(TYPESPEC, CHAR_TYPE);
                 }
                | KWD_VOID
                 {
                    $$ = maketreeWithVal(TYPESPEC, VOID_TYPE);
                 }
                ;

funDecl         : funHeader LPAREN formalDeclList RPAREN funBody
                 {
                    tree* funDeclNode = maketree(FUNDECL);
                    addChild(funDeclNode, $1);
                    addChild(funDeclNode, $3);
                    addChild(funDeclNode, $5);
                    updateScope("");
                    $$ = funDeclNode;
                 }
                | funHeader LPAREN RPAREN funBody
                 {
                    tree* funDeclNode = maketree(FUNDECL);
                    addChild(funDeclNode, $1);
                    addChild(funDeclNode, $4);
                    updateScope("");
                    $$ = funDeclNode;
                 }
                ;

funHeader         : typeSpecifier ID
                 {
                    tree* funHeaderNode = maketree(FUNHEADER);
                    addChild(funHeaderNode, $1);
                    int index = ST_insert($2, scope, $1->val, 2);
                    updateScope($2);
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(funHeaderNode, maketreeWithVal(IDENTIFIER, index));
                    $$ = funHeaderNode;
                 }
                ;

formalDeclList  : formalDecl
                 {
                    tree* formalDeclListNode = maketree(FORMALDECLLIST);
                    addChild(formalDeclListNode, $1);
                    $$ = formalDeclListNode;
                 }
                | formalDecl COMMA formalDeclList
                 {
                    tree* formalDeclListNode = maketree(FORMALDECLLIST);
                    addChild(formalDeclListNode, $1);
                    addChild(formalDeclListNode, $3);
                    $$ = formalDeclListNode;
                 }
                ;    

formalDecl      : typeSpecifier ID
                 {
                    tree* formalDeclNode = maketree(FORMALDECL);
                    addChild(formalDeclNode, $1);
                    int index = ST_insert($2, scope, $1->val, 0);
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(formalDeclNode, maketreeWithVal(IDENTIFIER, index));
                    $$ = formalDeclNode;
                 }
                | typeSpecifier ID LSQ_BRKT RSQ_BRKT
                 {
                    tree* formalDeclNode = maketree(FORMALDECL);
                    addChild(formalDeclNode, $1);
                    int index = ST_insert($2, scope, $1->val, 1);
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(formalDeclNode, maketreeWithVal(IDENTIFIER, index));
                    $$ = formalDeclNode;
                 }
                ;      

funBody         : LCRLY_BRKT localDeclList statementList RCRLY_BRKT
                 {
                    tree* funBodyNode = maketree(FUNBODY);
                    addChild(funBodyNode, $2);
                    addChild(funBodyNode, $3);
                    $$ = funBodyNode;
                 }
                ;  

localDeclList   : 
                  {
                    tree* localDeclListNode = maketree(LOCALDECLLIST);
                    $$ = localDeclListNode;
                  }
                | varDecl localDeclList
                 {
                    tree* localDeclListNode = maketree(LOCALDECLLIST);
                    addChild(localDeclListNode, $1);
                    addChild(localDeclListNode, $2);
                    $$ = localDeclListNode;
                 }
                ;  

statementList   : 
                 {
                    tree* statementListNode = maketree(STATEMENTLIST);
                    $$ = statementListNode;
                 }
                | statement statementList
                 {
                    tree* statementListNode = maketree(STATEMENTLIST);
                    addChild(statementListNode, $1);
                    addChild(statementListNode, $2);
                    $$ = statementListNode;
                 }
                ;

statement       : compoundStmt
                 {
                    tree* statementNode = maketree(STATEMENT);
                    addChild(statementNode, $1);
                    $$ = statementNode;
                 }
                | assignStmt
                 {
                    tree* statementNode = maketree(STATEMENT);
                    addChild(statementNode, $1);
                    $$ = statementNode;
                 }
                | condStmt
                 {
                    tree* statementNode = maketree(STATEMENT);
                    addChild(statementNode, $1);
                    $$ = statementNode;
                 }
                | loopStmt
                 {
                    tree* statementNode = maketree(STATEMENT);
                    addChild(statementNode, $1);
                    $$ = statementNode;
                 }
                | returnStmt
                 {
                    tree* statementNode = maketree(STATEMENT);
                    addChild(statementNode, $1);
                    $$ = statementNode;
                 }
                ;

compoundStmt    : LCRLY_BRKT statementList RCRLY_BRKT
                 {
                    tree* compoundStmtNode = maketree(COMPOUNDSTMT);
                    addChild(compoundStmtNode, $2);
                    $$ = compoundStmtNode;
                 }
                ;              

assignStmt      : var OPER_ASGN expression SEMICLN
                 {
                    tree* assignStmtNode = maketree(ASSIGNSTMT);
                    addChild(assignStmtNode, $1);
                    addChild(assignStmtNode, $3);
                    $$ = assignStmtNode;
                 }
                | expression SEMICLN
                 {
                    tree* assignStmtNode = maketree(ASSIGNSTMT);
                    addChild(assignStmtNode, $1);
                    $$ = assignStmtNode;
                 }
                ;

condStmt        : KWD_IF LPAREN expression RPAREN statement
                 {
                    tree* condStmtNode = maketree(CONDSTMT);
                    addChild(condStmtNode, $3);
                    addChild(condStmtNode, $5);
                    $$ = condStmtNode;
                 }
                | KWD_IF LPAREN expression RPAREN statement KWD_ELSE statement
                 {
                    tree* condStmtNode = maketree(CONDSTMT);
                    addChild(condStmtNode, $3);
                    addChild(condStmtNode, $5);
                    addChild(condStmtNode, $7);
                    $$ = condStmtNode;
                 }
                ;

loopStmt        : KWD_WHILE LPAREN expression RPAREN statement
                 {
                    tree* loopStmtNode = maketree(LOOPSTMT);
                    addChild(loopStmtNode, $3);
                    addChild(loopStmtNode, $5);
                    $$ = loopStmtNode;
                 }
                ;

returnStmt      : KWD_RETURN SEMICLN
                 {
                  tree* returnStmtNode = maketree(RETURNSTMT);
                    $$ = returnStmtNode;
                 }
                | KWD_RETURN expression SEMICLN
                 {
                    tree* returnStmtNode = maketree(RETURNSTMT);
                    addChild(returnStmtNode, $2);
                    $$ = returnStmtNode;
                 }
                ;

var             : ID
                 {
                    int index = ST_lookup($1, scope);
                    if (index == -1){
                        index = yywarning("Undeclared Variable.");
                    }
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    $$ = maketreeWithVal(IDENTIFIER, index);
                 }
                | ID LSQ_BRKT addExpr RSQ_BRKT
                 {
                    tree* varNode = maketree(VAR);
                    int index = ST_lookup($1, scope);
                    if (index == -1){
                        index = yywarning("Undeclared Variable.");
                    }
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(varNode, maketreeWithVal(IDENTIFIER, index));
                    addChild(varNode, $3);
                    $$ = varNode;
                 }
                ;

expression      : addExpr
                 {
                    tree* expressionNode = maketree(EXPRESSION);
                    addChild(expressionNode, $1);
                    $$ = expressionNode;
                 }
                | expression relop addExpr
                 {
                    tree* expressionNode = maketree(EXPRESSION);
                    addChild(expressionNode, $1);
                    addChild(expressionNode, $2);
                    addChild(expressionNode, $3);
                    $$ = expressionNode;
                 }
                ;

relop           : OPER_LTE
                 {
                   $$ = maketreeWithVal(RELOP, OPER_LTE);
                 }
                | OPER_LT
                 {
                   $$ = maketreeWithVal(RELOP, OPER_LT);
                 }
                | OPER_GT
                 {
                   $$ = maketreeWithVal(RELOP, OPER_GT); 
                 }
                | OPER_GTE
                 {
                   $$ = maketreeWithVal(RELOP, OPER_GTE); 
                 }
                | OPER_EQ
                 {
                   $$ = maketreeWithVal(RELOP, OPER_EQ); 
                 }
                | OPER_NEQ
                 {
                  $$ = maketreeWithVal(RELOP, OPER_NEQ); 
                 }
                ;

addExpr         : term
                 {
                    tree* addExprNode = maketree(ADDEXPR);
                    addChild(addExprNode, $1);
                    $$ = addExprNode;
                 }
                | addExpr addop term
                 {
                    tree* addExprNode = maketree(ADDEXPR);
                    addChild(addExprNode, $1);
                    addChild(addExprNode, $2);
                    addChild(addExprNode, $3);
                    $$ = addExprNode;
                 }
                ;

addop           : OPER_ADD
                 {
                    $$ = maketreeWithVal(ADDOP, OPER_ADD);
                 }
                | OPER_SUB
                 {
                    $$ = maketreeWithVal(ADDOP, OPER_SUB);
                 }
                ;

term            : factor
                 {
                    tree* termNode = maketree(TERM);
                    addChild(termNode, $1);
                    $$ = termNode;
                 }
                | term mulop factor
                 {
                    tree* termNode = maketree(TERM);
                    addChild(termNode, $1);
                    addChild(termNode, $2);
                    addChild(termNode, $3);
                    $$ = termNode;
                 }
                ;

mulop            : OPER_MUL
                 {
                    $$ = maketreeWithVal(MULOP, OPER_MUL);
                 }
                 | OPER_DIV
                 {
                    $$ = maketreeWithVal(MULOP, OPER_DIV);
                 }
                ;

factor          : LPAREN expression RPAREN
                 {
                    tree* factorNode = maketree(FACTOR);
                    addChild(factorNode, $2);
                    $$ = factorNode;
                 }
                | var
                 {
                    tree* factorNode = maketree(FACTOR);
                    addChild(factorNode, $1);
                    $$ = factorNode;
                 }
                | funcCallExpr
                 {
                    tree* factorNode = maketree(FACTOR);
                    addChild(factorNode, $1);
                    $$ = factorNode;
                 }
                | INTCONST
                 {
                    $$ = maketreeWithVal(INTEGER, $1);
                 }
                | CHARCONST
                 {
                    $$ = maketreeWithVal(CHAR, $1);
                 }
                | STRCONST
                 {
                    $$ = maketreeWithVal(STRCONST, $1);
                 }
                ;

funcCallExpr    : ID LPAREN argList RPAREN
                 {
                    tree* funcCallExprNode = maketree(FUNCCALLEXPR);
                    int index = ST_lookup($1, scope);
                    if (index == -1){
                        index = yywarning("Undeclared Variable.");
                    }
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(funcCallExprNode, maketreeWithVal(IDENTIFIER, index));
                    addChild(funcCallExprNode, $3);
                    $$ = funcCallExprNode;
                 }
                | ID LPAREN RPAREN
                 {
                    tree* funcCallExprNode = maketree(FUNCCALLEXPR);
                    int index = ST_lookup($1, scope);
                    if (index == -1){
                        index = yywarning("Undeclared Variable.");
                    }
                    if (index == -2){
                        index = yywarning("Symbol Table is Full.");
                    }
                    addChild(funcCallExprNode, maketreeWithVal(IDENTIFIER, index));
                    $$ = funcCallExprNode;
                 }
                ;

argList         : expression
                 {
                    tree* argListNode = maketree(ARGLIST);
                    addChild(argListNode, $1);
                    $$ = argListNode;
                 }
                | argList COMMA expression
                 {
                    tree* argListNode = maketree(ARGLIST);
                    addChild(argListNode, $1);
                    addChild(argListNode, $3);
                    $$ = argListNode;
                 }
                ;

%%

int yywarning(const char * msg){
    printf("warning: line %d: %s\n", yylineno, msg);
    return -1;
}

int yyerror(const char * msg){
    printf("error: line %d: %s\n", yylineno, msg);
    return -1;
}

void updateScope(char* nextScope){
   scope = nextScope;
}
