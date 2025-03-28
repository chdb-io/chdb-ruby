#ifndef CHDB_LOCAL_RESULT_H
#define CHDB_LOCAL_RESULT_H

#include <ruby.h>

typedef struct
{
    struct local_result_v2 *c_result;
} LocalResult;

extern VALUE cLocalResult;
extern const rb_data_type_t LocalResultType;

void init_local_result();

VALUE local_result_alloc(VALUE klass);

VALUE local_result_buf(VALUE self);

VALUE local_result_elapsed(VALUE self);

VALUE local_result_rows_read(VALUE self);

VALUE local_result_bytes_read(VALUE self);

#endif