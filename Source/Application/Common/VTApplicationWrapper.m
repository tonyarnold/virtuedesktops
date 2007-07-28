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

#import "VTApplicationWrapper.h"
#import "VTDesktopController.h"
#import "VTNotifications.h" 
#import <Peony/Peony.h> 
#import <Zen/Zen.h> 

#define kVtCodingBundlePath     @"path"
#define kVtCodingBundleId       @"id"
#define kVtCodingBundleTitle    @"title"
#define kVtCodingSticky         @"sticky"
#define kVtCodingHidden         @"hidden"
#define kVtCodingUnfocused      @"unfocused"
#define kVtCodingDesktop        @"desktop"
#define kVtCodingDesktopEnabled	@"desktopEnabled"

@interface VTApplicationWrapper (Binding) 
- (void) createApplications; 
@end 

#pragma mark -
@implementation VTApplicationWrapper

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		mApplications	= [[NSMutableArray alloc] init]; 
		mDesktop      = nil; 
		mImage        = nil;
		mSticky       = NO; 
		mBindDesktop	= NO;
		mUnfocused		= NO;
		mBundlePath   = nil;
		
		// and register our interest in desktop collection changes 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWillRemove:) name: VTDesktopWillRemoveNotification object: nil]; 
		
		return self; 
	}
	
	return nil; 
}

- (id) initWithBundleId: (NSString*) bundleId {
	if (self = [self init]) {
		if (bundleId == nil) {
			[self autorelease]; 
			return nil; 
		}
		
		ZEN_ASSIGN(mBundleId, bundleId);    
		ZEN_ASSIGN(mBundlePath, [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier: mBundleId]);
		
		// and complete initialization by filling the application array 
		[self createApplications];
		
		return self; 
	}
	
	return nil; 
}

- (id) initWithPath: (NSString*) path {
	if (self = [self init]) {
		if (path == nil) {
			[self autorelease]; 
			return nil; 
		}
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		{
      // We have an application path, so assign and continue
			ZEN_ASSIGN(mBundlePath, path);
		}
		else
		{
			ZEN_ASSIGN(mBundlePath, [[NSWorkspace sharedWorkspace] fullPathForApplication: [path lastPathComponent]]);
			if (mBundlePath == nil)
			{
				[self autorelease];
				return nil;
			}
		}
		
		ZEN_ASSIGN_COPY(mBundleId, [[NSBundle bundleWithPath: path] objectForInfoDictionaryKey: @"CFBundleIdentifier"]);
		
		// and complete initialization by filling the application array 
		[self createApplications];
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mBundleId);
	ZEN_RELEASE(mBundlePath);
	ZEN_RELEASE(mApplications);
	ZEN_RELEASE(mImage);
	ZEN_RELEASE(mTitle);
	ZEN_RELEASE(mDesktop);
	
	// give up observer status 
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[dictionary setObject: mBundlePath forKey: kVtCodingBundlePath];
	
	[dictionary setObject: [NSNumber numberWithBool: mSticky] forKey: kVtCodingSticky];
	[dictionary setObject: [NSNumber numberWithBool: mHidden] forKey: kVtCodingHidden];
	[dictionary setObject: [NSNumber numberWithBool: mUnfocused] forKey: kVtCodingUnfocused];
	[dictionary setObject: [NSNumber numberWithBool: mBindDesktop] forKey: kVtCodingDesktopEnabled];
	
	if (mBundleId)
		[dictionary setObject: mBundleId forKey: kVtCodingBundleId];
	
	if (mTitle)
		[dictionary setObject: mTitle forKey: kVtCodingBundleTitle];
	
	if (mDesktop)
		[dictionary setObject: [mDesktop uuid] forKey: kVtCodingDesktop]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	// We use the path as the UID, so ensure precendence
	mBundlePath   = [[dictionary objectForKey: kVtCodingBundlePath] retain];
	
	// decode primitives 
	mBundleId     = [[dictionary objectForKey: kVtCodingBundleId] retain];
	mTitle        = [[dictionary objectForKey: kVtCodingBundleTitle] retain];
	mSticky       = [[dictionary objectForKey: kVtCodingSticky] boolValue]; 
	mHidden       = [[dictionary objectForKey: kVtCodingHidden] boolValue]; 
	mUnfocused		= [[dictionary objectForKey: kVtCodingUnfocused] boolValue];
	mBindDesktop	= [[dictionary objectForKey: kVtCodingDesktopEnabled] boolValue];
		
	// try to read the desktop
	NSString* desktopUUID = [dictionary objectForKey: kVtCodingDesktop];
	
	// get the desktop, this may be nil, which is ok
	if (desktopUUID)
		ZEN_ASSIGN(mDesktop, [[VTDesktopController sharedInstance] desktopWithUUID: desktopUUID]); 
	
	// and initialize applications 
	[self createApplications];
	
	return self; 
}

