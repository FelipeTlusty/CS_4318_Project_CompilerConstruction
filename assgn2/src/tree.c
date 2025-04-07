#include "tree.h"    // strtab.h is included via tree.h
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Pointer to AST root */
tree *ast = NULL;

/* 
 * Function: maketree
 * -------------------
 * Creates a new tree node with the specified kind and no semantic value.
 *
 * kind: The type of the node (as an integer from parser.y's nodeTypes enum).
 *
 * returns: Pointer to the newly created tree node.
 */
tree *maketree(int kind) {
    tree *newNode = (tree *)malloc(sizeof(tree));
    if (!newNode) {
        fprintf(stderr, "Memory allocation failed for new tree node.\n");
        exit(EXIT_FAILURE);
    }
    newNode->nodeKind = kind;    // Assign integer directly
    newNode->val = 0;            // Initialize as 0 since val is an integer
    newNode->numChildren = 0;
    newNode->parent = NULL;

    // Initialize all child pointers to NULL
    for (int i = 0; i < MAXCHILDREN; i++) {
        newNode->children[i] = NULL;
    }
    return newNode;
}

/* 
 * Function: maketreeWithVal
 * -------------------------
 * Creates a new tree node with the specified kind and an integer semantic value.
 *
 * kind: The type of the node (as an integer from parser.y's nodeTypes enum).
 * val: The semantic value to store in the node as an integer.
 *
 * returns: Pointer to the newly created tree node.
 */
tree *maketreeWithVal(int kind, int val) {
    tree *newNode = maketree(kind);  // Create a new tree node
    newNode->val = val;              // Store the integer value directly in newNode->val
    return newNode;
}

/* 
 * Function: addChild
 * ------------------
 * Adds a child node to a parent node and sets the parent reference in the child.
 *
 * parent: Pointer to the parent tree node.
 * child: Pointer to the child tree node to be added.
 */
void addChild(tree *parent, tree *child) {
    if (parent->numChildren >= MAXCHILDREN) {
        fprintf(stderr, "Exceeded maximum number of children (%d) for nodeKind %d.\n", MAXCHILDREN, parent->nodeKind);
        exit(EXIT_FAILURE);
    }
    parent->children[parent->numChildren++] = child;
    child->parent = parent;
}

/* 
 * Function: getSymbol
 * -------------------
 * Helper function to get the string representation of terminal nodes.
 *
 * kind: The kind of the node.
 * val: The value of the node.
 *
 * returns: Pointer to the string representation of the symbol.
 */
const char* getSymbol(int kind, int val) {
    switch (kind) {
        case 26:  return "INTEGER_CONST";
        case 27:  return "IDENTIFIER";
        case 28:  return "VAR";
        case 29:  return "ARRAYDECL";
        case 30:  return "CHAR_CONST";
        case 31:  return "FUNCTYPENAME";
        default:  return "<Unknown Symbol>";
    }
}

/* 
 * Function: printAst
 * ------------------
 * Recursively prints the AST starting from the given node with indentation.
 *
 * root: Pointer to the current tree node.
 * nestLevel: Current indentation level (number of spaces).
 */
void printAst(tree *root, int nestLevel) {
    if (root == NULL) return;

    // Print indentation
    for (int i = 0; i < nestLevel; i++) {
        printf("  "); // Two spaces per level
    }

    // Print node information based on its kind
    switch (root->nodeKind) {
        /* Non-Terminal Nodes */
        case 0:  printf("program\n"); break;
        case 1:  printf("declList\n"); break;
        case 2:  printf("decl\n"); break;
        case 3:  printf("varDecl\n"); break;
        case 4:  // typeSpecifier
            switch (root->val) {
                case INT_TYPE:   printf("typeSpecifier,int\n"); break;
                case CHAR_TYPE:  printf("typeSpecifier,char\n"); break;
                case VOID_TYPE:  printf("typeSpecifier,void\n"); break;
                default: printf("typeSpecifier,unknown\n"); break; // Handle unknown types
            }
            break;
        case 5:  printf("funDecl\n"); break;
        case 6:  printf("formalDeclList\n"); break;
        case 7:  printf("formalDecl\n"); break;
        case 8:  printf("funBody\n"); break;
        case 9:  printf("localDeclList\n"); break;
        case 10: printf("statementList\n"); break;
        case 11: printf("statement\n"); break;
        case 12: printf("compoundStmt\n"); break;
        case 13: printf("assignStmt\n"); break;
        case 14: printf("condStmt\n"); break;
        case 15: printf("loopStmt\n"); break;
        case 16: printf("returnStmt\n"); break;
        case 17: printf("expression\n"); break;
        case 32: printf("funHeader\n"); break;

        case 18: 
            switch (root->val) {
                case 270: printf("relop,<=\n"); break;
                case 271: printf("relop,>=\n"); break;
                case 272: printf("relop,<\n"); break;
                case 273: printf("relop,>\n"); break;
                case 274: printf("relop,==\n"); break;
                case 275: printf("relop,!=\n"); break;
                default:  printf("relop,unknown\n"); break;
            }
            break;

        case 19: printf("addExpr\n"); break;
        case 20: 
            switch (root->val) {
                case 266: printf("addop,+\n"); break;
                case 267: printf("addop,-\n"); break;
                default:  printf("addop,unknown\n"); break;
            }
            break;

        case 21: printf("term\n"); break;
        case 22: 
            switch (root->val) {
                case 268: printf("mulop,*\n"); break;
                case 269: printf("mulop,/\n"); break;
                default:  printf("mulop,unknown\n"); break;
            }
            break;
            
        case 23: printf("factor\n"); break;
        case 24: printf("funcCallExpr\n"); break;
        case 25: printf("argList\n"); break;

        /* Terminals */
        case 26: printf("integer,%d\n", root->val); break;
        case 27: printf("identifier,%d\n", root->val); break;
        case 28: printf("var,%d\n", root->val); break;
        case 29: printf("arrayDecl,%d\n", root->val); break;
        case 30: printf("char,%d\n", root->val); break;
        case 31: printf("funcTypeName,%d\n", root->val); break;

        /* Default Case */
        default: printf("<Unknown NodeKind %d, Val: %d>\n", root->nodeKind, root->val); break;
    }

    // Recursively print all children
    for (int i = 0; i < root->numChildren; i++) {
        printAst(root->children[i], nestLevel + 1);
    }
}

/* 
 * Function: printSymbolTable
 * ---------------------------
 * Prints the symbol table in the specified format.
 *
 * symbolTable: Pointer to the symbol table (assumed to be an array of identifiers).
 * numSymbols: The number of symbols in the table.
 */
void printSymbolTable(const char* symbolTable[], int numSymbols) {
    printf("\nSYMBOL TABLE:\n");
    for (int i = 0; i < numSymbols; i++) {
        printf("    %d: %s\n", i + 1, symbolTable[i]);
    }
}

/* 
 * Function: freeAst
 * -----------------
 * Recursively frees the memory allocated for the AST.
 *
 * root: Pointer to the current tree node.
 */
void freeAst(tree *root) {
    if (root == NULL) return;

    // Recursively free all child nodes
    for (int i = 0; i < root->numChildren; i++) {
        freeAst(root->children[i]);
    }

    // Free the node itself
    free(root);
}
