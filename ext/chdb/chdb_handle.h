#ifndef CHDB_HANDLE_H
#define CHDB_HANDLE_H

typedef struct chdb_conn **(*connect_chdb_func)(int, char**);
typedef void (*close_conn_func)(struct chdb_conn**);
typedef struct local_result_v2 *(*query_conn_func)(struct chdb_conn*, const char*, const char*);

extern connect_chdb_func connect_chdb_ptr;
extern close_conn_func close_conn_ptr;
extern query_conn_func query_conn_ptr;

extern void *chdb_handle;

void init_chdb_handle();

#endif