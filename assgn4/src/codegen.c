#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "codegen.h"

char* registerArray[8] = {"s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7"};
int regNum = 0;
int condCount = 1;
char* globalVars[10]; // using a small number as it is only for small programs
int globalNum = 0;
int loopCount = 0;  // Counter for unique labels

enum nodeTypes {
    PROGRAM, DECLLIST, DECL, VARDECL, TYPESPEC, FUNDECL,
    FORMALDECLLIST, FORMALDECL, FUNBODY, LOCALDECLLIST,
    STATEMENTLIST, STATEMENT, COMPOUNDSTMT, ASSIGNSTMT,
    CONDSTMT, LOOPSTMT, RETURNSTMT, EXPRESSION, RELOP,
    ADDEXPR, ADDOP, TERM, MULOP, FACTOR, FUNCCALLEXPR,
    ARGLIST, INTEGER, IDENTIFIER, VAR, ARRAYDECL, CHAR,
    FUNCTYPENAME
};

int flag = 0;

void nextReg(){
    regNum++;
    if (regNum > 7) {
        regNum = 0; // Resetting register number in case it exceeds 8
    } 
}

// Function that recursively generates code from the AST root
void generateCode(tree* node) {
    if (node == NULL) {
        return;
    }

    switch (node->nodeKind) {
        case PROGRAM:
            // Program-level initialization
            printf("# Global variable allocations:\n.data\n");
            flag = 0; // Reset flag for program start
            for (int i = 0; i < node->numChildren; i++) {
                generateCode(node->children[i]);
            }
            printf("# Output function\n");
            printf("startoutput:\n");
            printf("\t# Put argument in the output register\n");
            printf("\tlw $a0, 4($sp)\n");
            printf("\t# print int is syscall 1\n");
            printf("\tli $v0, 1\n");
            printf("\tsyscall\n");
            printf("\t# jump back to caller\n");
            printf("\tjr $ra\n");
            break;

        case VARDECL:
            // Handle global variable declarations
            if (flag == 0 && node->children[1] && node->children[1]->id) {
                printf("var%s:\t.word 0\n", node->children[1]->id);
                globalVars[globalNum] = node->children[1]->id;
                globalNum++;
            }
            break;

        case FUNDECL:
            // Handle function declarations
            if (flag == 0) {
                printf("\n.text\n");
                printf("\tjal startmain\n");
                printf("\tli $v0, 10\n");
                printf("\tsyscall\n");
                flag++;
            }
            func(node); // Process function declaration
            break;

        case FUNCCALLEXPR:
            // Handle function calls
            funcCallExpr(node);
            break;

        case CONDSTMT:
            // Handle conditional statements
            condStmt(node);
            break;

        case LOOPSTMT:
            // Handle iterative statements
            iterativeStmt(node);
            break;

        default:
            // Recursively process children nodes
            for (int i = 0; i < node->numChildren; i++) {
                generateCode(node->children[i]);
            }
            break;
    }
}

// Function to set up pointers and save registers at the start of a function
void setupPtrs() {
    printf("\t# Setting up FP\n");
    printf("\tsw $fp, ($sp)\n");
    printf("\tmove $fp, $sp\n");
    printf("\taddi $sp, $sp, -4\n");

    printf("\n\t# Saving registers\n");
    for (int i = 0; i < 8; i++) {
        printf("\tsw $%s, ($sp)\n", registerArray[i]);
        printf("\taddi $sp, $sp, -4\n");
    }
    printf("\n");
}

// Function to restore pointers and registers at the end of a function
void reloadPtrs() {
    
    printf("\n\t# Reloading registers\n");
    for (int i = 0; i < 8; i++) {
        printf("\taddi $sp, $sp, 4\n");
        printf("\tlw $%s, ($sp)\n", registerArray[7 - i]);
    }
    
    printf("\n\t# Setting FP back to old value\n"); // Add this line
    printf("\taddi $sp, $sp, 4\n");
    printf("\tlw $fp, ($sp)\n");

    printf("\n\t# Return to caller\n");
    printf("\tjr $ra\n");
    printf("\n");
}

