#include <ruby.h>

#include "chdb.h"
#include "chdb_handle.h"
#include "constants.h"
#include "connection.h"
#include "exception.h"
#include "local_result.h"

void Init_chdb_native()
{
    DEBUG_PRINT("Initializing chdb extension");

    init_exception();
    init_chdb_handle();
    init_chdb_constants();
    init_local_result();
    init_connection();

    DEBUG_PRINT("chdb extension initialized successfully");
}