#pragma mark -
#pragma mark Attributes 

- (void) setSticky: (BOOL) flag 
{
	if (mSticky == flag)
		return; 
	
	mSticky = flag; 
	
	// if we are running, tell all application objects to sticky 
	NSEnumerator*		applicationIter 	= [mApplications objectEnumerator]; 
	PNApplication*	    application			= nil; 
	VTDesktop*			activeDesktop		= [[VTDesktopController sharedInstance] activeDesktop]; 
	
	while (application = [applicationIter nextObject]) {
		// Workaround.. Pull the application to the current desktop before 
		// stickying it so the windows will not get lost 
		if (flag)
			[application setDesktop: activeDesktop]; 
		
		[application setSticky: flag]; 
	}
	
	if ((mSticky == NO) && (mUnfocused == NO) && (mBindDesktop == YES) && (mDesktop != nil) && (mDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
		// and move all of our windows to the bound desktop 
		[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop]; 	
	}
	
	if (mLaunching = NO)
		[[NSNotificationCenter defaultCenter] postNotificationName: kVtNotificationApplicationWrapperOptionsChanged object: self];
}

- (BOOL) isSticky {
	return mSticky; 
}

- (void) setIsHidden: (BOOL) flag {
	if (mHidden == flag)
		return; 
	
	mHidden = flag; 
	
	// if we are running, tell all application objects to sticky 
	NSEnumerator*	applicationIter	= [mApplications objectEnumerator]; 
	PNApplication*	application		= nil; 
	
	while (application = [applicationIter nextObject]) {
		[application setIsHidden: flag]; 
	}	
	
	if (mLaunching = NO)
		[[NSNotificationCenter defaultCenter] postNotificationName: kVtNotificationApplicationWrapperOptionsChanged object: self];
}

- (BOOL) isHidden {
	return mHidden; 
}

#pragma mark -
- (void) setIsUnfocused: (BOOL) flag {
	if (mUnfocused == flag)
		return;
	
	mUnfocused = flag;
	
	// if we are running, tell all application objects to sticky 
	NSEnumerator*	applicationIter	= [mApplications objectEnumerator]; 
	PNApplication*	application		= nil; 
	
	while (application = [applicationIter nextObject]) {
		[application setIsUnfocused: flag]; 
	}
	
	if (mLaunching = NO)
		[[NSNotificationCenter defaultCenter] postNotificationName: kVtNotificationApplicationWrapperOptionsChanged object: self];
}

- (BOOL) isUnfocused {
	return mUnfocused;
}

#pragma mark -
- (void) setBindingToDesktop: (BOOL) flag {
	mBindDesktop = flag;
	
	if ((mBindDesktop == NO) || (mUnfocused == YES) || (mSticky == YES))
		return; 
	
	ZEN_ASSIGN(mDesktop, [[VTDesktopController sharedInstance] activeDesktop]);
	// and move all of our windows there 
	[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop];	
	
	if (mLaunching = NO)
		[[NSNotificationCenter defaultCenter] postNotificationName: kVtNotificationApplicationWrapperOptionsChanged object: self];
}

- (BOOL) isBindingToDesktop {
	return mBindDesktop; 
}

- (void) setBoundDesktop: (VTDesktop*) desktop
{
	if (mDesktop != nil) {
		[mDesktop removeObserver:self forKeyPath:@"windows"];
	}
	ZEN_ASSIGN(mDesktop, desktop);
	if (mDesktop != nil) {
		[mDesktop addObserver:self forKeyPath:@"windows" options:NSKeyValueObservingOptionNew context:nil];
	}
	
	if ((mBindDesktop == NO) || (mDesktop == nil) || (mSticky == YES) || (mUnfocused == YES))
		return; 
	
	// and move all of our windows there 
	[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop];
}

- (VTDesktop*) boundDesktop {
	return mDesktop; 
}

- (NSImage*) icon {
	if ([self canBeRemoved] && mImage != nil)
	{
		NSImage* fadedImage = [[NSImage alloc] initWithSize: [mImage size]];
		[fadedImage lockFocus];
		[mImage setFlipped: YES];
		[mImage dissolveToPoint: NSZeroPoint fraction: 0.4];
		[fadedImage unlockFocus];
		return fadedImage;
	}
	
  // Ensure our image is drawing right side up
	[mImage setFlipped: NO];
	
	return mImage;
}

- (NSArray*) windows {
	// return union of all windows 
	if (mPid == 0)
		return nil; 
	
	if (mSticky) {
		PNApplication* firstInstance = [mApplications objectAtIndex: 0]; 
		if (firstInstance == nil)
			return nil; 
		
		return [firstInstance windows]; 
	}
	
	NSEnumerator*	applicationIter	= [mApplications objectEnumerator]; 
	PNApplication*	application		= nil; 
	NSMutableArray* windows			= [[[NSMutableArray alloc] init] autorelease]; 
	
	while (application = [applicationIter nextObject]) {
		NSEnumerator*	windowIter	= [[[application windows] objectEnumerator] retain]; 
		PNWindow*			window			= nil; 
		
		while (window = [windowIter nextObject]) {
			if ([windows indexOfObjectIdenticalTo: window] == NSNotFound)
				[windows addObject: window]; 
		}
		
		[windowIter release]; 
	}
	
	return windows; 
}

- (NSString*) title {
	return mTitle; 
}

#pragma mark -

- (pid_t) processIdentifier
{   
	NSArray       *allApps = [[NSWorkspace sharedWorkspace] launchedApplications];
	NSEnumerator  *enumerator = [allApps objectEnumerator];
	NSDictionary  *app;
	while (app = [enumerator nextObject]) {
		if ([[app objectForKey:@"NSApplicationPath"] isEqualToString: [self bundlePath]])
		{
			return (pid_t)[[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		}    
	}
	
	return (pid_t)0;
}

- (BOOL) isRunning
{
	return ([self processIdentifier] != 0); 
}

- (BOOL) canBeRemoved
{
	return ([self isRunning] == NO) && ([[self windows] count] == 0);
}

- (BOOL) isMe
{
    return mPid == [[NSProcessInfo processInfo] processIdentifier];
}

#pragma mark -

- (NSString*) bundlePath
{
	return mBundlePath; 
}

- (NSString*) bundleId
{
	return mBundleId; 
}


#pragma mark -

- (BOOL) hasCustomizedSettings
{
	if ([self isSticky] || [self isHidden] || [self isBindingToDesktop] || [self isUnfocused])
		return YES;
	
	return NO;
}


#pragma mark -
#pragma mark Notifications 
- (void) onApplicationAttached: (NSNotification*) notification
{
	NSDictionary*	userInfo	= [notification userInfo]; 
	PNApplication*	application	= [userInfo objectForKey: PNApplicationInstanceParam]; 
	
	// check validity of this application 
	if (([application name] == nil) || [[application name] isEqualToString: @""]) 
		return; 
	if (([application icon] == nil) || ([application path] == nil)) 
		return; 
	
	// check if we already know about this instance 
	if ([mApplications indexOfObjectIdenticalTo: application] != NSNotFound) {
		return; 
	}
	
	// if this is the first object added, fetch information we need 
	if (mPid == 0) {
		[self willChangeValueForKey: @"running"]; 
		
		mPid = [application pid];
		ZEN_ASSIGN(mBundlePath, [application path]);
		ZEN_ASSIGN(mBundleId, [application bundleId]);
		ZEN_ASSIGN(mTitle, [application name]);
		ZEN_ASSIGN(mImage, [application icon]);     
		
		[self didChangeValueForKey: @"running"]; 
	}
	
	// now apply attributes 
	[application setSticky: mSticky]; 
	[application setIsHidden: mHidden];
	[application setIsUnfocused: mUnfocused];
	
	// check if we should move this application to another desktop 
	if ((mSticky == NO) && (mUnfocused == NO) && (mBindDesktop == YES) && (mDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
		// First move the application to the other desktop
		[application setDesktop: mDesktop];
	}
	
	// ...and add 
	[mApplications addObject: application]; 
}

- (void) onApplicationDetached: (NSNotification*) notification {
	NSDictionary*	userInfo	= [notification userInfo]; 
	PNApplication*	application	= [userInfo objectForKey: PNApplicationInstanceParam]; 
	
	unsigned int appIndex = [mApplications indexOfObjectIdenticalTo: application]; 
	
	// check if we already know about this instance 
	if (appIndex == NSNotFound) {
		return; 
	}
	
	// remove it from our list 
	[mApplications removeObjectAtIndex: appIndex]; 
	
	// if there are no more applications in our list, switch to non-running mode 
	if ([mApplications count] == 0) {
		[self willChangeValueForKey: @"running"]; 
		[self willChangeValueForKey: @"windows"]; 
		mPid = 0; 
		[self didChangeValueForKey: @"windows"]; 
		[self didChangeValueForKey: @"running"];
	}
}

- (void) onDesktopWillRemove: (NSNotification*) notification {
	// check if we need this desktop, and if we do, reset ourselves. 
	if ([notification object] != mDesktop)
		return; 
	
	[self willChangeValueForKey: @"boundDesktop"]; 
	[self willChangeValueForKey: @"bindingToDesktop"]; 
	
	ZEN_RELEASE(mDesktop); 
	mBindDesktop = NO; 
	
	[self didChangeValueForKey: @"bindingToDesktop"]; 
	[self didChangeValueForKey: @"boundDesktop"]; 
}

#pragma mark -
#pragma mark KVO sink

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context {
	if ([keyPath isEqualToString: @"windows"]) {
		// note change of our windows path
		[self willChangeValueForKey: @"windows"];
		
		// Iterate all windows and move them if necessary 
		if ((mBindDesktop == YES) && (mDesktop != nil) && (mDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
			[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop];
		}
		
		[self didChangeValueForKey: @"windows"]; 
		
		return; 
	}
}

@end

#pragma mark -
@implementation VTApplicationWrapper (Binding) 

- (void) createApplications 
{
	// Clean array 
	[mApplications removeAllObjects]; 
	
	mLaunching = YES;
	
	// Walk the desktops to find an application matching our bundle 
	NSEnumerator *desktopIter	= [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop    *desktop     = nil;
	
	while (desktop = [desktopIter nextObject]) {
		// walk all applications to find our bundle string 
		NSEnumerator    *applicationIter	= [[desktop applications] objectEnumerator]; 
		PNApplication   *application      = nil; 
		
		while (application = [applicationIter nextObject]) {
			if ([application path] && [[application path] isEqualToString: [self bundlePath]]) {
				[mApplications addObject: application];
				[application setSticky: mSticky];
				[application setIsHidden:mHidden];
				[application setIsUnfocused:mUnfocused];
			}
		}
	}
	
  	if ([mApplications count] > 0) {
		PNApplication *application = [[mApplications objectAtIndex: 0] retain];
		
		if (application == nil) {
			return; 
		}
		
		mPid = [application pid]; 
		
		ZEN_ASSIGN_COPY(mBundlePath, [application path]);
		ZEN_ASSIGN_COPY(mBundleId, [application bundleId]);
		ZEN_ASSIGN_COPY(mTitle, [application name]);
		ZEN_ASSIGN(mImage, [application icon]);
		
		// check if we should move this application to another desktop 
		if ((mSticky == NO) && (mUnfocused == NO) && (mBindDesktop == YES) && (mDesktop != nil) && (mDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
			[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop];
		}
		[application release];
	} else {
		
		// if the application is not running, we fetch the information from the bundle itself (if it exists)
		mPid = 0;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: [self bundlePath]]) 
		{
			NSBundle *bundle = [NSBundle bundleWithPath: [self bundlePath]];
			ZEN_ASSIGN_COPY(mBundleId, [bundle bundleIdentifier]);
			
			// If we can retrieve the application name from inside the bundle (if it is a bundle!), we do, otherwise just use the name of the application package at the path supplied
			if ([bundle objectForInfoDictionaryKey: @"CFBundleName"] != nil)
			{
				ZEN_ASSIGN_COPY(mTitle, [bundle objectForInfoDictionaryKey: @"CFBundleName"]);
			}
			else
			{
				ZEN_ASSIGN_COPY(mTitle, [[self bundlePath] lastPathComponent]);
			}
			
			ZEN_ASSIGN(mImage, [[NSWorkspace sharedWorkspace] iconForFile: [self bundlePath]]);
		}
		mLaunching = NO;
	}
}

@end 

