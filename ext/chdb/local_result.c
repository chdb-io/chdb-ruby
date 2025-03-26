#include "local_result.h"

static void local_result_free(void *ptr)
{
    LocalResult *result = (LocalResult *)ptr;
    DEBUG_PRINT("Freeing LocalResult: %p", (void*)result);
    if (result->c_result)
    {
        free_result_v2(result->c_result);
    }
    free(result);
}

const rb_data_type_t LocalResultType =
{
    "LocalResult",
    {NULL, local_result_free, NULL},
};

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
