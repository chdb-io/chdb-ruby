#include <ruby.h>

#include "chdb.h"
#include "constants.h"
#include "connection.h"
#include "exception.h"
#include "local_result.h"

void init_chdb_constants()
{
    VALUE mChDB = rb_define_module("ChDB");
    VALUE mChDBConstants = rb_define_module_under(mChDB, "Constants");
    VALUE mmChDBOpen = rb_define_module_under(mChDBConstants, "Open");

    rb_define_const(mmChDBOpen, "READONLY", INT2FIX(CHDB_OPEN_READONLY));
    rb_define_const(mmChDBOpen, "READWRITE", INT2FIX(CHDB_OPEN_READWRITE));
    rb_define_const(mmChDBOpen, "CREATE", INT2FIX(CHDB_OPEN_CREATE));
}

void Init_chdb_native()
{
    DEBUG_PRINT("Initializing chdb extension");

    init_exception();
    init_chdb_constants();
    init_local_result();
    init_connection();

    DEBUG_PRINT("chdb extension initialized successfully");
}
