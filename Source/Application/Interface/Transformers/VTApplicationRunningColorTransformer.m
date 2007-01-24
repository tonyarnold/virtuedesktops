/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTApplicationRunningColorTransformer.h"
#import "VTApplicationWrapper.h"

@implementation VTApplicationRunningColorTransformer

+ (Class) transformedValueClass { 
	return [NSColor class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	if ([value isKindOfClass: [NSNumber class]] == NO)
		return nil; 
	
	if ([(NSNumber*)value boolValue])
		return [NSColor controlTextColor];
	else
		return [NSColor disabledControlTextColor]; 
		
	return nil; 
}

@end
