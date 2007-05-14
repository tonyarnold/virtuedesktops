//
//  PNWindow.m
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <syslog.h>
#import "PNWindow.h"
#import "PNStickyWindowCollection.h"
#import "PNNotifications.h"
#import "PNDesktop.h"
#import "PNWindowPool.h"
#import "DECEvent.h"
#import <Zen/Zen.h>

#define CGSTransparentBackgroundMask (1<<7)

@implementation PNWindow

#pragma mark -
#pragma mark Lifetime

+ (PNWindow*) windowWithNSWindow: (NSWindow*) window {
	return [PNWindow windowWithWindowId: [window windowNumber]];
}

+ (PNWindow*) windowWithWindowId: (CGSWindow) window {
	return [[PNWindowPool sharedWindowPool] windowWithId: window];
}

#pragma mark -
/*
 * @brief Designated initializer for PNWindow instances
 *
 * @param windowId	The native CGSWindow id that is wrapped by the initialized instance
 *
 */
- (id) initWithWindowId: (CGSWindow) windowId {
	if (self = [super init]) {
		mNativeWindow		= windowId;
		mOwnerPid			= kPnWindowInvalidPid;
		mIsSticky			= NO;
		mIsSpecial			= NO;
		mIsIgnoredByExpose	= NO;
		return self;
	}
	return nil;
}

/*
 * @brief Initializer for PNWindow instances
 *
 * @param window	The native NSWindow instance that should be wrapped by the initialized instance
 *
 */
- (id) initWithNSWindow: (NSWindow*) window {
	// ask the passed window for its CGSWindow
	CGSWindow nativeWindow = [window windowNumber];
  
	// pass on initialization using the CGSWindow id
	return [self initWithWindowId: nativeWindow];
}

- (void) dealloc {
	[mIcon release];
  
	[super dealloc];
}

#pragma mark -
#pragma mark Operations

- (BOOL) isEqual: (id) toObject {
	if ([toObject isKindOfClass: [PNWindow class]] == NO)
		return NO;
  
	return (((PNWindow*)toObject)->mNativeWindow == mNativeWindow);
}

#pragma mark -
- (void) orderAbove: (NSObject<PNDesktopItem>*) item {
	// if we are ordering relative to a window, we just take that window and pass it
	// on. in case of something else... i do not know yet ;)
	if (item == nil)
		CGSExtOrderWindow(mNativeWindow, kCGSOrderAbove, 0);
	else if ([item isKindOfClass: [PNWindow class]])
		CGSExtOrderWindow(mNativeWindow, kCGSOrderAbove, [(PNWindow*)item nativeWindow]);
}

- (void) orderBelow: (NSObject<PNDesktopItem>*) item {
	// if we are ordering relative to a window, we just take that window and pass it
	// on. in case of something else... i do not know yet ;)
	if ([item isKindOfClass: [PNWindow class]])
		CGSExtOrderWindow(mNativeWindow, kCGSOrderBelow, [(PNWindow*)item nativeWindow]);
}

- (void) orderOut {
}

- (void) orderIn {
}

#pragma mark -
- (BOOL) isValid {
	CGSConnection	oConnection = _CGSDefaultConnection();
	OSStatus			oResult;
	int						iLevel;
  
	oResult = CGSGetWindowLevel(oConnection, mNativeWindow, &iLevel);
	if (oResult) {
		return NO;
	}
  
	return YES;
}

#pragma mark -
- (void) setProperty: (NSString*) property forKey: (NSString*) key {
	CGSExtSetWindowProperty(mNativeWindow, [key cString], [property cString]);
}

- (NSString*) propertyForKey: (NSString*) key {
	CGSConnection oConnection = _CGSDefaultConnection();
	OSStatus		iResult;
  
  CGSValue		oKey = CGSCreateCStringNoCopy([key cString]);
	CGSValue		oValue;
  
	iResult = CGSGetWindowProperty(oConnection, mNativeWindow, oKey, &oValue);
	if (iResult)
		return nil;
  
	char* acValueString = CGSCStringValue(oValue);
	if (acValueString)
		return [NSString stringWithUTF8String: acValueString];
  
	return nil;
}

#pragma mark -
#pragma mark Accessors

