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
#import "VTDesktopScripting.h" 

@implementation VTDesktopController(VTCoreScripting)

- (VTDesktop*) valueInDesktopsWithUniqueID: (id) identifier {
	NSLog(@"VTDesktopController.VTCoreScripting.valueInDesktopsWithUniqueID"); 

	NSEnumerator*	desktopIter = [mDesktops objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject])
		if ([[desktop uniqueIdentifier] isEqual: identifier])
			return desktop; 
	
	return nil; 
}

- (VTDesktop*) valueInDesktopsAtIndex: (unsigned int) index {
	NSLog(@"VTDesktopController.VTCoreScripting.valueInDesktopsAtIndex"); 

	return [mDesktops objectAtIndex: index]; 
}

@end
