#ifndef CHDB_STREAMING_RESULT_H
#define CHDB_STREAMING_RESULT_H

#include <ruby.h>

#include "include/chdb.h"

typedef struct
{
    chdb_streaming_result *c_result;
} StreamingResult;

extern VALUE cStreamingResult;
extern const rb_data_type_t StreamingResultType;

void init_streaming_result();

VALUE streaming_result_alloc(VALUE klass);

#endif