- (int) desktopId {
	// fetch the desktop this window resides on
	CGSConnection	oConnection = _CGSDefaultConnection();
	int iDesktopId	= -1;
  
	OSStatus oResult = CGSGetWindowWorkspace(oConnection, mNativeWindow, &iDesktopId);
	if (oResult) {
		ZNLog( @"PNWindow.m - [Window: %i] Failed getting workspace id [Error: %i]", mNativeWindow, oResult);
		return kPnDesktopInvalidId;
	}
  
	return iDesktopId;
}

- (void) setDesktopId: (int) desktopId {
	if ([self isSticky])
		return;
  
	// notification parameters
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt: [self desktopId]], PNWindowChangeDesktopSourceParam,
		[NSNumber numberWithInt: desktopId], PNWindowChangeDesktopTargetParam,
		nil];
	
	// send notification about the upcoming change
	[[NSNotificationCenter defaultCenter] postNotificationName: PNWindowWillChangeDesktop object: self userInfo: userInfo];
	
	CGSExtSetWindowWorkspace(mNativeWindow, desktopId);
	
		// post notification about the change
	[[NSNotificationCenter defaultCenter] postNotificationName: PNWindowDidChangeDesktop object: self userInfo: userInfo];
}

/*
 * @brief Attaches the window to the passed desktop
 *
 * @param desktop The desktop that will become the owner of this window
 *
 */
- (void) setDesktop: (PNDesktop*) desktop {
	// We won't allow setting a nil desktop
	if (desktop == nil)
		return;
  
	[self setDesktopId: [desktop identifier]];
}

#pragma mark -
- (CGSWindow) nativeWindow {
	return mNativeWindow;
}

- (NSString*) name {
	static CGSValue kCGSWindowTitle = (int)NULL;
		// we have to create the private constant
	if (kCGSWindowTitle == (int)NULL)
		kCGSWindowTitle = CGSCreateCStringNoCopy("kCGSWindowTitle");
  
	CGSValue oWindowTitle = (int)NULL;
	OSStatus oResult;
  
	// get connection
	CGSConnection oConnection = _CGSDefaultConnection();
  
	// get the window title
	oResult = CGSGetWindowProperty(oConnection, mNativeWindow, kCGSWindowTitle, &oWindowTitle);
	if (oResult) {
		return nil;
	}
  
	char* acStrVal = CGSCStringValue(oWindowTitle);
	if (acStrVal) {
		return [NSString stringWithUTF8String: acStrVal];
	}
  
	return nil;
}

- (BOOL) isOrderedIn
{
  OSStatus oResult;
  Boolean orderedIn = NO;
 
	// Is the window currently displayed on the desktop we're interested in?
	oResult = CGSWindowIsOrderedIn(_CGSDefaultConnection(), mNativeWindow,  &orderedIn);
	if (oResult) {
		return NO;
	}
  return orderedIn;
}

#pragma mark -
#pragma mark Window Level Conveniences

- (BOOL)isMenu
{
	int level = [self level];
	
	return (level == NSPopUpMenuWindowLevel) || (level == NSSubmenuWindowLevel) || (level == NSMainMenuWindowLevel);
}
- (BOOL)isPalette
{
	int level = [self level];
	
	return (level == kCGUtilityWindowLevelKey) || (level == kCGBackstopMenuLevelKey) || (level == kCGFloatingWindowLevelKey);
}


#pragma mark -
- (BOOL) isSpecial {
	return mIsSpecial;
}

- (void) setSpecial: (BOOL) special {
	mIsSpecial = special;
}

#pragma mark -
- (int) level {
	CGSConnection		oConnection = _CGSDefaultConnection();
	OSStatus			oResult;
	int					iLevel;
  
	oResult = CGSGetWindowLevel(oConnection, mNativeWindow, &iLevel);
	if (oResult)
		return kPnWindowInvalidLevel;
  
	return iLevel;
}

- (void) setLevel: (int) level {
	CGSExtSetWindowLevel(mNativeWindow, level);
}

#pragma mark -
- (float) alphaValue {
	CGSConnection		oConnection = _CGSDefaultConnection();
	OSStatus				oResult;
	float						fAlpha;
  
	oResult = CGSGetWindowAlpha(oConnection, mNativeWindow, &fAlpha);
	if (oResult)
		return 1.0;
  
	return fAlpha;
}

- (void) setAlphaValue: (float) alpha {
	CGSExtSetWindowAlpha(mNativeWindow, [self alphaValue], alpha, 0, 0);
}

- (void) setAlphaValue: (float) alpha animate: (BOOL) flag withDuration: (float) duration {
	CGSExtSetWindowAlpha(mNativeWindow, [self alphaValue], alpha, flag == YES ? 1 : 0, duration);
}

