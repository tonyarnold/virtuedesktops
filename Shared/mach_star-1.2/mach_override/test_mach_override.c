#include "test_mach_override.h"

//------------------------------------------------------------------------------
#pragma mark Test Local Override by Pointer

void testLocalFunctionOverrideByPointer() {
	//	Test original.
	assertStrEqual( "localOriginal", localOriginalPtr() );
	
	//	Override local function by pointer.
	kern_return_t err = mach_override_ptr( (void*)&localOriginal,
										   (void*)&localOverride,
										   (void**)&gReentry_localOriginal );
	assert( !err );
	
	//	Test override took effect.
	assertStrEqual( "localOverride", localOriginalPtr() );
}

const char* localOriginal() {
	return __FUNCTION__;
}

const char* localOverride() {
	//	Test calling through the reentry island back into the original
	//	implementation.
	assertStrEqual( "localOriginal", gReentry_localOriginal() );
	
	return __FUNCTION__;
}

//------------------------------------------------------------------------------
#pragma mark Test System Override by Pointer

void testSystemFunctionOverrideByPointer() {
	//	Test original.
	assertStrEqual( "Unknown error: 0", strerrorPtr( 0 ) );
	
	//	Override local function by pointer.
	kern_return_t err = mach_override_ptr( (void*)&strerror,
										   (void*)&strerrorOverride,
										   (void**)&gReentry_strerror );
	assert( !err );
	
	//	Test override took effect.
	assertStrEqual( "strerrorOverride", strerrorPtr( 0 ) );
}

char* strerrorOverride( int errnum ) {
	//	Test calling through the reentry island back into the original
	//	implementation.
	assertStrEqual( "Unknown error: 0", gReentry_strerror( 0 ) );
	
	return (char*)__FUNCTION__;
}

//------------------------------------------------------------------------------
#pragma mark Test System Override by Name

void testSystemFunctionOverrideByName() {
	//	Test original.
	assertIntEqual( EINVAL, strerror_rPtr( 0, NULL, 0 ) );
	
	//	Override local function by pointer.
	kern_return_t err = mach_override( "_strerror_r",
									   NULL,
									   (void*)&strerror_rOverride,
									   (void**)&gReentry_strerror_r );
	
	//	Test override took effect.
	assertIntEqual( 0, strerror_rPtr( 0, NULL, 0 ) );
}

int strerror_rOverride( int errnum, char *strerrbuf, size_t buflen ) {
	assertIntEqual( EINVAL, gReentry_strerror_r( 0, NULL, 0 ) );
	
	return 0;
}

//------------------------------------------------------------------------------
#pragma mark main

int main( int argc, const char *argv[] ) {
	testLocalFunctionOverrideByPointer();
	testSystemFunctionOverrideByPointer();
	testSystemFunctionOverrideByName();
	
	printf( "success\n" );
	return 0;
}