#include <ruby.h>

#include "chdb.h"
#include "constants.h"
#include "connection.h"
#include "local_result.h"

VALUE cChDBError;
VALUE cLocalResult;

void init_chdb_constants() {
    VALUE mChDB = rb_define_module("ChDB");
    VALUE mChDBConstants = rb_define_module_under(mChDB, "Constants");
    VALUE mmChDBOpen = rb_define_module_under(mChDBConstants, "Open");

    rb_define_const(mmChDBOpen, "READONLY", INT2FIX(CHDB_OPEN_READONLY));
    rb_define_const(mmChDBOpen, "READWRITE", INT2FIX(CHDB_OPEN_READWRITE));
    rb_define_const(mmChDBOpen, "CREATE", INT2FIX(CHDB_OPEN_CREATE));
}

void init_exception() {
    VALUE mChDB = rb_define_module("ChDB");
    if (rb_const_defined(mChDB, rb_intern("Exception")))
        cChDBError = rb_const_get(mChDB, rb_intern("Exception"));
    else
        cChDBError = rb_define_class_under(mChDB, "Exception", rb_eStandardError);
}

void init_local_result() {
    VALUE mChDB = rb_define_module("ChDB");
    cLocalResult = rb_define_class_under(mChDB, "LocalResult", rb_cObject);
    rb_define_alloc_func(cLocalResult, local_result_alloc);
    rb_define_method(cLocalResult, "buf", local_result_buf, 0);
    rb_define_method(cLocalResult, "elapsed", local_result_elapsed, 0);
    rb_define_method(cLocalResult, "rows_read", local_result_rows_read, 0);
    rb_define_method(cLocalResult, "bytes_read", local_result_bytes_read, 0);
}

void init_connection() {
    VALUE mChDB = rb_define_module("ChDB");
    VALUE cConnection = rb_define_class_under(mChDB, "Connection", rb_cObject);
    rb_define_alloc_func(cConnection, connection_alloc);
    rb_define_method(cConnection, "initialize", connection_initialize, 2);
    rb_define_method(cConnection, "query", connection_query, 2);
    rb_define_method(cConnection, "close", connection_close, 0);
}


void Init_chdb(void)
{
    DEBUG_PRINT("Initializing chdb extension");
    
    init_chdb_constants();
    init_exception(); 
    init_local_result();
    init_connection(); 

    DEBUG_PRINT("chdb extension initialized successfully");
}