#pragma mark -
/*
 * @brief Sets the window to be stickied according to the passed flag
 *
 * @param stickyState If set ot @c YES, the window will be stickied, if
 *						set to @c NO, the window will become nonsticky.
 *
 * @notify		kPnOnWindowStickied
 *					'object'	self
 * @notify		kPnOnWindowUnstickied
 *					'object'	self
 *
 * @distnotify	kPnOnWindowStickied
 *					'window'	self.mNativeWindow
 * @distnotify	kPnOnWindowUnstickied
 *					'window'	self.mNativeWindow
 */
- (void) setSticky: (BOOL) stickyState
{
	NSDictionary* infoDict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: mNativeWindow], @"window", nil];
  
	if (stickyState == YES)
  {
		// post notification about the window becoming sticky
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName: kPnOnWindowStickied object: nil userInfo: infoDict];
		[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnWindowStickied object: self];
	}
	else
  {
		// post notification about the window being no longer sticky
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName: kPnOnWindowUnstickied object: nil userInfo: infoDict];
		[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnWindowUnstickied object: self];
	}
  
	// set sticky state
	mIsSticky = stickyState;
}

/**
* @brief		Query the sticky state of the window
 *
 * @return	Returns @c YES if the window is sticky.
 *
 * This method will only check the cached setting without querying the
 * windowing system. We trust ourselves to be consistent there.
 *
 */
- (BOOL) isSticky
{
	return mIsSticky;
}

#pragma mark -
- (void) setIgnoredByExpose: (BOOL) flag
{
	// first set our flag
	mIsIgnoredByExpose = flag;
  
	// now set the window tag accordingly
	if (flag)
		CGSExtClearWindowTags(mNativeWindow, CGSTagExposeFade);
	else
		CGSExtSetWindowTags(mNativeWindow, CGSTagExposeFade);
}

- (BOOL) isIgnoredByExpose
{
	return mIsIgnoredByExpose;
}

#pragma mark -
- (void) clearWindowTags {
	int tags[2];
	
	tags[0] = 0x02;
	tags[1] = 0;
	
	CGSExtClearWindowTags(mNativeWindow, tags);
}


#pragma mark -
- (NSRect) screenRectangle {
	NSRect			rect;
	OSStatus		oResult;
	CGSConnection		oConnection = _CGSDefaultConnection();
  
	oResult = CGSGetScreenRectForWindow(oConnection, mNativeWindow, (CGRect*)&rect);
	if (oResult)
		return NSMakeRect(0, 0, 0, 0);
  
	return rect;
}

#pragma mark -
- (NSImage*) icon {
//	if (mIcon == nil) {
//		mIcon = [NSImage imageNamed: @"imageWindow.png"];
//	}
	return [NSImage imageNamed: @"imageWindow.png"];
}

#pragma mark -
- (pid_t) ownerPid {
	if (mOwnerPid != kPnWindowInvalidPid)
		return mOwnerPid;
  
	OSStatus		oResult;
  
	CGSConnection		oConnection = _CGSDefaultConnection();
	CGSConnection		oOwnerCID;
  
	if (oResult = CGSGetWindowOwner(oConnection, mNativeWindow, &oOwnerCID)) {
		ZNLog( @"PNWindow.m - [Window: %i] Failed getting window owner [Error: %i]", mNativeWindow, oResult);
		return 0;
	}
  
	if (oResult = CGSConnectionGetPID(oOwnerCID, &mOwnerPid, oOwnerCID)) {
		ZNLog( @"PNWindow.m - [Window: %i] Failed getting owner PID [Error: %i]", mNativeWindow, oResult);
		mOwnerPid = kPnWindowInvalidPid;
	}
  
	return mOwnerPid;
}

- (ProcessSerialNumber) ownerPsn {
		ProcessSerialNumber oOwnerPsn;
		OSStatus			oResult;
    
    oOwnerPsn.highLongOfPSN = 0;
    oOwnerPsn.lowLongOfPSN = 0;
    
    if ([self ownerPid] == kPnWindowInvalidPid)
      return oOwnerPsn;
    
    oResult = GetProcessForPID([self ownerPid], &oOwnerPsn);
    if (oResult) {
      ZNLog( @"PNWindow.m - [Window: %i] Failed getting owner PSN [Error: %i]", mNativeWindow, oResult);
    }
    
    return oOwnerPsn;
}

@end