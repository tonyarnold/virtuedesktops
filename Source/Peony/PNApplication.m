/******************************************************************************
* Peony framework
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "PNApplication.h"
#import "PNWindowList.h"
#import "PNNotifications.h"
#import <Zen/Zen.h> 

@implementation PNApplication

#pragma mark -
#pragma mark Lifetime 
- (id) initWithPid: (pid_t) pid onDesktop: (PNDesktop*) desktop 
{
	if (self = [super init])
  {
		mPid			= pid; 
		mDesktop	= [desktop retain]; 
		mWindows	= [[NSMutableArray array] retain]; 
		
		mName			= nil; 
		mIcon			= [[[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericApplicationIcon)] retain]; 
		mBundlePath	= nil; 
		
		mIsSticky	= NO; 
		mIsHidden	= NO;
    mIsUnfocused = NO;
		
		if (mPid == 0)
    {
			// oops, no can do with this pid 
			[self autorelease]; 
			return nil; 
		}
		
		// Create psn out of the pid
		OSStatus oResult = GetProcessForPID(mPid, &mPsn); 
		if (!oResult)
    {
			return self;
		}
    else
    {
			[self autorelease]; 
			return nil;
		}
	}
	
	return nil; 
}

- (void) dealloc
{
	// attributes 
	ZEN_RELEASE(mWindows); 
	ZEN_RELEASE(mName); 
	ZEN_RELEASE(mIcon); 
	ZEN_RELEASE(mDesktop); 
	ZEN_RELEASE(mBundlePath); 
	
	// super 
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 

- (pid_t) pid
{
	return mPid; 
}

- (ProcessSerialNumber) psn
{
	return mPsn; 
}

#pragma mark -
- (NSArray*) windows
{
  return mWindows; 
}

#pragma mark -
- (void) setHidden: (BOOL) hidden
{
	mIsHidden = hidden; 
}

- (BOOL) isHidden
{
	return mIsHidden; 
}


#pragma mark -
- (void) setSticky: (BOOL) stickyState
{  
  NSEnumerator*   windowIterator			= [[self windows] objectEnumerator];
	PNWindow*       window							= nil;
	
	while (window = [windowIterator nextObject]) {
		[window setSticky: stickyState];
	}
	
	if (stickyState == YES) 
  {
		// post notification about the window becoming sticky 
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName: kPnOnApplicationStickied object: nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnApplicationStickied object: mWindows]; 
	}
  else
  {
		// post notification about the window being no longer sticky 
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName: kPnOnApplicationUnstickied object: nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnApplicationUnstickied object: mWindows];		
	}
	mIsSticky = stickyState;
}

- (BOOL) isSticky 
{
	return mIsSticky; 
}

#pragma mark -
- (void) setUnfocused: (BOOL) unfocused
{
  mIsUnfocused = unfocused; 
}

- (BOOL) isUnfocused
{
  return mIsUnfocused; 
}

#pragma mark -

- (void) setAlphaValue: (float) alpha animate: (BOOL) flag withDuration: (float) duration 
{
  
}

- (void) setAlphaValue: (float) alpha 
{
  
}

- (float) alphaValue 
{
	// currently we return 1.0 here, as there is no meaningful value to return 
	// for a collection of windows... 
	return 1.0f; 
}

#pragma mark -

- (PNDesktop*) desktop {
	return mDesktop; 
}

- (int) desktopId {
	return [mDesktop identifier]; 
}

/**
 * @todo	Move this method from separate window handling to handling a window list, which should be much more effecient
 *
 */ 
- (void) setDesktop: (PNDesktop*) desktop {
	// We will not modify the desktop we belong to but will just move all the windows we know about to the passed desktop, a new application instance will be created there...
	
	NSMutableArray* windowsForSwitching = [[NSMutableArray alloc] init];
	NSEnumerator*   windowIter					= [mWindows objectEnumerator];
	PNWindow*       window							= nil;
  
	       
	while (window = [windowIter nextObject]) {
		if ([window isSticky] == 0)
			[windowsForSwitching addObject: window];
	}
	PNWindowList* mWindowList = [[PNWindowList alloc] initWithArray: windowsForSwitching];
	[mWindowList setDesktop: desktop];
}

#pragma mark -

- (NSString*) name {
	ZEN_RELEASE(mName);

	if ((mPsn.highLongOfPSN == 0) && (mPsn.lowLongOfPSN == 0)) {
		mName = @""; 
		return mName; 
	}
	
	// get the process name
	CFStringRef strProcessName;    
	CopyProcessName(&mPsn, &strProcessName); 
	
	mName = (NSString*)strProcessName; 
	
	return mName; 
}

#pragma mark -
- (NSImage*) icon 
{
  ZEN_RELEASE(mIcon);
    
	if ((mPsn.highLongOfPSN != 0) || (mPsn.lowLongOfPSN != 0))
  {
    // get the application bundle location
    FSRef fsRef;
    GetProcessBundleLocation(&mPsn, &fsRef); 
    
    char string[512];
    FSRefMakePath(&fsRef, (UInt8 *)string, 512);

    // get the icon
    mIcon = [[[NSWorkspace sharedWorkspace] iconForFile: [NSString stringWithCString: string]] retain];
  }
  
  
  // This doesn't seem to work
  if (mIcon == nil)
  {
    mIcon = [[[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericApplicationIcon)] retain];
  }
  
	return mIcon; 
}

#pragma mark -
- (NSString*) bundlePath 
{
	if (mBundlePath != nil)
		return mBundlePath; 
	
	if ((mPsn.highLongOfPSN == 0) && (mPsn.lowLongOfPSN == 0)) 
		return nil; 
	
	// get the application bundle location
	FSRef fsRef;
	GetProcessBundleLocation(&mPsn, &fsRef); 
	
	char string[512];
	FSRefMakePath(&fsRef, (UInt8 *)string, 512);
    
	// get the path
	mBundlePath = [[NSString stringWithCString: string] retain];
	
	return mBundlePath; 
	
}

#pragma mark -

- (BOOL) isValid 
{
	ProcessSerialNumber psn; 
	
	// check if we can retrieve information about the process, and if
	// we cant, we assume that we do not exist any longer 
	OSStatus iReturn = GetProcessForPID(mPid, &psn); 
	
	return (iReturn == noErr); 
}

#pragma mark -
#pragma mark Binding windows 

- (void) bindWindow: (PNWindow*) window 
{
	// check if we already know about this window, and if we do, return 
	if ([mWindows containsObject: window])
		return; 
	
	[self willChangeValueForKey: @"windows"]; 
	
	[mWindows addObject: window];
	// if we are displayed as sticky, we will sticky the new window too
	if (mIsSticky)
		[window setSticky: YES]; 
	
	[self didChangeValueForKey: @"windows"]; 
}

- (void) unbindWindow: (PNWindow*) window 
{
	// check if we know about this window and return if we dont 
	if ([mWindows containsObject: window] == NO)
		return; 
	
	[self willChangeValueForKey: @"windows"]; 
	[mWindows removeObject: window]; 
	[self didChangeValueForKey: @"windows"]; 
}

#pragma mark -
#pragma mark Ordering windows 

/**
 * @todo	Implement 
 *
 */ 
- (void) orderOut {
}

/**
 * @todo	Implement 
 *
 */ 
- (void) orderIn {
}

/**
 * @todo	Implement 
 *
 */ 
- (void) orderAbove: (NSObject<PNDesktopItem>*) item {
}

/**
 * @todo	Implement 
 *
 */ 
- (void) orderBelow: (NSObject<PNDesktopItem>*) item {
}

@end
