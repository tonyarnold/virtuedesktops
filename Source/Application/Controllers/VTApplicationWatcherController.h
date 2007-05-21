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

#import <Cocoa/Cocoa.h>

/**
 * @brief	Handles automatic desktop switching upon application activation and
 *			general application activation strategies 
 *
 * Our strategy for switching can be outlines as 
 *
 * - we want to switch if a new application did become active as a direct 
 *   result of an action triggered by the user. 
 * - we do not want to switch if an application did become active because 
 *   another application did resign focus [TODO]
 * - if an application has windows on multiple desktops, we will not switch
 *   automatically, as we cannot decide where to switch
 * - we want to switch if the user holds down a predefined modifier key 
 *   or key combination to tell Virtue, that the activation was intentional
 *   [DONE VIA PREFERENCES]
 */ 
@interface VTApplicationWatcherController : NSObject {
	ProcessSerialNumber		mFinderPSN; 
	ProcessSerialNumber		mPSN; 
	ProcessSerialNumber		mActivatedPSN; 
}

- (id) init; 
- (void) dealloc; 
- (void) setupAppChangeNotification;

@end
