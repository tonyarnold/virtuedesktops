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


@protocol VTPager

/**
 * Implement to display the pager upon request. The closing behaviour 
 * should be bound to the stick parameter. If stick is NO, the pager
 * should auto-hide if one of the flag keys (Option, Command, Alternate)
 * are released; if it is YES, the pager should stay visible as long as 
 * it loses key focus, a desktop is selected or hide is called. 
 *
 */ 
- (void) display: (BOOL) stick; 

/**
 * Implement to hide the pager upon request. The method hard-closes the 
 * pager, there should not be a condition that keeps the pager on-screen
 * after a call to this method 
 *
 */ 
- (void) hide; 

@end
