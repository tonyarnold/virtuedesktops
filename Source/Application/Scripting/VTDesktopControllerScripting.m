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

#import "VTDesktopControllerScripting.h"
#import "VTApplication.h" 
#import "VTDesktop.h"


@implementation VTDesktopController(VTScripting)

- (NSScriptObjectSpecifier*) objectSpecifier {
	// class description of the container class (the NSApplication) 
	id classDescription = [NSClassDescription classDescriptionForClass: [VTApplication class]];
	
	NSScriptObjectSpecifier* container = [[VTApplication sharedApplication] objectSpecifier];
	
	// NOTE: The key has to be synchronized with the VTApplicationDelegate interface 
	return [[[NSPropertySpecifier alloc] initWithContainerClassDescription: classDescription containerSpecifier: container key: @"desktopController"] autorelease];
}

- (VTDesktop*) valueInDesktopsWithUniqueID: (id) identifier {
	NSEnumerator*	desktopIter = [_desktops objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject])
		if ([[desktop uuid] isEqual: identifier])
			return desktop; 
	
	return nil; 
}

#pragma mark -

- (void) insertInDesktops: (VTDesktop*) desktop 
{
  [self insertObject: desktop inDesktopsAtIndex: [_desktops count]];
}

- (void) removeFromDesktopsAtIndex: (unsigned int) desktopIndex 
{
  [self removeObjectFromDesktopsAtIndex: desktopIndex];
}

@end
