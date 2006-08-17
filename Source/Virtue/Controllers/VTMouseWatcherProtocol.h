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

/**
* @brief	Protocol clients of a VTMouseWatcherController should implement 
 *
 */ 
@protocol VTMouseWatcherProtocol

- (void) mouseEntered: (NSEvent*) event; 
- (void) mouseExited: (NSEvent*) event; 

- (void) mouseDown: (NSEvent*) event; 

@end
