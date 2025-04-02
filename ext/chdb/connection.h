#ifndef CHDB_CONNECTION_H
#define CHDB_CONNECTION_H

#include <ruby.h>

typedef struct
{
    struct chdb_conn **c_conn;
} Connection;

extern const rb_data_type_t ConnectionType;

void init_connection();

VALUE connection_alloc(VALUE klass);

VALUE connection_initialize(VALUE self, VALUE argc, VALUE argv);

VALUE connection_query(VALUE self, VALUE query, VALUE format);

VALUE connection_streaming_query(VALUE self, VALUE query, VALUE format);

VALUE connection_streaming_fecth_result(VALUE self, VALUE streaming_result);

VALUE connection_streaming_cancel_query(VALUE self, VALUE streaming_result);

VALUE connection_close(VALUE self);

#endif
