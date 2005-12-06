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

#import "VTDesktopControllerScripting.h"
#import "VTApplication.h" 
#import <Virtue/VTDesktop.h> 


@implementation VTDesktopController(VTScripting)

- (NSScriptObjectSpecifier*) objectSpecifier {
	// class description of the container class (the NSApplication) 
	id classDescription = [NSClassDescription classDescriptionForClass: [VTApplication class]];
	
	NSScriptObjectSpecifier* container = [[VTApplication sharedApplication] objectSpecifier];
	
	// NOTE: The key has to be synchronized with the VTApplicationDelegate interface 
	return [[[NSPropertySpecifier alloc] initWithContainerClassDescription: classDescription containerSpecifier: container key: @"desktopController"] autorelease];
}

- (VTDesktop*) valueInDesktopsWithUniqueID: (id) identifier {
	NSEnumerator*	desktopIter = [mDesktops objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject])
		if ([[desktop uuid] isEqual: identifier])
			return desktop; 
	
	return nil; 
}

#pragma mark -

- (VTDesktop*) valueInDesktopsAtIndex: (unsigned int) index {
	return [mDesktops objectAtIndex: index]; 
}

#pragma mark -

- (void) insertInDesktops: (VTDesktop*) desktop {
	[self insertObject: desktop inDesktopsAtIndex: [mDesktops count]]; 
}

- (void) removeFromDesktopsAtIndex: (unsigned int) index {
	[self removeObjectFromDesktopsAtIndex: index]; 
}

@end