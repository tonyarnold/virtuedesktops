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

@interface NSString(VTFSRef)
- (BOOL) createFSRef: (FSRef*) fsRef createIfNecessary: (BOOL) create; 
- (BOOL) createFSSpec: (FSSpec*) fsSpec createIfNecessary: (BOOL) create; 

@end
