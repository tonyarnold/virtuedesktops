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

#import "VTTriggerToTypeImage.h"
#import "VTTrigger.h"
#import "VTHotkeyTrigger.h" 
#import "VTMouseTrigger.h"

@implementation VTTriggerToTypeImage

+ (Class) transformedValueClass { 
	return [NSNumber class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	if ([value isKindOfClass: [VTMouseTrigger class]]) 
		return [NSNumber numberWithInt: 1]; 

	return [NSNumber numberWithInt: 0];
}
	
@end
