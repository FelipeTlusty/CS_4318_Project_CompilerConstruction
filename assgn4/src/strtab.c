#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "strtab.h"

char *symTypeMod[3] = {"", "[]", "()"};
char *types[3] = {"int", "char", "void"};
int errorFound = 0; // Error flag

table_node *current_scope = NULL; // Points to the current scope
param *working_list_head = NULL; // Points to the current function's head parameter
param *working_list_end = NULL; // Points to the current function's end parameter

// Provided hash function to get an integer key
unsigned long hash(unsigned char *str) {
    unsigned long hash = 5381;
    int c;
    while ((c = *str++))
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    return hash;
}

// Insert a new symbol entry in the current scope
int ST_insert(char *id, char *scope, int data_type, int symbol_type, int size) {
    if (!current_scope) {
        fprintf(stderr, "Error: No current scope.\n");
        return -2;
    }

    if (data_type < 0 || data_type > 2) {
        return -3; // Invalid data type
    }

    int index = hash((unsigned char *)id) % MAXIDS;
    int start = index;

    // Ensure no duplicate symbol in the current scope
    symEntry *tempEntry = ST_lookup(id);
    if (tempEntry) {
        return -1; // Symbol already exists in the current scope
    }

    // Open address collision resolution
    while (current_scope->strTable[index] != NULL &&
           strcmp(current_scope->strTable[index]->id, id) != 0) {
        index = (index + 1) % MAXIDS;
        if (index == start) {
            fprintf(stderr, "Symbol table is full.\n");
            return -2; // Table is full
        }
    }

    if (current_scope->strTable[index] == NULL) {
        // Insert new entry
        symEntry *entry = (symEntry *)malloc(sizeof(symEntry));
        entry->id = strdup(id);
        entry->scope = scope;
        entry->entry = index;
        entry->data_type = data_type;
        entry->symbol_type = symbol_type;
        entry->size = size;
        entry->params = NULL;

        current_scope->strTable[index] = entry;
        return index;
    }

    return -1; // Symbol exists
}

// Recursive lookup function to search for identifier in the current or parent scopes
symEntry *ST_lookup(char *id) {
    table_node *scope = current_scope;
    while (scope) {
        int index = hash((unsigned char *)id) % MAXIDS;
        int start = index;
        while (scope->strTable[index] != NULL) {
            if (strcmp(scope->strTable[index]->id, id) == 0) {
                return scope->strTable[index]; // Found the symbol in this scope
            }
            index = (index + 1) % MAXIDS;
            if (index == start) break; // Avoid infinite loop
        }
        scope = scope->parent; // Move to parent scope if not found in current
    }
    return NULL; // Symbol not found
}

// Print the symbol table of the current scope and its children recursively
void print_sym_tab() {
    if (!current_scope) {
        printf("No symbol table to display (NULL scope).\n");
        return;
    }

    printf("Symbol Table for Current Scope:\n");
    int found_entries = 0;  // Track if we have entries to print

    // Use local variable 'scope' to safely traverse the symbol table
    table_node *scope = current_scope;

    // Loop through the current scope's symbol table entries
    for (int i = 0; i < MAXIDS; i++) {
        if (scope->strTable[i]) {
            found_entries = 1;
            printf("ID: %s, Type: %s, Symbol Type: %s", 
                   scope->strTable[i]->id, 
                   types[scope->strTable[i]->data_type], 
                   symTypeMod[scope->strTable[i]->symbol_type]);

            // Print size and parameters based on symbol type
            if (scope->strTable[i]->symbol_type == ARRAY || 
                scope->strTable[i]->symbol_type == FUNCTION) {
                printf(", Size: %d", scope->strTable[i]->size);
            }

            if (scope->strTable[i]->symbol_type == FUNCTION) {
                param *param_ptr = scope->strTable[i]->params;
                printf(", Params: ");
                while (param_ptr) {
                    printf("Type: %s, Symbol Type: %s -> ", 
                           types[param_ptr->data_type], 
                           symTypeMod[param_ptr->symbol_type]);
                    param_ptr = param_ptr->next;
                }
                printf("NULL");
            }
            printf("\n");
        }
    }

    // If no entries were found, inform the user
    if (!found_entries) {
        printf("No entries found in this scope.\n");
    }

    // Recursively print child and sibling scopes
    if (scope->first_child) {
        current_scope = scope->first_child; // Move to first child
        print_sym_tab(); // Recursively print child scope
        current_scope = scope->parent; // Return to parent scope
    }
    if (scope->next) {
        current_scope = scope->next; // Move to sibling
        print_sym_tab(); // Recursively print sibling scope
        current_scope = scope->parent; // Return to parent scope
    }
}

// Create a new scope (table_node) and set it as the current scope
void new_scope() {
    table_node *new_scope = (table_node *)malloc(sizeof(table_node));
    memset(new_scope->strTable, 0, sizeof(new_scope->strTable));
    new_scope->parent = current_scope;
    new_scope->first_child = NULL;
    new_scope->next = NULL;

    if (current_scope) {
        if (!current_scope->first_child) {
            current_scope->first_child = new_scope; // Set as first child
        } else {
            table_node *sibling = current_scope->first_child;
            while (sibling->next) sibling = sibling->next; // Traverse to last sibling
            sibling->next = new_scope; // Append new scope as next sibling
        }
    }

    current_scope = new_scope; // Update current scope
}

// Return to the parent scope
void up_scope() {
    if (current_scope && current_scope->parent)
        current_scope = current_scope->parent; // Move to parent scope
}

// Add a parameter to an entry's parameter list, incrementing the size
void add_param(symEntry *entry, int data_type, int symbol_type) {
    if (!entry) return;

    param *new_param = (param *)malloc(sizeof(param));
    new_param->data_type = data_type;
    new_param->symbol_type = symbol_type;
    new_param->next = NULL;

    // Add the new parameter to the end of the list
    if (entry->params == NULL) {
        entry->params = new_param;
    } else {
        working_list_end->next = new_param;
    }
    working_list_end = new_param;
    entry->size++; // Increment parameter count for this function
}

// Reset the current parameter list after a function declaration
void reset_param_list() {
    working_list_head = NULL;
    working_list_end = NULL;
}

// Create and return a new table node for a child scope
table_node* create_table_node(table_node* parent) {
    table_node *new_node = (table_node *)malloc(sizeof(table_node));
    new_node->parent = parent;
    new_node->first_child = NULL;
    new_node->next = NULL;
    memset(new_node->strTable, 0, sizeof(new_node->strTable));
    return new_node;
}

// Add a child node to a parent node's list
void add_child_table_node(table_node* parent, table_node* child) {
    if (!parent->first_child) {
        parent->first_child = child;
    } else {
        table_node* sibling = parent->first_child;
        while (sibling->next) sibling = sibling->next;
        sibling->next = child;
    }
}

void toggleError(){
    if (errorFound == 0){
        errorFound = 1;
    }
}
