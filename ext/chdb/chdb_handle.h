#ifndef CHDB_HANDLE_H
#define CHDB_HANDLE_H

#include "include/chdb.h"

typedef struct chdb_conn **(*connect_chdb_func)(int, char**);
typedef void (*close_conn_func)(struct chdb_conn**);
typedef struct local_result_v2 *(*query_conn_func)(struct chdb_conn*, const char*, const char*);
typedef void (*free_result_v2_func)(struct local_result_v2*);
typedef chdb_streaming_result *(*query_conn_streaming_func)(struct chdb_conn*, const char*, const char*);
typedef const char *(*chdb_streaming_result_error_func)(chdb_streaming_result*);
typedef struct local_result_v2 *(*chdb_streaming_fetch_result_func)(struct chdb_conn*, chdb_streaming_result*);
typedef void (*chdb_streaming_cancel_query_func)(struct chdb_conn*, chdb_streaming_result*);
typedef void (*chdb_destroy_result_func)(chdb_streaming_result*);

extern connect_chdb_func connect_chdb_ptr;
extern close_conn_func close_conn_ptr;
extern query_conn_func query_conn_ptr;
extern free_result_v2_func free_result_v2_ptr;
extern query_conn_streaming_func query_conn_streaming_ptr;
extern chdb_streaming_result_error_func chdb_streaming_result_error_ptr;
extern chdb_streaming_fetch_result_func chdb_streaming_fetch_result_ptr;
extern chdb_streaming_cancel_query_func chdb_streaming_cancel_query_ptr;
extern chdb_destroy_result_func chdb_destroy_result_ptr;

extern void *chdb_handle;

void init_chdb_handle();

#endif
