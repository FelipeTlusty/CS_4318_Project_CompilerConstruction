%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<../src/tree.h>
#include<../src/strtab.h>

#define MAXCALLS 100

extern int yylineno;
/* nodeTypes refer to different types of internal and external nodes that can be part of the abstract syntax tree.*/
enum nodeTypes {PROGRAM, DECLLIST, DECL, VARDECL, TYPESPEC, FUNDECL,
                FORMALDECLLIST, FORMALDECL, FUNBODY, LOCALDECLLIST,
                STATEMENTLIST, STATEMENT, COMPOUNDSTMT, ASSIGNSTMT,
                CONDSTMT, LOOPSTMT, RETURNSTMT, EXPRESSION, RELOP,
                ADDEXPR, ADDOP, TERM, MULOP, FACTOR, FUNCCALLEXPR,
                ARGLIST, INTEGER, IDENTIFIER, VAR, ARRAYDECL, CHAR,
                FUNCTYPENAME};

enum opType {ADD, SUB, MUL, DIV, LT, LTE, EQ, GTE, GT, NEQ};

int funcParams[MAXCALLS];
int paramCount = 0;
char* scopeId = "global";
int scopeLevel = 0;
tree* funDeclNode;

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
                    if(!current_scope){
                        new_scope();
                    }
                    int index = ST_insert($2, scopeId, $1->val, 1, $4);
                    if (index == -1){
                        index = yyerror("Multiply Declared Variable.");
                    }
                    else{
                        if ($4 <= 0){
                           index = yyerror("Array Declared With Size of 0.");
                        }
                    }
                    addChild(varDeclNode, maketreeWithVal(IDENTIFIER, index, $2));
                    addChild(varDeclNode, maketreeWithVal(INTEGER, $4, ""));
                    $$ = varDeclNode;
                 }
                | typeSpecifier ID SEMICLN
                 {
                    tree* varDeclNode = maketree(VARDECL);
                    if(!current_scope){
                        new_scope();
                    }
                    int index = ST_insert($2, scopeId, $1->val, 0, 0);
                    if (index == -1){
                        index = yyerror("Multiply Declared Variable.");
                    }
                    addChild(varDeclNode, $1);
                    addChild(varDeclNode, maketreeWithVal(IDENTIFIER, index, $2));
                    $$ = varDeclNode;
                 }
                ;
                
typeSpecifier   : KWD_INT
                 {
                    $$ = maketreeWithVal(TYPESPEC, INT_TYPE, "");
                 }
                | KWD_CHAR
                 {
                    $$ = maketreeWithVal(TYPESPEC, CHAR_TYPE, "");
                 }
                | KWD_VOID
                 {
                    $$ = maketreeWithVal(TYPESPEC, VOID_TYPE, "");
                 }
                ;

