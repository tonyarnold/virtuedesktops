/*
	PNApplication.m
	See COPYING for licensing details
	Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>\n
	Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
 */

#import "PNApplication.h"
#import "PNWindowList.h"
#import "PNNotifications.h"
#import <Zen/Zen.h>
#import <Carbon/Carbon.h>

/**
  @class PNApplication
  @brief Class for creating and managing "virtual desktops" by utilising Apple's workspace objects

  This class does a lot of the management of creating, modifying and maintaining virtual desktops using Apple's workspace objects. It does not define a "layout" for the desktops - as far as the class is concerned, the desktops have an order, but no physical representation.\n
  This interface is not really representing a whole application but acts as a window group grouping windows belonging to one application seen on a specific desktop. It is possible to have multiple applications with the same pid on different desktops at the same time.
 */

@implementation PNApplication

#pragma mark -
#pragma mark Lifetime
- (id) initWithPid: (pid_t) pid onDesktop: (PNDesktop*) desktop 
{
	if (self = [super init])
    {
		mPid        = pid;
		mDesktop    = [desktop retain]; 
		mWindows    = [[NSMutableArray alloc] init]; 
        
        _name       = nil;
		
		mIsSticky	= NO; 
		mIsHidden	= NO;
        mIsUnfocused = NO;
        
		if (mPid == 0)
        {
			// oops, no can do with this pid 
			[self autorelease]; 
			return nil; 
		} else if ([self isMe]) {
            mIsSticky = YES;
        }
		
		// Create psn out of the pid
		OSStatus oResult = GetProcessForPID(mPid, &mPsn); 
		if (!oResult) {
			return self;
		} else {
			[self autorelease]; 
			return nil;
		}
	}
	
	return nil; 
}

- (void) dealloc
{
	// attributes 
	[mWindows release];
	[mDesktop release]; 
	
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
- (void) setIsHidden: (BOOL) isHidden
{
  if (mIsHidden == isHidden)
    return;
  
	mIsHidden = isHidden; 
}

- (BOOL) isHidden
{
	return mIsHidden; 
}


#pragma mark -
- (void) setSticky: (BOOL) stickyState
{  
	NSEnumerator*   windowIterator			= [[self windows] objectEnumerator];
	PNWindow*       window					= nil;
	
    // Overload stickyState to be sure the current application is stiky
    if ([self isMe]) {
        stickyState = YES;
    }
    
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
- (void) setIsUnfocused: (BOOL) unfocused
{
  if (mIsUnfocused == unfocused)
    return;
  
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
	// currently we return 1.0 here, as there is no meaningful value to return for a collection of windows... 
	return 1.0f; 
}

#pragma mark -

- (PNDesktop*) desktop {
	return mDesktop; 
}

- (int) desktopId {
	return [mDesktop identifier]; 
}

- (void) setDesktop: (PNDesktop*) desktop {
	// We will not modify the desktop we belong to but will just move all the windows we know about to the passed desktop, a new application instance will be created there...
	NSMutableArray* windowsForSwitching = [[NSMutableArray alloc] init];
	NSEnumerator*   windowIter			= [mWindows objectEnumerator];
	PNWindow*       window				= nil;
  
	while (window = [windowIter nextObject]) {
		if (![window isSticky])
			[windowsForSwitching addObject: window];
	}
  
	PNWindowList* mWindowList = [[PNWindowList alloc] initWithArray: windowsForSwitching];
	[mWindowList setDesktop: desktop];
	if (mDesktop != desktop) {
		ZEN_RELEASE(mDesktop);
		ZEN_ASSIGN(mDesktop, desktop);
	}
	[mWindowList release];
  
	if (windowsForSwitching)
		[windowsForSwitching release];
}

#pragma mark -

- (NSString*) name 
{  
  char          buffer[1024];
  CFStringRef		pName;
  
  if( !_name )
  {
    if( !_name && (CopyProcessName( &mPsn, &pName) == noErr) )    // with thanks to Dylan Ashe
    {
      CFStringGetCString(pName, buffer, 256, CFStringConvertNSStringEncodingToEncoding([NSString defaultCStringEncoding]));
      
      _name = [NSString stringWithCString:buffer];
      [_name retain];
      
      CFRelease(pName);
    }
    // CFBundleName code demoted to alternate method because it was causing plist processing issues in Jaguar, yet CopyProcessName doesn't work for everything, e.g. Help Viewer - njr
    else if( [self path] )
    {
      NSBundle *b = [NSBundle bundleWithPath: [self path]];
      if( b )
      {
        _name = [b localizedStringForKey:@"CFBundleName" value:@"_AsM_nO_nAmE_" table:@"InfoPlist"];
        
        if( [_name isEqualToString:@"_AsM_nO_nAmE_"] )
          _name = [[b infoDictionary] objectForKey:@"CFBundleName"];
        
        if( _name )
          [_name retain];
      }
    }
    
  }
  
  return _name ? _name : NSLocalizedString(@"<<unknown application>>", "Name used when application name cannot be determined");
}

#pragma mark -

- (NSString*) path 
{	
	if ((mPsn.highLongOfPSN == 0) && (mPsn.lowLongOfPSN == 0)) 
		return nil; 
	
	// get the application bundle location
	FSRef fsRef;
	GetProcessBundleLocation(&mPsn, &fsRef); 
	
	char string[512];
	FSRefMakePath(&fsRef, (UInt8 *)string, 512);
  	
	return [NSString stringWithCString: string];
}

- (NSString*) bundleId
{   
  return [[NSBundle bundleWithPath: [self path]] bundleIdentifier];
}

#pragma mark -
- (NSImage*) icon 
{    
	return [[NSWorkspace sharedWorkspace] iconForFile: [self path]]; 
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

- (BOOL) isFrontmost
{
  ProcessSerialNumber psn;
  Boolean applicationIsFrontmost = NO;
  
  OSStatus iReturn = GetFrontProcess(&psn);
  
  if (iReturn == noErr)
  {
    iReturn = SameProcess(&psn, &mPsn, &applicationIsFrontmost); 
  }
  
  return (BOOL) applicationIsFrontmost;
}

- (BOOL) isMe
{
    return mPid == [[NSProcessInfo processInfo] processIdentifier];
}

#pragma mark -
#pragma mark Activation

- (BOOL) activate
{
    if ([self isFrontmost]) {
        return TRUE;
    }
    OSErr result = SetFrontProcess(&mPsn);
    return (result == 0);
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