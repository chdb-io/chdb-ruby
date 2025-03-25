#ifndef CHDB_CONNECTION_H
#define CHDB_CONNECTION_H

#include <ruby.h>

typedef struct {
    struct chdb_conn **c_conn;
} Connection;

extern const rb_data_type_t ConnectionType;

VALUE connection_alloc(VALUE klass);

VALUE connection_initialize(VALUE self, VALUE argc, VALUE argv);

VALUE connection_query(VALUE self, VALUE query, VALUE format);

VALUE connection_close(VALUE self);

#endif