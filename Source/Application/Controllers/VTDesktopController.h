/******************************************************************************
*
* VirtueDesktops framework
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
*
*****************************************************************************/

#import <Cocoa/Cocoa.h>
#import <Peony/Peony.h> 
#import "VTDesktopLayout.h" 
#import "VTDesktopDecoration.h" 
#import "VTDesktop.h" 


@interface VTDesktopController : NSObject {
	NSMutableArray*       _desktops; 
	NSMutableArray*       mApplications; 
	NSMutableDictionary*	mDesktopWatchers; 
	
	VTDesktop*						mPreviousDesktop; 
	VTDesktop*						mSnapbackDesktop; 
	
	NSString*							mDefaultDesktopBackgroundPath;
	
	VTDesktopDecoration*	mDecorationPrototype; 
	BOOL									mUsesDecorationPrototype;	
	BOOL									mExpectingBackgroundChange; 
}

#pragma mark -
#pragma mark Lifetime 

+ (VTDesktopController*) sharedInstance; 

#pragma mark -
#pragma mark Factories 

- (VTDesktop*) desktopWithFreeId; 
- (int) freeId; 
	
#pragma mark -
#pragma mark Attributes 

- (NSMutableArray*) desktops;
- (void) setDesktops: (NSArray*)newDesktops;
- (void) addInDesktops: (VTDesktop*) desktop; 
- (void) insertObject: (VTDesktop*) desktop inDesktopsAtIndex: (unsigned int) index;
- (void) removeObjectFromDesktopsAtIndex: (unsigned int) index;
- (void) sendWindowUnderCursorBack;
- (void) moveWindowUnderCursorToDesktop: (VTDesktop*) desktop;

#pragma mark -
- (BOOL) canAdd;
- (BOOL) canDelete; 

#pragma mark -
- (VTDesktopDecoration*) decorationPrototype; 
- (void) setDecorationPrototype: (VTDesktopDecoration*) prototype; 

#pragma mark -
- (void) setUsesDecorationPrototype: (BOOL) flag; 
- (BOOL) usesDecorationPrototype; 

#pragma mark -

- (VTDesktop*) activeDesktop; 
- (VTDesktop*) previousDesktop; 
- (VTDesktop*) snapbackDesktop; 

#pragma mark -
#pragma mark Querying 

- (VTDesktop*) desktopWithUUID: (NSString*) uuid; 
- (VTDesktop*) desktopWithIdentifier: (int) identifier; 
- (VTDesktop*) getDesktopInDirection: (VTDirection) direction;

#pragma mark -
#pragma mark Desktop switching 

- (void) activateDesktop: (VTDesktop*) desktop;
- (void) activateDesktop: (VTDesktop*) desktop usingTransition: (PNTransitionType) type withOptions: (PNTransitionOption) options withDuration: (float) duration; 
- (void) activateDesktopInDirection: (VTDirection) direction; 

#pragma mark -
#pragma mark Desktop persistency 

- (void) serializeDesktops;
- (void) deserializeDesktops; 

#pragma mark -

- (void) applyDecorationPrototype: (BOOL) overwrite;

@end