funDecl         : typeSpecifier ID LPAREN
                 {
                    funDeclNode = maketree(FUNDECL);
                    addChild(funDeclNode, $1);
                    if(!current_scope){
                        new_scope();
                    }
                    int index = ST_insert($2, scopeId, $1->val, 2, 0);
                    if (index == -1){
                        index = yyerror("Symbol Declared Multiple Times.");
                    }
                    else{
                        new_scope();
                        updateScope($2);
                        scopeLevel++;
                    }
                    addChild(funDeclNode, maketreeWithVal(IDENTIFIER, index, $2));
                 }
                  formalDeclList RPAREN funBody
                 {
                    addChild(funDeclNode, $5);
                    addChild(funDeclNode, $7);
                    up_scope();
                    updateScope("global");
                    scopeLevel--;
                    $$ = funDeclNode;
                 }
                | typeSpecifier ID LPAREN
                 {
                    funDeclNode = maketree(FUNDECL);
                    addChild(funDeclNode, $1);
                    if(!current_scope){
                        new_scope();
                    }
                    int index = ST_insert($2, scopeId, $1->val, 2, 0);
                    if (index == -1){
                        index = yyerror("Symbol Declared Multiple Times.");
                    }
                    else{
                        new_scope();
                        updateScope($2);
                        scopeLevel++;
                    }
                    addChild(funDeclNode, maketreeWithVal(IDENTIFIER, index, $2));
                 }
                  RPAREN funBody
                 {
                    addChild(funDeclNode, $6);
                    up_scope();
                    updateScope("global");
                    scopeLevel--;
                    $$ = funDeclNode;
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
                    if(!current_scope){
                        new_scope();
                    }
                    int index = ST_insert($2, scopeId, $1->val, 0, 0);
                    symEntry* tempEntry = ST_lookup(scopeId);
                    if (index == -1){
                        index = yywarning("Symbol Declared Multiple Times");
                    }
                    else{
                        add_param(tempEntry, $1->val, 0);
                        addChild(formalDeclNode, maketreeWithVal(IDENTIFIER, index, $2));
                    }
                    $$ = formalDeclNode;
                 }
                | typeSpecifier ID LSQ_BRKT RSQ_BRKT
                 {
                    tree* formalDeclNode = maketree(FORMALDECL);
                    addChild(formalDeclNode, $1);
                    if(!current_scope){
                        new_scope();
                    }
                    int index = ST_insert($2, scopeId, $1->val, 1, 0);
                    symEntry* tempEntry = ST_lookup(scopeId);
                    if (index == -1){
                        index = yywarning("Symbol Declared Multiple Times");
                    }
                    else{
                        add_param(tempEntry, $1->val, 1);
                        addChild(formalDeclNode, maketreeWithVal(IDENTIFIER, index, $2));
                    }
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
                    tree* temp1 = assignStmtNode->children[0];
                    while (temp1->children[0]){
                        temp1 = temp1->children[0];
                    }
                    if (temp1->nodeKind != IDENTIFIER){
                        yyerror("Assigning Value to a Non Variable Element.");
                    }
                    else{
                        symEntry* tempEntry = ST_lookup(temp1->id);
                        if (tempEntry != NULL){
                           int varType = tempEntry->data_type;
                           tree* temp2 = assignStmtNode->children[1];
                           getTypes(temp2);
                           for (int i = 0; i < paramCount; i++){
                              if (funcParams[i] != varType){
                                 yyerror("Type Mismatch in Assignment.");
                              }
                           }
                        }
                    }
                    resetParams();
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
                    symEntry* tempEntry = ST_lookup($1);
                    if (tempEntry == NULL){
                        yyerror("Undeclared Variable.");
                        $$ = maketreeWithVal(IDENTIFIER, -1, $1);
                    }
                    else{
                        $$ = maketreeWithVal(IDENTIFIER, tempEntry->entry, $1);
                    }
                 }
                | ID LSQ_BRKT addExpr RSQ_BRKT
                 {
                    tree* varNode = maketree(VAR);
                    symEntry* tempEntry = ST_lookup($1);

                    if (tempEntry == NULL){
                        yyerror("Undeclared Variable.");
                    }
                    else{

                        addChild(varNode, maketreeWithVal(IDENTIFIER, tempEntry->entry, $1));
                        addChild(varNode, $3);

                        if(tempEntry->symbol_type != ARRAY){                      
                           yyerror("Non-array Identifier Used as an Array.");
                        }
                        else{
                           if($3->nodeKind == IDENTIFIER){
                              symEntry* tempID = ST_lookup($3->id);
                              if (tempID->data_type != INT_TYPE){
                                 yyerror("Indexing an Array With a Non-Integer Type.");
                              }
                           }
                           else{
                              if($3->nodeKind != INTEGER){
                                 yyerror("Indexing an Array With a Non-Integer Type.");
                              }
                              else{
                                 if(tempEntry->size <= $3->val){
                                    yyerror("Indexing Array With an Out of Bounds Literal.");
                                 }
                              }
                           }
                        }
                    }
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
                   $$ = maketreeWithVal(RELOP, OPER_LTE, "");
                 }
                | OPER_LT
                 {
                   $$ = maketreeWithVal(RELOP, OPER_LT, "");
                 }
                | OPER_GT
                 {
                   $$ = maketreeWithVal(RELOP, OPER_GT, ""); 
                 }
                | OPER_GTE
                 {
                   $$ = maketreeWithVal(RELOP, OPER_GTE, ""); 
                 }
                | OPER_EQ
                 {
                   $$ = maketreeWithVal(RELOP, OPER_EQ, ""); 
                 }
                | OPER_NEQ
                 {
                  $$ = maketreeWithVal(RELOP, OPER_NEQ, ""); 
                 }
                ;

