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

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

/**
 * @brief Category of NSUserDefaults to store NSColor objects 
 *
 * See http://developer.apple.com/documentation/Cocoa/Conceptual/DrawColor/Tasks/StoringNSColorInDefaults.html
 * for details 
 *
 */ 
@interface NSUserDefaults (VTColor)

- (void) setColor: (NSColor*) aColor forKey:(NSString*) aKey;
- (NSColor*) colorForKey: (NSString*) aKey;

@end
