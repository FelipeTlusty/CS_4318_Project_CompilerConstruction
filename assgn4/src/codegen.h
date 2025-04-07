#ifndef CODEGEN_H
#define CODEGEN_H

#include "strtab.h" 
#include "tree.h" 

// Function that will recursively generate code from the ast root.
void generateCode(tree* node);

// Function to setup pointers and registers at function start.
void setupPtrs();

// Function to reset pointers and registers at function end.
void reloadPtrs();

// Sub-function that will generate code for expressions from the ast.
int expr(tree* node);

// Sub-function that will generate code for assignment statements from the ast.
void assgnStmt(tree* node);

// Sub-function that will generate code for conditional statements from the ast.
void condStmt(tree* node);

// Sub-function that will generate code for iterative statements from the ast.
void iterativeStmt(tree* node);

// Sub-function that will generate code for functions from the ast.
void func(tree* node);

// Sub-function that will generate code for function call expressions from the ast.
int funcCallExpr(tree* node);

#endif
