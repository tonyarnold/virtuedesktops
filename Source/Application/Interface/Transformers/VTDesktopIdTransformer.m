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

#import "VTDesktopIdTransformer.h"
#import "VTDesktopController.h"

@implementation VTDesktopIdTransformer

+ (Class) transformedValueClass { 
	return [VTDesktop class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return YES; 
}

- (id) transformedValue: (id) value {
	if ([value isKindOfClass: [NSNumber class]] == NO)
		return nil; 
	
	return [[VTDesktopController sharedInstance] desktopWithIdentifier: [(NSNumber*)value intValue]]; 
}

- (id) reverseTransformedValue: (id) value {
	if ([value isKindOfClass: [VTDesktop class]] == NO) 
		return nil; 
	
	return [NSNumber numberWithInt: [(VTDesktop*)value identifier]]; 
}

@end
