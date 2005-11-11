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

#import "PNWindowScripting.h"
#import <Virtue/VTDesktopController.h> 

@implementation PNWindow(VTScripting)

- (NSScriptObjectSpecifier*) objectSpecifier {	
	// find our container 
	VTDesktop*		desktop		= [[VTDesktopController sharedInstance] desktopWithIdentifier: [self desktopId]]; 
	PNApplication*	application	= [desktop applicationForPid: [self ownerPid]]; 
	
	int index = [[application windows] indexOfObject: self]; 
	
	NSScriptObjectSpecifier* containerRef = [application objectSpecifier]; 
	return [[[NSIndexSpecifier alloc] initWithContainerClassDescription: [containerRef keyClassDescription] containerSpecifier: containerRef key: @"windows" index: index] autorelease]; 
}


#pragma mark -
#pragma mark Scripting commands 

- (void) sendToDesktopCommand: (NSScriptCommand*) command {
	NSDictionary*	arguments		= [command evaluatedArguments]; 
	VTDesktop*		targetDesktop	= [arguments objectForKey: @"to"]; 
	
	if (targetDesktop == nil)
		return; 
	
	[self setDesktop: targetDesktop]; 
}


@end
