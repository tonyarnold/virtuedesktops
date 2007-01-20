//
//  NSMethodSignatureArguments.h
//  Zen framework
//
//  Originally taken from the Colloquy project - http://colloquy.info
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "NSMethodSignature+Arguments.h"


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