// Sub-function that generates code for function calls
int funcCallExpr(tree* node) {
    int result = 0;
    printf("\n\t# Function call: %s\n", node->children[0]->id);
    // Save return address and call function
    printf("\n\t# Saving return address\n");
    printf("\tsw $ra, ($sp)\n");

    if (node->children[1]){
        // Evaluate arguments (Variable Expression)
        printf("\n\t# Evaluating and stopring arguments\n");
        printf("\n\t# Evaluating argument 0\n"); // using 0 as we are expected to only handle 1 argument
        expr(node->children[1]->children[0]); // assuming again theres only 1 argument inside the function
        printf("\n\t# Storing argument 0\n");
        printf("\tsw $%s, -4($sp)\n", registerArray[regNum]);
        printf("\taddi $sp, $sp, -8\n");
    }
    else{
        printf("\taddi $sp, $sp, -4\n");
    }

    // printf("\taddi $sp, $sp, -4\n");
    printf("\n\t#Jump to callee\n");
    printf("\tjal start%s\n", node->children[0]->id);

    // Restore stack pointer and return address
    if (node->children[1]){
        printf("\n\t# Deallocating space for arguments\n");
        printf("\taddi $sp, $sp, 4\n");
    }
    printf("\n\t# Resetting return address\n");
    printf("\taddi $sp, $sp, 4\n");
    printf("\tlw $ra, ($sp)\n");

    // Store return value in $s5
    printf("\n\t# Move return value into another reg\n");
    nextReg();
    printf("\tmove $%s, $2\n", registerArray[regNum]);
    nextReg();
    return result;
}

// Sub-function that generates code for expressions
int expr(tree* node) {
    int result, t1, t2;
    if (node->numChildren == 1 || node->nodeKind != EXPRESSION){
        if (node->nodeKind == EXPRESSION){
            node = node->children[0];
        }
        // printf("\t# nodeKind = %d\n", node->nodeKind);
        switch (node->nodeKind) {
            case ADDEXPR:
                printf("\t# Arithmetic expression\n");
                t1 = expr(node->children[0]);
                nextReg();
                t2 = expr(node->children[2]);
                nextReg();
                if (node->children[1]->val == 266){
                    printf("\tadd $%s, $%s, $%s\n", registerArray[regNum], registerArray[regNum - 2], registerArray[regNum - 1]);
                }
                else{
                    printf("\tsub $%s, $%s, $%s\n", registerArray[regNum], registerArray[regNum - 2], registerArray[regNum - 1]);
                }
                break;
            case TERM:
                printf("\t# Arithmetic expression\n");
                t1 = expr(node->children[0]);
                nextReg();
                t2 = expr(node->children[2]);
                nextReg();
                if (node->children[1]->val == 266){
                    printf("\tmul $%s, $%s, $%s\n", registerArray[regNum], registerArray[regNum - 2], registerArray[regNum - 1]);
                }
                else{
                    printf("\tdiv $%s, $%s, $%s\n", registerArray[regNum], registerArray[regNum - 2], registerArray[regNum - 1]);
                }
                break;
            case IDENTIFIER:
                printf("\t# Variable expression\n");
                int global = 0;
                for (int i = 0; i < globalNum; i++){
                    if (strcmp(globalVars[i], node->id) == 0){
                        global = 1;
                        break;
                    }
                }
                if(global == 1){
                    printf("\tlw $%s, var%s\n", registerArray[regNum], node->id);
                }
                else{
                    printf("\tlw $%s, 4($fp)\n", registerArray[regNum]);
                }
                break;
            case INTEGER:
                printf("\t# Integer expression\n");
                result = node->val;
                printf("\tli $%s, %d\n", registerArray[regNum], result);
                break;
            case FACTOR:
                if(node->children[0]->nodeKind == FUNCCALLEXPR){
                    result = funcCallExpr(node->children[0]);
                }
                else{
                    result = expr(node->children[0]);
                }
                break;
        }
    }
    // Relational comparison
    else{ 
        // Evaluate left-hand side and right-hand side
        t1 = expr(node->children[0]);
        nextReg();
        t2 = expr(node->children[2]);
        result = t1 - t2;
        nextReg();
        printf("\n\t# Relational comparison\n");

        // Assuming the operator type is stored in a specific child
        int relop = node->children[1]->val; // Example: '<', '>'
        if (relop == 272) { // '<'
            printf("\n\t# LT\n");
            printf("\tsub $%s, $%s, $%s\n", registerArray[regNum], registerArray[regNum - 2], registerArray[regNum - 1]);
            nextReg();
            printf("\tslt $%s, $%s, $0\n", registerArray[regNum], registerArray[regNum - 1]);
        } else if (relop == 273) { // '>'
            printf("\n\t# GT\n");
            printf("\tsub $%s, $%s, $%s\n", registerArray[regNum], registerArray[regNum - 2], registerArray[regNum - 1]);
            nextReg();
            printf("\tsgt $%s, $%s, $0\n", registerArray[regNum], registerArray[regNum - 1]);
        } else {
             fprintf(stderr, "Error: Unsupported relational operator '%c'.\n", relop);
        }
    }
    return result;
}

