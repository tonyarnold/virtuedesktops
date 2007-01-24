//
//  VTApplicationRunningCountTransformer.m
//  VirtueDesktops
//
//  Created by Tony on 1/10/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#import "VTApplicationRunningCountTransformer.h"
#import "VTDesktop.h"

@implementation VTApplicationRunningCountTransformer

+ (Class) transformedValueClass { 
	return [NSString class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (id) transformedValue: (id) value {
	NSString*	format = NSLocalizedString(@"VTDesktopRunningApplicationCount", @"Template String"); 
	NSString*	number; 
	NSString*	application; 
	int       count	= [value count];
	
	if ((count == 0) || (count > 1)) {
		if (count == 0) {
      number	= NSLocalizedString(@"VTDesktopRunningApplicationCountNone", @"No applications number"); 
		} else {
      number	= [NSString stringWithFormat: @"%i", count];
    }
			
		application	= NSLocalizedString(@"VTDesktopRunningApplicationPlural", @"Plural form of applications");
    
	} else {
		number      = @"1";
		application	= NSLocalizedString(@"VTDesktopRunningApplicationSingluar", @"Plural form of applications");
	}
	return [NSString stringWithFormat: format, number, application];
}

@end
