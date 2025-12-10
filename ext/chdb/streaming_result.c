#include "streaming_result.h"

#include "constants.h"
#include "chdb_handle.h"

VALUE cStreamingResult;

void streaming_result_free(void *ptr)
{
    StreamingResult *result = (StreamingResult *)ptr;
    DEBUG_PRINT("Freeing StreamingResult: %p", (void*)result);
    if (result->c_result)
    {
        DEBUG_PRINT("Freeing chdb_streaming_result: %p", (void*)result->c_result);
        chdb_destroy_result_ptr(result->c_result);
    }
    free(result);
}

const rb_data_type_t StreamingResultType =
{
    "StreamingResult",
    {NULL, streaming_result_free, NULL},
};

void init_streaming_result()
{
    VALUE mChDB = rb_define_module("ChDB");
    cStreamingResult = rb_define_class_under(mChDB, "StreamingResult", rb_cObject);
    rb_define_alloc_func(cStreamingResult, streaming_result_alloc);
}

VALUE streaming_result_alloc(VALUE klass)
{
    StreamingResult *result = ALLOC(StreamingResult);
    DEBUG_PRINT("Allocating StreamingResult: %p", (void*)result);
    result->c_result = NULL;
    return rb_data_typed_object_wrap(klass, result, &StreamingResultType);
}
