#ifndef STRTAB_H
#define STRTAB_H
#define MAXIDS 1000

// Enum for data types
enum dataType {INT_TYPE, CHAR_TYPE, VOID_TYPE};

// Enum for symbol types
enum symbolType {SCALAR, ARRAY, FUNCTION};

// Structure representing a parameter
typedef struct param {
    int data_type;
    int symbol_type;
    struct param* next;
} param;

// Structure representing a symbol entry in the symbol table
typedef struct strEntry {
    char* id;
    char* scope;
    int entry;
    int data_type;
    int symbol_type;
    int size; // Num elements if array, num params if function
    param* params; // Linked list head for parameters
} symEntry;

// Linked list tracking parameters for a function in progress
extern param *working_list_head;
extern param *working_list_end;

// Functions to add new parameters to the working list and reset it
void add_param(symEntry *entry, int data_type, int symbol_type);
void reset_param_list();

// Structure for managing the symbol table tree
typedef struct table_node {
    symEntry* strTable[MAXIDS];  // The symbol table itself (array of pointers to entries)
    int numChildren;
    struct table_node* parent;
    struct table_node* first_child;  // First subscope
    struct table_node* last_child;   // Most recently added subscope
    struct table_node* next; // Next subscope sharing the same parent
} table_node;

extern table_node* current_scope; // Global pointer to the current scope in the symbol table tree

// Functions for managing the tree of symbol tables (scope management)
void new_scope();                  // Create a new nested scope
void up_scope();                   // Move up to the parent scope
table_node* create_table_node(table_node* parent); // Initialize a new table node
void add_child_table_node(table_node* parent, table_node* child); // Add child node to parent

// Inserts a symbol into the current symbol table
int ST_insert(char *id, char *scope, int data_type, int symbol_type, int size);

// Look up a symbol starting from the current scope
symEntry* ST_lookup(char *id);

// Output entry in symbol table for debugging or inspection
void output_entry(int index);

// Prints the whole symbol table tree and its contents
void print_sym_tab();  // Updated without the scope parameter

// Returns a variable name by searching for its index in the symbol table
char* get_symbol_id(int index);

#endif
