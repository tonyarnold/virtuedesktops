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

#import "VTDesktopNamePrimitive.h"

#pragma mark -
@implementation VTDesktopNamePrimitive

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		mName = @"Desktop Name Decoration";
    return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
    [self bind: @"text" toObject: [self container] withKeyPath: @"desktop.name" options: nil];
    return self;
	}
	
	return nil; 
}

#pragma mark -
#pragma mark VTDecorationPrimitive overrides 

- (void) setContainer: (VTDesktopDecoration*) container {
  [self unbind: @"text"];
  [self bind: @"text" toObject: container withKeyPath: @"desktop.name" options: nil];
  [super setContainer: container];
}

@end