// Sub-function that generates code for assignment statements
void assgnStmt(tree* node) {
    if (node->children[0]->nodeKind == IDENTIFIER){
        expr(node->children[1]); // EXPR
        symEntry* tempEntry = ST_lookup(node->children[0]->id); 
        printf("\t# Assignment\n");
        if (tempEntry) {
            printf("\tsw $%s, var%s\n", registerArray[regNum], tempEntry->id);
        } else {
            printf("\tsw $%s, 4($sp)\n", registerArray[regNum]);
        }
        nextReg();
    }
    else{
        expr(node->children[0]);
    }
}

// Sub-function that generates code for conditional statements
void condStmt(tree* node) {
    printf("\n\t# Conditional statement\n");
    int t1 = expr(node->children[0]); // Expression
    printf("\tbeq $%s, $0, L%d\n", registerArray[regNum], condCount);
    nextReg();
    printf("\t# True Case\n\n");
    
    // True block
    tree* stmtNode = node->children[1]; // First statement
    // locating first statement
    while(stmtNode){
        if (stmtNode->nodeKind == ASSIGNSTMT) {
            assgnStmt(stmtNode);
        }
        else if (stmtNode->nodeKind == CONDSTMT) {
            condStmt(stmtNode);
        }
        else if (stmtNode->nodeKind == LOOPSTMT) {
            iterativeStmt(stmtNode);
        }
        else if (stmtNode->nodeKind == RETURNSTMT) {
            if (stmtNode->numChildren > 0) {
                tree* exprNode = stmtNode->children[0]; // EXPRESSION
                printf("\n\t# Set return value\n");
                int t1 = expr(exprNode->children[0]);
                printf("\n\t#Move return value into another register\n");
                printf("\tmove $v0, $%s\n", registerArray[regNum]);
                nextReg();
            }
        }
        stmtNode = stmtNode->children[0];
    }
    // End of the conditional
    printf("\nL%d:\n", condCount);
}

// Sub-function that generates code for iterative statements
void iterativeStmt(tree* node) {
    loopCount++;
    printf("\n\t# Iterative statement (while loop)\n");

    // Label for the beginning of the loop condition check
    printf("L%d:\n", loopCount);
    
    int t1 = expr(node->children[0]); // Expression
    printf("\tbeq $%s, $0, L%d\n", registerArray[regNum], loopCount + 1);
    nextReg();

    tree* stmtNode = node->children[1]; // First statement
    while(stmtNode){
        if (stmtNode->nodeKind == ASSIGNSTMT) {
            assgnStmt(stmtNode);
        }
        else if (stmtNode->nodeKind == CONDSTMT) {
            condStmt(stmtNode);
        }
        else if (stmtNode->nodeKind == LOOPSTMT) {
            iterativeStmt(stmtNode);
        }
        else if (stmtNode->nodeKind == RETURNSTMT) {
            if (stmtNode->numChildren > 0) {
                tree* exprNode = stmtNode->children[0]; // EXPRESSION
                printf("\n\t# Set return value\n");
                int t1 = expr(exprNode->children[0]);
                printf("\n\t#Move return value into another register\n");
                printf("\tmove $v0, $%s\n", registerArray[regNum]);
                nextReg();
            }
        }
        stmtNode = stmtNode->children[0];
    }
    
    // Jump back to the start of the loop
    printf("\tb L%d\n", loopCount);

    // Label for the end of the loop
    loopCount++;
    printf("L%d:\n", loopCount);
}

