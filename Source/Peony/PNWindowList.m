//
//  PNWindowList.m
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "PNWindowList.h"
#import "PNNotifications.h"
#import "PNDesktop.h" 
#import "PNDesktopItem.h" 
#import "CGSPrivate.h"
#import "DEComm.h"

@interface PNWindowList(Private)
- (NSArray*) nativeWindows; 
- (int) nativeWindowsInCArray: (int**) windows; 
@end 

#pragma mark -
@implementation PNWindowList

#pragma mark -
#pragma mark Lifetime 
+ (id) windowListWithArray: (NSArray*) windows {
	return [[[PNWindowList alloc] initWithArray: windows] autorelease]; 
}

#pragma mark -
- (id) init {
	return [self initWithArray: nil]; 
}

- (id) initWithArray: (NSArray*) windows {
	if (self = [super init]) {
		mWindows        = [[NSMutableArray alloc] init]; 
		mNativeWindows  = [[NSMutableArray alloc] init];
		
		if (windows)
			[self addWindows: windows]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	[mWindows release]; 
	[mNativeWindows release]; 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) addWindow: (PNWindow*) window {
	// adds the window to our list if it is not yet contained 
	if ([mWindows containsObject: window])
		return; 
	
	[mWindows addObject: window]; 
	[mNativeWindows addObject: [NSNumber numberWithInt: [window nativeWindow]]]; 
}

- (void) addWindows: (NSArray*) windows {
	// iterate the passed array and add all PNWindow objects 
	NSEnumerator*	windowIter	= [windows objectEnumerator]; 
	NSObject*		window		= nil; 
	
	while (window = [windowIter nextObject]) {
		if ([window isKindOfClass: [PNWindow class]] == NO)
			return; 
		
		[self addWindow: (PNWindow*)window]; 
	}
}

- (void) delWindow: (PNWindow*) window {
	// remove the window 
	[mWindows removeObject: window];
	[mNativeWindows removeObject: [NSNumber numberWithInt: [window nativeWindow]]]; 
}

- (void) delWindows: (NSArray*) windows {
	// iterate the passed array and delete all PNWindow objects 
	NSEnumerator*	windowIter	= [windows objectEnumerator];
	NSObject*			window			= nil;
	
	while (window = [windowIter nextObject]) {
		if ([window isKindOfClass: [PNWindow class]] == YES)
			[self delWindow: (PNWindow*)window]; 
	}
}

- (NSArray*) windows {
	return mWindows; 
}

#pragma mark -
- (void) setSticky: (BOOL) stickyState
{  
  int* windows; 
	int  windowsCount = [self nativeWindowsInCArray: &windows]; 
  
	if (stickyState == YES)
  {
		CGSExtSetWindowListTags(windows, windowsCount, CGSTagSticky); 
	}
	else
  {
		CGSExtClearWindowListTags(windows, windowsCount, CGSTagSticky); 
	}
	
	free(windows);
}

- (BOOL) isSticky 
{
	// cannot return anything useful here, think we should throw an exception
	return NO; 
}

#pragma mark -
- (void) setAlphaValue: (float) alpha animate: (BOOL) flag withDuration: (float) duration {
	if ([mWindows count] == 0)
		return; 
	
	int* windows; 
	int  windowsCount; 
		
	windowsCount = [self nativeWindowsInCArray: &windows]; 
	
	CGSExtSetWindowListAlpha(windows, windowsCount, 1.0, alpha, flag == YES ? 1 : 0, duration); 
	
	free(windows); 
}

- (void) setAlphaValue: (float) alpha {
	if ([mWindows count] == 0)
		return; 
	
	int* windows; 
	int  windowsCount; 
	
	windowsCount = [self nativeWindowsInCArray: &windows]; 
	
	CGSExtSetWindowListAlpha(windows, windowsCount, 1.0, alpha, 0, 0); 

	free(windows); 
}

- (float) alphaValue {
	// cannot return anything useful here, think we should throw an exception 
	return 0.0; 
}

#pragma mark -
- (int) desktopId {
	// cannot return anything useful here, think we should throw an exception 	
	return -1;
}

- (void) setDesktop: (PNDesktop*) desktop
{
    [self setDesktopId: [desktop identifier]];
}

- (void) setDesktopId: (int) desktopId
{
	if ([mWindows count] == 0)
		return; 
	
	int* windows; 
	int  windowsCount; 
	
	windowsCount = [self nativeWindowsInCArray: &windows]; 
	
	CGSExtSetWindowListWorkspace(windows, windowsCount, desktopId);  
    
	free(windows); 
}

#pragma mark -
- (NSString*) name {
	// cannot return anything useful here, think we should throw an exception 
	return nil; 
}

#pragma mark -
- (NSImage*) icon {
	// cannot return anything useful here, think we should throw an exception 
	return nil; 
}

#pragma mark -
#pragma mark Operations 

- (void) orderOut {
}

- (void) orderIn {
}

- (void) orderAbove: (NSObject<PNDesktopItem>*) item {
}

- (void) orderBelow: (NSObject<PNDesktopItem>*) item {
}

@end 

#pragma mark -
@implementation PNWindowList(Private)

- (NSArray*) nativeWindows {
	return mNativeWindows; 
}

- (int) nativeWindowsInCArray: (int**) windows {	
	// alloc the array 
	*windows = (int*)malloc(sizeof(int) * [mNativeWindows count]);
	// fill up 
	NSEnumerator*	windowIter	= [mNativeWindows objectEnumerator]; 
	NSNumber*			window			= nil; 
	int						i						= 0; 
	
	while (window = [windowIter nextObject]) {
		(*windows)[i] = [window intValue]; 
		i++; 
	}

	// return 
	return [mNativeWindows count]; 
}

@end
