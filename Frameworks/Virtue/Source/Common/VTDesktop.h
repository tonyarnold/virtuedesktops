/******************************************************************************
* 
* Virtue 
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
#import <Peony/Peony.h>

#import "VTCoding.h" 
#import "VTDesktopDecoration.h" 

@interface VTDesktop : PNDesktop<NSCoding, VTCoding> {
	// attributes 
	NSString*							mDesktopBackgroundImagePath; 
	NSString*							mDefaultDesktopBackgroundImagePath; 
	BOOL									mManagesIconset; 
	BOOL									mShowsBackground; 
	NSColor*							mColorLabel; 
	// decoration 
	VTDesktopDecoration*	mDecoration; 
	// unique identifier 
	NSString*							mUUID; 
}

#pragma mark Lifetime 
+ (id) desktopWithIdentifier: (int) identifier; 
+ (id) desktopWithName: (NSString*) name identifier: (int) identifier; 

#pragma mark -
- (id) initWithName: (NSString*) name identifier: (int) identifier; 

#pragma mark -
#pragma mark Attributes 

- (void) setDesktopBackground: (NSString*) path;  
- (NSString*) desktopBackground; 

#pragma mark -
- (void) setDefaultDesktopBackgroundPath: (NSString*) path;
- (NSString*) defaultDesktopBackgroundPath;

#pragma mark -
- (void) setManagesIconset: (BOOL) flag; 
- (BOOL) managesIconset; 

#pragma mark -
- (void) setShowsBackground: (BOOL) flag; 
- (BOOL) showsBackground; 

#pragma mark -
- (void) setColorLabel: (NSColor*) color; 
- (NSColor*) colorLabel; 

#pragma mark -
- (VTDesktopDecoration*) decoration; 

#pragma mark -
- (void) setName: (NSString*) name; 

#pragma mark -
- (NSString*) uuid; 

#pragma mark -
#pragma mark Persistency 
- (void) attachToDisk; 
- (void) detachFromDisk; 

#pragma mark -
#pragma mark Iconset  

- (void) showIconset; 
- (void) hideIconset; 

#pragma mark -
#pragma mark Desktop background

- (void) applyDesktopBackground; 
- (void) applyDefaultDesktopBackground; 

#pragma mark -
#pragma mark Class method 

+ (void) updateDesktopPath; 
+ (NSString*) currentDesktopBackground; 

+ (NSString*) virtualDesktopContainerPath; 
+ (NSString*) virtualDesktopPath: (VTDesktop*) desktop; 
+ (NSString*) virtualDesktopMetadataName; 
+ (NSString*) desktopContainerPath; 

@end
