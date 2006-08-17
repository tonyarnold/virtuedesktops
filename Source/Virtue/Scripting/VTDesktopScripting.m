/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDesktopScripting.h"
#import "VTDesktopController.h"


@implementation VTDesktop(VTCoreScripting)

- (NSNumber*) uniqueIdentifier {
	return [NSNumber numberWithUnsignedInt: (unsigned int)self]; 
}

- (NSScriptObjectSpecifier*) objectSpecifier {	
	NSLog(@"VTDesktop.VTCoreScripting.objectSpecifier"); 
	
	int index = [[[VTDesktopController sharedInstance] desktops] indexOfObject: self]; 
	
	NSScriptObjectSpecifier* containerRef = [[VTDesktopController sharedInstance] objectSpecifier]; 
	return [[[NSIndexSpecifier alloc] initWithContainerClassDescription: [containerRef keyClassDescription] containerSpecifier: containerRef key: @"desktops" index: index] autorelease]; 
}

#pragma mark -
#pragma mark Scripting Commands 

- (void) activateDesktopCommand: (NSScriptCommand*) command {
	// trigger activation via the desktop controller, that will take care of checks 
	[[VTDesktopController sharedInstance] activateDesktop: self]; 
}

@end
