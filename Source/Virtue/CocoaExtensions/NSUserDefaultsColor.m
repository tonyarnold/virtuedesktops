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
* See http://developer.apple.com/documentation/Cocoa/Conceptual/DrawColor/Tasks/StoringNSColorInDefaults.html
* for implementation details 
* 
*****************************************************************************/ 

#import "NSUserDefaultsColor.h"


@implementation NSUserDefaults (VTColor)

- (void) setColor: (NSColor*) aColor forKey: (NSString*) aKey
{
    NSData* theData = [NSArchiver archivedDataWithRootObject: aColor];
    [self setObject: theData forKey: aKey]; 
}

- (NSColor*) colorForKey: (NSString*) aKey
{
    NSColor*	theColor	= nil;
    NSData*		theData		= [self dataForKey: aKey];
	
    if (theData != nil)
        theColor = (NSColor*)[NSUnarchiver unarchiveObjectWithData: theData];
	
    return theColor;
}

@end
