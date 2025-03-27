#include "exception.h"

VALUE cChDBError;

void init_exception()
{
    VALUE mChDB = rb_define_module("ChDB");
    if (rb_const_defined(mChDB, rb_intern("Exception")))
    {
        cChDBError = rb_const_get(mChDB, rb_intern("Exception"));
    }
    else
    {
        cChDBError = rb_define_class_under(mChDB, "Exception", rb_eStandardError);
    }
}
