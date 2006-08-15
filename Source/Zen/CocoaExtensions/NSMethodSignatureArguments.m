/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************
*
* Copyright, Colloquy Project 
* http://www.colloquy.info
*
*****************************************************************************/ 

#import "NSMethodSignatureArguments.h"


@interface NSMethodSignature(NSMethodSignaturePrivate)
+ (id) signatureWithObjCTypes:(const char *) types;
@end

#pragma mark -

@implementation NSMethodSignature (ZNArguments)

+ (id) methodSignatureWithReturnAndArgumentTypes: (const char*) retType, ... {
	NSMutableString* types = [NSMutableString stringWithFormat: @"%s@:", retType];
	
	char* type = NULL;
	va_list strings;
	
	va_start(strings, retType);
	
	while (type = va_arg(strings, char*))
		[types appendString: [NSString stringWithUTF8String: type]];
	
	va_end(strings);
	
	return [self signatureWithObjCTypes: [types UTF8String]];
}

@end
