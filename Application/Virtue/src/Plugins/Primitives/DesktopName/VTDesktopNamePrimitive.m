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

#import "VTDesktopNamePrimitive.h"
#import <Virtue/VTDesktopDecoration.h>
#import <Virtue/VTDesktop.h>

#pragma mark -
@implementation VTDesktopNamePrimitive

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		mName = @"Desktop Name Primitive"; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// bindings 
	[self unbind: @"text"]; 
	// super... 
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		// set up binding 
		if (([self container]) && ([[self container] desktop]))
			[self bind: @"text" toObject: [[self container] desktop] withKeyPath: @"name" options: nil]; 	
				
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder]; 
}

#pragma mark -
#pragma mark VTDecorationPrimitive overrides 

- (void) setContainer: (VTDesktopDecoration*) container {
	// first remove any existing binding
	[self unbind: @"text"]; 
	// trigger call to super 
	[super setContainer: container]; 
	
	// and attach to the desktop inside the container 
	if ((container != nil) && ([container desktop] != nil))
		[self bind: @"text" toObject: [[self container] desktop] withKeyPath: @"name" options: nil]; 	
	else
		[self setText: @""]; 
}

@end


