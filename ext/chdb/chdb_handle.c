#include "chdb_handle.h"

#include <dlfcn.h>
#include <ruby.h>

#include "exception.h"

void *chdb_handle = NULL;
connect_chdb_func connect_chdb_ptr = NULL;
close_conn_func close_conn_ptr = NULL;
query_conn_func query_conn_ptr = NULL;

VALUE get_chdb_rb_path(void)
{
    VALUE chdb_module = rb_const_get(rb_cObject, rb_intern("ChDB"));
    return rb_funcall(chdb_module, rb_intern("lib_file_path"), 0);
}

void init_chdb_handle()
{
    VALUE rb_path = get_chdb_rb_path();
    VALUE lib_dir = rb_file_dirname(rb_file_dirname(rb_path));
    VALUE lib_path = rb_str_cat2(lib_dir, "/lib/chdb/lib/libchdb.so");
    // printf("chdb.rb path from Ruby: %s\n", StringValueCStr(lib_path));

    connect_chdb_ptr = NULL;
    close_conn_ptr = NULL;
    query_conn_ptr = NULL;

    chdb_handle = dlopen(RSTRING_PTR(lib_path), RTLD_LAZY | RTLD_GLOBAL);
    if (!chdb_handle)
    {
        rb_raise(cChDBError, "Failed to load chdb library: %s\nCheck if libchdb.so exists at: %s",
                 dlerror(), RSTRING_PTR(lib_path));
    }

    connect_chdb_ptr = (connect_chdb_func)dlsym(chdb_handle, "connect_chdb");
    close_conn_ptr = (close_conn_func)dlsym(chdb_handle, "close_conn");
    query_conn_ptr = (query_conn_func)dlsym(chdb_handle, "query_conn");

    if (!connect_chdb_ptr || !close_conn_ptr || !query_conn_ptr)
    {
        rb_raise(cChDBError, "Symbol loading failed: %s\nMissing functions: connect_chdb(%p) close_conn(%p) query_conn(%p)",
                 dlerror(),
                 (void*)connect_chdb_ptr,
                 (void*)close_conn_ptr,
                 (void*)query_conn_ptr);
    }
}