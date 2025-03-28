#ifndef CHDB_CONSTANTS_H
#define CHDB_CONSTANTS_H

#define CHDB_OPEN_READONLY     0x00000001
#define CHDB_OPEN_READWRITE    0x00000002
#define CHDB_OPEN_CREATE       0x00000004

#define CHDB_DEBUG 0
#if CHDB_DEBUG
#define DEBUG_PRINT(fmt, ...) fprintf(stderr, fmt "\n", ##__VA_ARGS__)
#else
#define DEBUG_PRINT(fmt, ...) ((void)0)
#endif

#endif