addExpr         : term
                 {
                    $$ = $1;
                 }
                | addExpr addop term
                 {
                    if (($1->nodeKind == INTEGER || $1->nodeKind == CHAR) && ($3->nodeKind == INTEGER || $3->nodeKind == CHAR)){
                        int sum = 0;
                        if($2->val == OPER_ADD){
                              sum = $1->val + $3->val;
                        }
                        else{
                              sum = $1->val - $3->val;
                        }
                        if ($1->nodeKind == $3->nodeKind){
                           if ($1->nodeKind == INTEGER){
                              $$ = maketreeWithVal(INTEGER, sum, "");
                           }
                           else{
                              $$ = maketreeWithVal(CHAR, sum, "");
                           }
                        }
                        else{
                           $$ = maketreeWithVal(INTEGER, sum, "");
                        }
                    }
                    else{
                        tree* addExprNode = maketree(ADDEXPR);
                        addChild(addExprNode, $1);
                        addChild(addExprNode, $2);
                        addChild(addExprNode, $3);
                        $$ = addExprNode;
                    }
                 }
                ;

addop           : OPER_ADD
                 {
                    $$ = maketreeWithVal(ADDOP, OPER_ADD, "");
                 }
                | OPER_SUB
                 {
                    $$ = maketreeWithVal(ADDOP, OPER_SUB, "");
                 }
                ;

term            : factor
                 {
                    $$ = $1;
                 }
                | term mulop factor
                {
                    if (($1->nodeKind == INTEGER || $1->nodeKind == CHAR) && ($3->nodeKind == INTEGER || $3->nodeKind == CHAR)){
                        int product = 0;
                        if($2->val == OPER_ADD){
                              product = $1->val * $3->val;
                        }
                        else{
                              product = $1->val / $3->val;
                        }
                        if ($1->nodeKind == $3->nodeKind){
                           if ($1->nodeKind == INTEGER){
                              $$ = maketreeWithVal(INTEGER, product, "");
                           }
                           else{
                              $$ = maketreeWithVal(CHAR, product, "");
                           }
                        }
                        else{
                           $$ = maketreeWithVal(INTEGER, product, "");
                        }
                    }
                    else{
                        tree* termNode = maketree(TERM);
                        addChild(termNode, $1);
                        addChild(termNode, $2);
                        addChild(termNode, $3);
                        $$ = termNode;
                    }
                 }
                ;

mulop            : OPER_MUL
                 {
                    $$ = maketreeWithVal(MULOP, OPER_MUL, "");
                 }
                 | OPER_DIV
                 {
                    $$ = maketreeWithVal(MULOP, OPER_DIV, "");
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
                    $$ = maketreeWithVal(INTEGER, $1, "");
                 }
                | CHARCONST
                 {
                    $$ = maketreeWithVal(CHAR, $1, "");
                 }
                | STRCONST
                 {
                    $$ = maketreeWithVal(STRCONST, $1, "");
                 }
                ;

