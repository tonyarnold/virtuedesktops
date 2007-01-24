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

#define VTBackgroundHelperDesktopChangedName			@"com.apple.desktop"
#define VTBackgroundHelperDesktopChangedObject		@"BackgroundChanged"


typedef enum VTBackgroundHelperMode {
	// no mode used, background changes disabled 
	VTBackgroundHelperModeNone		= 0, 
	// using the Finder process to update the background image 
	VTBackgroundHelperModeFinder	= 1, 
	// using a bruteforce attack at the com.apple.desktop plist 
	VTBackgroundHelperModePList		= 2, 
} VTBackgroundHelperMode; 

@interface VTDesktopBackgroundHelper : NSObject {
	VTBackgroundHelperMode		mMode; 
	pid_t                     mFinderPid; 
  NSString*                 mDefaultDesktopBackgroundPath;
}

#pragma mark -
#pragma mark Lifetime 
+ (id) sharedInstance;

#pragma mark -
#pragma mark Attributes 
- (VTBackgroundHelperMode) mode; 

#pragma mark -
- (BOOL) canSetBackground; 

#pragma mark -
#pragma mark Operations 
- (void) setBackground: (NSString*) path;
- (NSString*) background;
- (void) setDefaultBackground: (NSString*) path;
- (NSString*) defaultBackground;

@end
