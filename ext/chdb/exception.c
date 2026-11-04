#include "exception.h"

VALUE cChDBError;

void init_exception()
{
    VALUE mChDB = rb_define_module("ChDB");
    // Look up ChDB::Exception only in ChDB itself: rb_const_defined/rb_const_get
    // also search Object for a module and would return Ruby's top-level Exception.
    if (rb_const_defined_at(mChDB, rb_intern("Exception")))
    {
        cChDBError = rb_const_get_at(mChDB, rb_intern("Exception"));
    }
    else
    {
        cChDBError = rb_define_class_under(mChDB, "Exception", rb_eStandardError);
        rb_global_variable(&cChDBError);
    }
}
