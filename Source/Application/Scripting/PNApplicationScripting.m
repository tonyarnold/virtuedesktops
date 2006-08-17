/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "PNApplicationScripting.h"
#import <Virtue/VTDesktop.h> 
#import <Virtue/VTDesktopController.h> 

@implementation PNApplication(VTScripting)

- (NSScriptObjectSpecifier*) objectSpecifier {
	VTDesktop* desktop = [[VTDesktopController sharedInstance] desktopWithIdentifier: [self desktopId]]; 
	
	int index = [[desktop applications] indexOfObject: self]; 
	
	NSScriptObjectSpecifier* containerRef = [desktop objectSpecifier]; 
	return [[[NSIndexSpecifier alloc] initWithContainerClassDescription: [containerRef keyClassDescription] 
                                                   containerSpecifier: containerRef 
                                                                  key: @"applications" 
                                                                index: index] autorelease]; 
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