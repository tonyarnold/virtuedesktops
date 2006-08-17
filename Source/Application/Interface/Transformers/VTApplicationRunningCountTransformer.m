/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTApplicationRunningCountTransformer.h"
#import <Virtue/VTDesktop.h> 

@implementation VTApplicationRunningCountTransformer

+ (Class) transformedValueClass { 
	return [NSString class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	NSString*	format	= NSLocalizedString(@"VTDesktopRunningApplicationCount", @"Template String"); 
	NSString*	number; 
	NSString*	application; 
	int			count	= [value count];
	
	if ((count == 0) || (count > 1)) {
		if (count == 0)
			number	= NSLocalizedString(@"VTDesktopRunningApplicationCountNone", @"No applications number"); 
		else
			number	= [NSString stringWithFormat: @"%i", count];

		application	= NSLocalizedString(@"VTDesktopRunningApplicationPlural", @"Plural form of applications");
	}
	else {
		number		= @"1";
		application	= NSLocalizedString(@"VTDesktopRunningApplicationSingluar", @"Plural form of applications");
	}
		
	return [NSString stringWithFormat: format, number, application];
}

@end
