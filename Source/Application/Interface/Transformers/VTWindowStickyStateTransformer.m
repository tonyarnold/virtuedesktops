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

#import "VTWindowStickyStateTransformer.h"

@implementation VTWindowStickyStateImage

+ (Class) transformedValueClass { 
	return [NSImage class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	if ([value isKindOfClass: [NSNumber class]] == NO)
		return nil; 
	
	if ([(NSNumber*)value boolValue])
		return [NSImage imageNamed: @"imageIsSticky"]; 
	else
		return [NSImage imageNamed: @"imageIsUnsticky"]; 
		
	return nil; 
}

@end

@implementation VTWindowStickyStateWidgetImage

+ (Class) transformedValueClass { 
	return [NSImage class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	if ([value isKindOfClass: [NSNumber class]] == NO)
		return nil; 
	
	if ([(NSNumber*)value boolValue] == NO)
		return [NSImage imageNamed: @"imageWidgetSticky"]; 
	else
		return [NSImage imageNamed: @"imageWidgetUnsticky"]; 
	
	return nil; 
}

@end

@implementation VTWindowStickyStateWidgetAlternateImage

+ (Class) transformedValueClass { 
	return [NSImage class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	if ([value isKindOfClass: [NSNumber class]] == NO)
		return nil; 
	
	if ([(NSNumber*)value boolValue] == NO)
		return [NSImage imageNamed: @"imageWidgetStickyPressed"]; 
	else
		return [NSImage imageNamed: @"imageWidgetUnstickyPressed"]; 
	
	return nil; 
}

@end
