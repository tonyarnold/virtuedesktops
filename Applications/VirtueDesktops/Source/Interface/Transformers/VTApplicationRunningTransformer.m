/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTApplicationRunningTransformer.h"
#import <Virtue/VTApplicationWrapper.h> 

@implementation VTApplicationRunningTransformer

+ (Class) transformedValueClass { 
	return [NSString class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	if ([value isKindOfClass: [NSNumber class]] == NO)
		return nil; 
	
	if ([(NSNumber*)value boolValue])
		return NSLocalizedString(@"VTApplicationRunningStateYes", @"The running state description for running applications"); 
	else
		return NSLocalizedString(@"VTApplicationRunningStateNo", @"The running state description for running applications"); 
	
	return nil; 
}

@end