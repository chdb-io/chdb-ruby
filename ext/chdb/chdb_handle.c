#include "chdb_handle.h"

#include <dlfcn.h>
#include <ruby.h>
#include "constants.h"
#include "exception.h"

void *chdb_handle = NULL;
connect_chdb_func connect_chdb_ptr = NULL;
close_conn_func close_conn_ptr = NULL;
query_conn_func query_conn_ptr = NULL;
free_result_v2_func free_result_v2_ptr = NULL;
query_conn_streaming_func query_conn_streaming_ptr = NULL;
chdb_streaming_result_error_func chdb_streaming_result_error_ptr = NULL;
chdb_streaming_fetch_result_func chdb_streaming_fetch_result_ptr = NULL;
chdb_streaming_cancel_query_func chdb_streaming_cancel_query_ptr = NULL;
chdb_destroy_result_func chdb_destroy_result_ptr = NULL;

VALUE get_chdb_rb_path()
{
    VALUE chdb_module = rb_const_get(rb_cObject, rb_intern("ChDB"));
    return rb_funcall(chdb_module, rb_intern("lib_file_path"), 0);
}

void close_chdb_handle()
{
    if (chdb_handle)
    {
        dlclose(chdb_handle);
        chdb_handle = NULL;
        DEBUG_PRINT("Close chdb handle");
    }
}

void init_chdb_handle()
{
    VALUE rb_path = get_chdb_rb_path();
    VALUE lib_dir = rb_file_dirname(rb_file_dirname(rb_path));
    VALUE lib_path = rb_str_cat2(lib_dir, "/lib/chdb/lib/libchdb.so");

    DEBUG_PRINT("chdb.rb path from Ruby: %s\n", StringValueCStr(lib_path));

    connect_chdb_ptr = NULL;
    close_conn_ptr = NULL;
    query_conn_ptr = NULL;
    free_result_v2_ptr = NULL;
    query_conn_streaming_ptr = NULL;
    chdb_streaming_result_error_ptr = NULL;
    chdb_streaming_fetch_result_ptr = NULL;
    chdb_streaming_cancel_query_ptr = NULL;
    chdb_destroy_result_ptr = NULL;

    chdb_handle = dlopen(RSTRING_PTR(lib_path), RTLD_LAZY | RTLD_GLOBAL);
    if (!chdb_handle)
    {
        rb_raise(cChDBError, "Failed to load chdb library: %s\nCheck if libchdb.so exists at: %s",
                 dlerror(), RSTRING_PTR(lib_path));
    }

    connect_chdb_ptr = (connect_chdb_func)dlsym(chdb_handle, "connect_chdb");
    close_conn_ptr = (close_conn_func)dlsym(chdb_handle, "close_conn");
    query_conn_ptr = (query_conn_func)dlsym(chdb_handle, "query_conn");
    free_result_v2_ptr = (free_result_v2_func)dlsym(chdb_handle, "free_result_v2");
    query_conn_streaming_ptr = (query_conn_streaming_func)dlsym(chdb_handle, "query_conn_streaming");
    chdb_streaming_result_error_ptr = (chdb_streaming_result_error_func)dlsym(chdb_handle, "chdb_streaming_result_error");
    chdb_streaming_fetch_result_ptr = (chdb_streaming_fetch_result_func)dlsym(chdb_handle, "chdb_streaming_fetch_result");
    chdb_streaming_cancel_query_ptr = (chdb_streaming_cancel_query_func)dlsym(chdb_handle, "chdb_streaming_cancel_query");
    chdb_destroy_result_ptr = (chdb_destroy_result_func)dlsym(chdb_handle, "chdb_destroy_result");

    if (!connect_chdb_ptr || !close_conn_ptr || !query_conn_ptr || !free_result_v2_ptr ||
            !query_conn_streaming_ptr || !chdb_streaming_result_error_ptr || !chdb_streaming_fetch_result_ptr ||
            !chdb_streaming_cancel_query_ptr || !chdb_destroy_result_ptr)
    {
        close_chdb_handle();

        rb_raise(cChDBError,
                 "Symbol loading failed: %s\nMissing functions: connect_chdb(%p), close_conn(%p), query_conn(%p), free_result_v2(%p), query_conn_streaming(%p), chdb_streaming_result_error(%p), chdb_streaming_fetch_result(%p), chdb_streaming_cancel_query(%p), chdb_destroy_result(%p)",
                 dlerror(),
                 (void*)connect_chdb_ptr,
                 (void*)close_conn_ptr,
                 (void*)query_conn_ptr,
                 (void*)free_result_v2_ptr,
                 (void*)query_conn_streaming_ptr,
                 (void*)chdb_streaming_result_error_ptr,
                 (void*)chdb_streaming_fetch_result_ptr,
                 (void*)chdb_streaming_cancel_query_ptr,
                 (void*)chdb_destroy_result_ptr);
    }

    rb_set_end_proc(close_chdb_handle, 0);
}
