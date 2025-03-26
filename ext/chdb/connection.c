#include "connection.h"

VALUE connection_alloc(VALUE klass)
{
    Connection *conn = ALLOC(Connection);
    DEBUG_PRINT("Allocating Connection: %p", (void*)conn);
    conn->c_conn = NULL;
    return rb_data_typed_object_wrap(klass, conn, &ConnectionType);
}

VALUE connection_initialize(VALUE self, VALUE argc, VALUE argv)
{
    Check_Type(argc, T_FIXNUM);
    Check_Type(argv, T_ARRAY);

    int c_argc = NUM2INT(argc);
    char **c_argv = ALLOC_N(char *, c_argc);

    for (int i = 0; i < c_argc; i++)
    {
        VALUE arg = rb_ary_entry(argv, i);
        c_argv[i] = StringValueCStr(arg);
    }

    Connection *conn;
    TypedData_Get_Struct(self, Connection, &ConnectionType, conn);
    conn->c_conn = connect_chdb(c_argc, c_argv);

    if (!conn->c_conn)
    {
        xfree(c_argv);
        rb_raise(cChDBError, "Failed to connect to chDB");
    }

    xfree(c_argv);
    rb_gc_unregister_address(&argv);
    return self;
}

VALUE connection_query(VALUE self, VALUE query, VALUE format)
{
    Connection *conn;
    TypedData_Get_Struct(self, Connection, &ConnectionType, conn);

    Check_Type(query, T_STRING);
    Check_Type(format, T_STRING);

    struct local_result_v2 *c_result = query_conn(
                                           *conn->c_conn,
                                           StringValueCStr(query),
                                           StringValueCStr(format)
                                       );

    if (!c_result)
    {
        rb_raise(cChDBError, "Query failed with nil result");
    }

    if (c_result->error_message)
    {
        VALUE error_message = rb_str_new_cstr(c_result->error_message);
        rb_raise(cChDBError, "CHDB error: %s", StringValueCStr(error_message));
    }

    VALUE result_obj = rb_class_new_instance(0, NULL, cLocalResult);
    LocalResult *result;
    TypedData_Get_Struct(result_obj, LocalResult, &LocalResultType, result);
    result->c_result = c_result;

    return result_obj;
}

VALUE connection_close(VALUE self)
{
    Connection *conn;
    TypedData_Get_Struct(self, Connection, &ConnectionType, conn);

    if (conn->c_conn)
    {
        close_conn(conn->c_conn);
        conn->c_conn = NULL;
    }
    return Qnil;
}

static void connection_free(void *ptr)
{
    Connection *conn = (Connection *)ptr;
    DEBUG_PRINT("Closing connection: %p", (void*)conn->c_conn);
    if (conn->c_conn)
    {
        close_conn(conn->c_conn);
    }
    free(conn);
}

const rb_data_type_t ConnectionType =
{
    "Connection",
    {NULL, connection_free, NULL},
};

// 其他 Connection 方法保持不变...