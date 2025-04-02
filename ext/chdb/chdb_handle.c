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

    if (!connect_chdb_ptr || !close_conn_ptr || !query_conn_ptr || !free_result_v2_ptr)
    {
        close_chdb_handle();

        rb_raise(cChDBError,
                 "Symbol loading failed: %s\nMissing functions: connect_chdb(%p) close_conn(%p) query_conn(%p), free_result_v2(%p)",
                 dlerror(),
                 (void*)connect_chdb_ptr,
                 (void*)close_conn_ptr,
                 (void*)query_conn_ptr,
                 (void*)free_result_v2_ptr);
    }

    rb_set_end_proc(close_chdb_handle, 0);
}
