#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "strtab.h"

char *symTypeMod[3] = {"", "[]", "()"};
char* types[3] = {"int", "char", "void"};

strEntry strTable[MAXIDS];

/* Provided is a hash function to get an integer back. */
unsigned long hash(unsigned char *str)
{
    unsigned long hash = 5381;
    int c;

    while ((c = *str++)) // Added parentheses to suppress warning
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */

    return hash;
}

/* 
 * Function: ST_insert
 * -------------------
 * Inserts a new entry into the symbol table's hashtable.
 *
 * id: Identifier name
 * scope: Scope of the identifier ("", "local", etc.)
 * data_type: Data type of the identifier (int, char, void)
 * symbol_type: Category of the symbol (variable, array, function)
 *
 * returns: int (index)
 */
int ST_insert(char *id, char *scope, int data_type, int symbol_type){
    // TODO: Concatenate the scope and id and use that to create the hash key
    if (data_type != 0 && data_type != 1 && data_type != 2){
        return -3;
    }
    char* keyStr = (char*) malloc(strlen(scope) + strlen(id) + 1);
    if (keyStr == NULL) {
        fprintf(stderr, "Memory allocation failed for keyStr.\n");
        exit(EXIT_FAILURE);
    }
    strcpy(keyStr, scope);
    strcat(keyStr, id);
    int index = hash((unsigned char*)keyStr) % MAXIDS;
    int start = index;
    free(keyStr);

    // TODO: Use ST_lookup to check if the id is already in the symbol table. If yes, ST_lookup will return an index that is not -1. if index != -1, that means the variable is already in the hashtable. Hence, no need to insert that variable again. However, if index == -1, then use linear probing to find an empty spot and insert there. Then return that index.
    int searchIndex = ST_lookup(id, scope);
    if (searchIndex == -1){
        while (strTable[index].id != NULL && 
               (strcmp(strTable[index].id, id) != 0 || strcmp(strTable[index].scope, scope) != 0)){
            index = (index + 1) % MAXIDS;
            if (index == start) {
                fprintf(stderr, "Symbol table is full.\n");
                return -2; // Indicate failure due to full table
            }
        }
        // If empty node is found, set that node to the new variable
        if (strTable[index].id == NULL){
            strTable[index].id = strdup(id); // Use strdup to allocate memory for id
            strTable[index].scope = strdup(scope); // Use strdup to allocate memory for scope
            strTable[index].data_type = data_type;
            strTable[index].symbol_type = symbol_type;
        }
        // If variable is found or table is full return corresponding error message.
        else{
            if (searchIndex >= 0){
                printf("Warning: Variable '%s' already declared in scope '%s'.\n", id, scope);
                output_entry(searchIndex);
            }
            else{
                printf("Error: Symbol table is full.\n");
                return -2;
            }
        }
    }
    return index;
}

/* 
 * Function: ST_lookup
 * -------------------
 * Looks for an existing entry in the symbol table.
 * 
 * id: Identifier name
 * scope: Scope of the identifier ("", "local", etc.)
 *
 * returns: int ("index" if entry is found or "-1" if entry not found)
 */
int ST_lookup(char *id, char *scope) {
    // TODO: Concatenate the scope and id and use that to create the hash key
    char* keyStr = (char*) malloc(strlen(scope) + strlen(id) + 1);
    if (keyStr == NULL) {
        fprintf(stderr, "Memory allocation failed for keyStr.\n");
        exit(EXIT_FAILURE);
    }
    strcpy(keyStr, scope);
    strcat(keyStr, id);
    int index = hash((unsigned char*)keyStr) % MAXIDS;
    int start = index;
    free(keyStr);

    // TODO: Use the hash value to check if the index position has the "id". If not, keep looking for id until you find an empty spot. If you find "id", return that index. If you arrive at an empty spot, that means "id" is not there. Then return -1. 
    while (strTable[index].id != NULL && 
           (strcmp(strTable[index].id, id) != 0 || strcmp(strTable[index].scope, scope) != 0)){
        index = (index + 1) % MAXIDS;
        if(index == start){
            printf("Error: Symbol table is full.\n");
            return -2;
        }
    }

    // Searches for global variable if local not found.
    if (strTable[index].id == NULL && strcmp(scope,"") != 0){
        index = hash((unsigned char*)id) % MAXIDS;
        start = index;
        while (strTable[index].id != NULL && 
               (strcmp(strTable[index].id, id) != 0 || strcmp(strTable[index].scope, "") != 0)){
            index = (index + 1) % MAXIDS;
            if (index == start){
                printf("Error: Symbol table is full.\n");
                return -2;
            }
        }
    }

    // sets index as -1 if the variable was not found.
    if (strTable[index].id == NULL){
        index = -1;
    }

    return index;
}

/* 
 * Function: output_entry
 * -------------------
 * Prints out symbol table's entry from a given index.
 * 
 * i: Index in the symbol table
 *
 * returns: void
 */
void output_entry(int i){
    if (i < 0 || i >= MAXIDS || strTable[i].id == NULL) {
        printf("Invalid symbol table index: %d\n", i);
        return;
    }
    printf("%d: %s ", i, types[strTable[i].data_type]);
    printf("%s:%s%s\n", strTable[i].scope, strTable[i].id, symTypeMod[strTable[i].symbol_type]);
}
