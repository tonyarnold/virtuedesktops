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
#import "VTCoding.h" 
#import "VTDesktop.h" 

@interface VTApplicationWrapper : NSObject<VTCoding> {
	NSString*	mBundle; 
	
	// running applications 
	pid_t		mPid; 
	// general 
	NSString*	mTitle; 
	NSImage*	mImage; 
	VTDesktop*	mDesktop; 
	BOOL		mSticky; 
	BOOL		mHidden; 
	BOOL		mBindDesktop; 
	
	NSMutableArray*	mApplications; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (id) initWithBundlePath: (NSString*) bundlePath; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setSticky: (BOOL) flag; 
- (BOOL) isSticky; 

#pragma mark -
- (void) setHidden: (BOOL) flag; 
- (BOOL) isHidden; 

#pragma mark -
- (void) setBindingToDesktop: (BOOL) flag; 
- (BOOL) isBindingToDesktop; 

#pragma mark -
- (void) setBoundDesktop: (VTDesktop*) desktop; 
- (VTDesktop*) boundDesktop; 

#pragma mark -
- (NSImage*) icon; 
- (NSArray*) windows; 
- (NSString*) title; 

#pragma mark -
- (BOOL) isRunning; 

#pragma mark -
- (NSString*) bundlePath; 

#pragma mark -
#pragma mark Notification delegate 
- (void) onApplicationAttached: (NSNotification*) notification; 
- (void) onApplicationDetached: (NSNotification*) notification; 
@end


