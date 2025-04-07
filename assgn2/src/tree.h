#ifndef TREE_H
#define TREE_H

#define MAXCHILDREN 12

#include "strtab.h"  // Moved here if tree.h uses strtab.h symbols

/* Tree node structure */
typedef struct treenode tree;

/* Tree node definition */
struct treenode {
    int nodeKind;                    /* Type of the node as an integer */
    int val;                         /* Integer value */
    int numChildren;                 /* Number of children */
    tree *parent;                    /* Pointer to parent node */
    tree *children[MAXCHILDREN];     /* Array of child node pointers */
};

/* Pointer to AST root */
extern tree *ast;

/* Declaration of the types array */
extern char* types[3];  

/* Function Prototypes */

/* Builds a subtree with zero children (nodeKind as an int parameter) */
tree *maketree(int kind);

/* Builds a subtree with a leaf node holding an integer value */
tree *maketreeWithVal(int kind, int val);

/* Assigns the subtree rooted at 'child' as a child of the subtree rooted at 'parent'. Also assigns the 'parent' node as the 'child->parent'. */
void addChild(tree *parent, tree *child);

/* Prints the AST recursively starting from the root of the AST. This function prints warnings or node information based on node type. */
void printAst(tree *root, int nestLevel);

/* Frees the memory allocated for the AST */
void freeAst(tree *root);

#endif /* TREE_H */