funcCallExpr    : ID LPAREN argList RPAREN
                 {
                    tree* funcCallExprNode = maketree(FUNCCALLEXPR);
                    symEntry* tempEntry = ST_lookup($1);
                    if (tempEntry == NULL){
                        yyerror("Undefined Function.");
                    }
                    else{
                        addChild(funcCallExprNode, maketreeWithVal(IDENTIFIER, tempEntry->entry, $1));
                        addChild(funcCallExprNode, $3);
                        tree* temp = funcCallExprNode->children[1];
                        countParams(temp);
                        if (paramCount != tempEntry->size){
                           if (paramCount > tempEntry->size){
                              yyerror("Too Many Parameters in Function Call.");
                           }
                           else{
                              yyerror("Too Few Parameters in Function Call.");
                           }
                        }
                        else{
                           getTypesFunc(temp);
                           param* tempParam = tempEntry->params;
                           param* callParam = working_list_head;
                           while(tempParam){
                              if(tempParam->data_type != callParam->data_type || tempParam->symbol_type != callParam->symbol_type){
                                 yyerror("Parameter Mismatch in Function Call.");
                                 break;
                              }
                              else{
                                 tempParam = tempParam->next;
                                 callParam = callParam->next;
                              }
                           }
                        }
                        resetParams();
                    }
                    $$ = funcCallExprNode;
                 }
                | ID LPAREN RPAREN
                 {
                    tree* funcCallExprNode = maketree(FUNCCALLEXPR);
                    symEntry* tempEntry = ST_lookup($1);

                    if (tempEntry == NULL){
                        yyerror("Undefined Function.");
                        addChild(funcCallExprNode, maketreeWithVal(IDENTIFIER, -1, $1));
                    }
                    else{
                        addChild(funcCallExprNode, maketreeWithVal(IDENTIFIER, tempEntry->entry, $1));
                        if (tempEntry->size > 0){
                           yyerror("Too Few Parameters.");
                        }
                    }
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
   scopeId = nextScope;
}

// function to get the number of parameters being called by a function call.
void countParams(tree* tempTree){ 
   if (tempTree->nodeKind == IDENTIFIER){
      paramCount += 1;
   }
   for (int i = 0; i < tempTree->numChildren; i++){
      countParams(tempTree->children[i]);
   }
}

// function to get param types from function call
void getTypes(tree* tempTree){
   //flag used if elements count grows too large.
   if (paramCount >= MAXCALLS){
      printf("Error: Equation has Too Many Parameters.");
   }
   else{
      if (tempTree->nodeKind == IDENTIFIER){
            symEntry* tempEntry = ST_lookup(tempTree->id);
            funcParams[paramCount] = tempEntry->data_type;
            paramCount += 1;
         }
         else{
            if (tempTree->nodeKind == INT_TYPE){
               funcParams[paramCount] = 0;
               paramCount += 1;
            }
            else{
               if (tempTree->nodeKind == CHAR_TYPE){
                  funcParams[paramCount] = 1;
                  paramCount += 1;
               }
               else{
                  if (tempTree->nodeKind == VOID_TYPE){
                     funcParams[paramCount] = 2;
                     paramCount += 1;
                  }
               }
            }
         }
      for (int i = 0; i < tempTree->numChildren; i++){
         getTypes(tempTree->children[i]);
      }
   }
}

// searches for function call params and adds them to a param linked list to be used for comparison with the function definition.
void getTypesFunc(tree* tempTree){
   if (tempTree->nodeKind == IDENTIFIER){
      symEntry* tempEntry = ST_lookup(tempTree->id);
      param *new_param = (param *)malloc(sizeof(param));
      new_param->data_type = tempEntry->data_type;
      new_param->symbol_type = tempEntry->symbol_type;
      new_param->next = NULL;

      if(!working_list_head){
         working_list_head = new_param;
      }
      else{
         param* current = working_list_head;
         while(current->next){
            current = current->next;
         }
         current->next = new_param;
      }
   }
   for (int i = 0; i < tempTree->numChildren; i++){
      getTypesFunc(tempTree->children[i]);
   }
}

// resets variables to 0 and frees any memory allocated for function params.
void resetParams(){
   paramCount = 0;
   for (int i = 0; i < 20; i++){
      funcParams[i] = 0;
   }
   if (working_list_head){
      while(working_list_head){
         param* temp = working_list_head;
         working_list_head = working_list_head->next;
         free(temp);
      }
   }
}
