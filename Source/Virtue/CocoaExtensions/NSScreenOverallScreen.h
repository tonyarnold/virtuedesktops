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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/**
 * @brief	Overall screen frame and overall visible screen frame extensions
 *
 */ 
@interface NSScreen (VTOverallScreen)

+ (NSRect) overallFrame; 
+ (NSRect) overallVisibleFrame; 

@end
