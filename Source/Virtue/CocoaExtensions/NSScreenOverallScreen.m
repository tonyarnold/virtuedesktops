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

#import "NSScreenOverallScreen.h"


@implementation NSScreen (VTOverallScreen)

+ (NSRect) overallFrame
{
	NSRect			overallFrame	= [[NSScreen mainScreen] frame]; 

	// fetch all screens and return union of all of their frames 
	NSArray*		screens			= [NSScreen screens]; 
	NSEnumerator*   screenIter		= [screens objectEnumerator]; 
	NSScreen*		screen			= nil; 
		
	while (screen = [screenIter nextObject])
		overallFrame = NSUnionRect(overallFrame, [screen frame]); 
	
	return overallFrame; 
}

+ (NSRect) overallVisibleFrame
{
	NSRect			overallFrame	= [[NSScreen mainScreen] visibleFrame]; 
	
	// fetch all screens and return union of all of their visible frames 
	NSEnumerator*   screenIter		= [[NSScreen screens] objectEnumerator]; 
	NSScreen*		screen			= nil; 
	
	while (screen = [screenIter nextObject])
	{
		NSUnionRect(overallFrame, [screen visibleFrame]); 
	}
	
	return overallFrame; 
}

@end
