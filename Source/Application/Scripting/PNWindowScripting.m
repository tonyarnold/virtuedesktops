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

#import "PNWindowScripting.h"
#import "VTDesktopController.h" 

@implementation PNWindow(VTScripting)

- (NSScriptObjectSpecifier*) objectSpecifier {	
	// find our container 
	VTDesktop*      desktop			= [[[VTDesktopController sharedInstance] desktopWithIdentifier: [self desktopId]] retain]; 
	PNApplication*	application	= [[desktop applicationForPid: [self ownerPid]] retain]; 
	
	int windowIndex = [[application windows] indexOfObject: self]; 
	
	NSScriptObjectSpecifier* containerRef = [application objectSpecifier]; 
  [desktop release];
  [application release];
	return [[[NSIndexSpecifier alloc] initWithContainerClassDescription: [containerRef keyClassDescription] containerSpecifier: containerRef key: @"windows" index: windowIndex] autorelease]; 
}


#pragma mark -
#pragma mark Scripting commands 

- (void) sendToDesktopCommand: (NSScriptCommand*) command {
	NSDictionary*	arguments			= [command evaluatedArguments]; 
	VTDesktop*		targetDesktop	= [arguments objectForKey: @"to"]; 
	
	if (targetDesktop == nil)
		return; 
	
	[self setDesktop: targetDesktop]; 
}


@end
