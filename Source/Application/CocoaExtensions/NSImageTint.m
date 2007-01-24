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

#import "NSImageTint.h"


@implementation NSImage(VTTint)

- (NSImage*) tintWithColor: (NSColor*) color {
	NSImage*	targetImage = [[self copy] autorelease]; 
	NSRect		targetFrame = {NSZeroPoint, [targetImage size]}; 
	
	[targetImage lockFocus]; 
	[color set]; 
	NSRectFillUsingOperation(targetFrame, NSCompositeSourceAtop);
	[targetImage unlockFocus]; 
	
	return targetImage; 
}


@end
