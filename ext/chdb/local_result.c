#include "local_result.h"

#include "constants.h"
#include "include/chdb.h"
#include "chdb_handle.h"

VALUE cLocalResult;

void local_result_free(void *ptr)
{
    LocalResult *result = (LocalResult *)ptr;
    DEBUG_PRINT("Freeing LocalResult: %p", (void*)result);
    if (result->c_result)
    {
        DEBUG_PRINT("Freeing local_result_v2: %p", (void*)result->c_result);
        free_result_v2_ptr(result->c_result);
    }
    free(result);
}

const rb_data_type_t LocalResultType =
{
    "LocalResult",
    {NULL, local_result_free, NULL},
};

void init_local_result()
{
    VALUE mChDB = rb_define_module("ChDB");
    cLocalResult = rb_define_class_under(mChDB, "LocalResult", rb_cObject);
    rb_define_alloc_func(cLocalResult, local_result_alloc);
    rb_define_method(cLocalResult, "buf", local_result_buf, 0);
    rb_define_method(cLocalResult, "elapsed", local_result_elapsed, 0);
    rb_define_method(cLocalResult, "rows_read", local_result_rows_read, 0);
    rb_define_method(cLocalResult, "bytes_read", local_result_bytes_read, 0);
}

VALUE local_result_alloc(VALUE klass)
{
    LocalResult *result = ALLOC(LocalResult);
    DEBUG_PRINT("Allocating LocalResult: %p", (void*)result);
    result->c_result = NULL;
    return rb_data_typed_object_wrap(klass, result, &LocalResultType);
}

VALUE local_result_buf(VALUE self)
{
    LocalResult *result;
    TypedData_Get_Struct(self, LocalResult, &LocalResultType, result);

    if (!result->c_result || !result->c_result->buf)
    {
        DEBUG_PRINT("Buffer access attempted on empty result");
        return Qnil;
    }

    DEBUG_PRINT("Returning buffer of length %zu", result->c_result->len);
    return rb_str_new(result->c_result->buf, result->c_result->len);
}

VALUE local_result_elapsed(VALUE self)
{
    LocalResult *result;
    TypedData_Get_Struct(self, LocalResult, &LocalResultType, result);
    DEBUG_PRINT("Query elapsed time: %f", result->c_result->elapsed);
    return DBL2NUM(result->c_result->elapsed);
}

VALUE local_result_rows_read(VALUE self)
{
    LocalResult *result;
    TypedData_Get_Struct(self, LocalResult, &LocalResultType, result);
    DEBUG_PRINT("Rows read: %" PRIu64, result->c_result->rows_read);
    return ULONG2NUM(result->c_result->rows_read);
}

VALUE local_result_bytes_read(VALUE self)
{
    LocalResult *result;
    TypedData_Get_Struct(self, LocalResult, &LocalResultType, result);
    DEBUG_PRINT("Bytes read: %" PRIu64, result->c_result->bytes_read);
    return ULONG2NUM(result->c_result->bytes_read);
}
