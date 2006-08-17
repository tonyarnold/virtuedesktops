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

#import "VTDesktopLayout.h" 

/**
 * VTPluginLayout 
 *
 * Plugin interface for plugins providing new kinds of desktop layouts and 
 * pagers. 
 *
 */ 
@protocol VTPluginLayout

#pragma mark -
#pragma mark Type factory 

- (Class) layoutClass; 

@end
