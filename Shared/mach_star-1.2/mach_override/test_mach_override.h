#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include "mach_override.h"

#define	assertStrEqual( EXPECTED, ACTUAL ) if( strcmp( (EXPECTED), (ACTUAL) ) != 0 ) { printf( "EXPECTED: %s\nACTUAL: %s\n", (EXPECTED), (ACTUAL)); assert( strcmp( (EXPECTED), (ACTUAL) ) == 0 ); }
#define	assertIntEqual( EXPECTED, ACTUAL ) if( (EXPECTED) != (ACTUAL) ) { printf( "EXPECTED: %d\nACTUAL: %d\n", (EXPECTED), (ACTUAL)); assert( (EXPECTED) == (ACTUAL) ); }

//------------------------------------------------------------------------------
#pragma mark Test Local Override by Pointer

const char* localOriginal();
const char* localOverride();
/*
 Design note: We call localOriginal() through a function pointer
 (localOriginalPtr) since otherwise gcc's optimizer believes its return value
 doesn't change and it won't actually call it again after the override. Calling
 through a function pointer defeats this optimization, allowing the test to
 succeed even with -Os.
*/
typedef const char* (*localProc)();
localProc localOriginalPtr = localOriginal;
localProc gReentry_localOriginal;

void testLocalFunctionOverrideByPointer();

//------------------------------------------------------------------------------
#pragma mark Test System Override by Pointer

char* strerrorOverride( int errnum );
typedef char* (*strerrorProc)( int );
strerrorProc strerrorPtr = strerror;
strerrorProc gReentry_strerror;

void testSystemFunctionOverrideByPointer();

//------------------------------------------------------------------------------
#pragma mark Test System Override by Name

int strerror_rOverride( int errnum, char *strerrbuf, size_t buflen );
typedef int (*strerror_rProc)( int, char*, size_t );
strerror_rProc strerror_rPtr = strerror_r;
strerror_rProc gReentry_strerror_r;

void testSystemFunctionOverrideByName();