// Sub-function that generates code for functions
void func(tree* node) {
    if (!node || !node->children[1] || !node->children[1]->id) {
        fprintf(stderr, "Error: Function node or name is invalid.\n");
        return;
    }

    printf("\n\t# Function definition\n");
    char* funcName = node->children[1]->id;
    printf("start%s:\n", funcName);

    // Setup function frame
    setupPtrs();

    // Additional logic for startmain
    /*if (strcmp(funcName, "main") == 0) {
        printf("\t# Saving return address\n");
        printf("\tsw $ra, ($sp)\n");
        printf("\taddi $sp, $sp, -4\n");
        printf("\t# Jump to callee\n");
        printf("\t# jal will correctly set $ra as well\n");
        printf("\tjal startfunc\n");
        printf("\t# Resetting return address\n");
        printf("\taddi $sp, $sp, 4\n");
        printf("\tlw $ra, ($sp)\n");
        printf("\t# Move return value into another reg\n");
        printf("\tmove $s1, $2\n");
    }*/

    int varNum = 0; // Variable to track the number of local variables

    // Locate the function body
    tree* funcBody = NULL;
    for (int i = 0; i < node->numChildren; i++) {
        if (node->children[i] && node->children[i]->nodeKind == FUNBODY) {
            funcBody = node->children[i];
            break;
        }
    }

    if (!funcBody) {
        fprintf(stderr, "Error: Function body missing for %s.\n", funcName);
        return;
    }

    // Count local variables in the function
    tree* localDeclList = funcBody->children[0]; // LOCALDECLLIST
    while (localDeclList && localDeclList->numChildren > 0) {
        if (localDeclList->children[0] && localDeclList->children[0]->nodeKind == VARDECL) {
            varNum++;
        }
        localDeclList = localDeclList->children[1];
    }

    if (varNum > 0) {
        printf("\n\t# Allocate space for %d local variables.\n", varNum);
        printf("\taddi $sp, $sp, -%d\n\n", varNum * 4);
    }

    // Process the statements in the function body
    tree* statementList = funcBody->children[1]; // STATEMENTLIST
    while (statementList && statementList->numChildren > 0) {
        tree* stmtNode = statementList->children[0]->children[0]; // First statement
        if (stmtNode) {
            switch (stmtNode->nodeKind) {
                case ASSIGNSTMT:
                    assgnStmt(stmtNode);
                    break;
                case CONDSTMT:
                    condStmt(stmtNode);
                    break;
                case LOOPSTMT:
                    iterativeStmt(stmtNode);
                    break;
                case RETURNSTMT:
                    if (stmtNode->numChildren > 0) {
                        tree* exprNode = stmtNode->children[0]; // EXPRESSION
                        printf("\n\t# Set return value\n");
                        int t1 = expr(exprNode->children[0]);
                        printf("\tmove $v0, $%s\n", registerArray[regNum]);
                    }
                    break;
                default:
                    fprintf(stderr, "Warning: Unhandled statement kind in function %s.\n", funcName);
            }
        }
        statementList = statementList->children[1]; // Move to the next statement
    }

    printf("end%s:\n\n", funcName);

    // Deallocate local variables
    if (varNum > 0) {
        printf("\n\t# Deallocate space for %d local variables.\n", varNum);
        printf("\taddi $sp, $sp, %d\n\n", varNum * 4);
    }

    // Restore frame and return
    reloadPtrs();
}
