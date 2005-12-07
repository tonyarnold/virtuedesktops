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

#import "VTApplicationWrapper.h"
#import "VTDesktopController.h"
#import "VTNotifications.h" 
#import <Peony/Peony.h> 
#import <Zen/Zen.h> 

#define kVtCodingBundle			@"bundle"
#define kVtCodingSticky			@"sticky"
#define kVtCodingHidden			@"hidden"
#define kVtCodingDesktop		@"desktop"
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
		mDesktop		= nil; 
		mImage			= nil;
		mBundle			= nil; 
		mSticky			= NO; 
		mBindDesktop	= NO; 
				
		// and register our interest in desktop collection changes 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWillRemove:) name: VTDesktopWillRemoveNotification object: nil]; 
		
		return self; 
	}
	
	return nil; 
}

- (id) initWithBundlePath: (NSString*) bundlePath {
	if (self = [self init]) {
		if (bundlePath == nil) {
			NSLog(@"Invalid bundlePath"); 
			[self autorelease]; 
		
			return nil; 
		}
		
		ZEN_ASSIGN(mBundle, bundlePath);
		
		// and complete initialization by filling the application array 
		[self createApplications];
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mBundle); 
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
	[dictionary setObject: mBundle forKey: kVtCodingBundle]; 
	[dictionary setObject: [NSNumber numberWithBool: mSticky] forKey: kVtCodingSticky];
	[dictionary setObject: [NSNumber numberWithBool: mHidden] forKey: kVtCodingHidden]; 
	[dictionary setObject: [NSNumber numberWithBool: mBindDesktop] forKey: kVtCodingDesktopEnabled]; 
	if (mDesktop)
		[dictionary setObject: [mDesktop uuid] forKey: kVtCodingDesktop]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	// decode primitives 
	mBundle			= [[dictionary objectForKey: kVtCodingBundle] retain]; 
	mSticky			= [[dictionary objectForKey: kVtCodingSticky] boolValue]; 
	mHidden			= [[dictionary objectForKey: kVtCodingHidden] boolValue]; 
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

- (void) setSticky: (BOOL) flag {
	if (mSticky == flag)
		return; 
	
	mSticky = flag; 
	
	// if we are running, tell all application objects to sticky 
	NSEnumerator*		applicationIter	= [mApplications objectEnumerator]; 
	PNApplication*	application			= nil; 
	VTDesktop*			activeDesktop		= [[VTDesktopController sharedInstance] activeDesktop]; 
	
	while (application = [applicationIter nextObject]) {
		// Workaround.. Pull the application to the current desktop before 
		// stickying it so the windows will not get lost 
		if (flag)
			[application setDesktop: activeDesktop]; 
		
		[application setSticky: flag]; 
	}
	
	if ((mSticky == NO) && (mBindDesktop == YES) && (mDesktop != nil) && (mDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
		// and move all of our windows to the bound desktop 
		[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop]; 	
	}
}

- (BOOL) isSticky {
	return mSticky; 
}

- (void) setHidden: (BOOL) flag {
	if (mHidden == flag)
		return; 
	
	mHidden = flag; 
	
	// if we are running, tell all application objects to sticky 
	NSEnumerator*	applicationIter	= [mApplications objectEnumerator]; 
	PNApplication*	application		= nil; 
	
	while (application = [applicationIter nextObject]) {
		[application setHidden: flag]; 
	}	
}

- (BOOL) isHidden {
	return mHidden; 
}

#pragma mark -
- (void) setBindingToDesktop: (BOOL) flag {
	mBindDesktop = flag;
	
	if ((mBindDesktop == NO) || (mSticky == YES))
		return; 
	
	// and move all of our windows there 
	[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop]; 	
	
}

- (BOOL) isBindingToDesktop {
	return mBindDesktop; 
}

- (void) setBoundDesktop: (VTDesktop*) desktop {
	ZEN_ASSIGN(mDesktop, desktop);
	
	if ((mBindDesktop == NO) || (mDesktop == nil) || (mSticky == YES))
		return; 

	// and move all of our windows there 
	[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop]; 
}

- (VTDesktop*) boundDesktop {
	return mDesktop; 
}

- (NSImage*) icon {
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
		PNWindow*		window		= nil; 
		
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

- (BOOL) isRunning {
	return (mPid != 0); 
}

- (NSString*) bundlePath {
	return mBundle; 
}

#pragma mark -
#pragma mark Notifications 
- (void) onApplicationAttached: (NSNotification*) notification {
	NSDictionary*		userInfo		= [notification userInfo]; 
	PNApplication*	application	= [userInfo objectForKey: PNApplicationInstanceParam]; 
	
	// check validity of this application 
	if (([application name] == nil) || [[application name] isEqualToString: @""]) 
		return; 
	if (([application icon] == nil) || ([application bundlePath] == nil)) 
		return; 
	
	// check if we already know about this instance 
	if ([mApplications indexOfObjectIdenticalTo: application] != NSNotFound) {
		return; 
	}
	
	// if this is the first object added, fetch information we need 
	if (mPid == 0) {
		[self willChangeValueForKey: @"running"]; 
		
		mPid	= [application pid]; 
		ZEN_ASSIGN(mImage, ([application icon])); 
		ZEN_ASSIGN_COPY(mTitle, ([application name])); 
				
		[self didChangeValueForKey: @"running"]; 
	}
	
	// now apply attributes 
	[application setSticky: mSticky]; 
	[application setHidden: mHidden];
	
	// check if we should move this application to another desktop 
	if ((mSticky == NO) && (mBindDesktop == YES) && (mDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
		[application setDesktop: mDesktop];
	}
	
	// and add 
	[mApplications addObject: application]; 
	// plus we are now officially interested in changes of the windows of this 
	// application 
	[application addObserver: self forKeyPath: @"windows" options: NSKeyValueObservingOptionNew context: NULL]; 
}

- (void) onApplicationDetached: (NSNotification*) notification {
	NSDictionary*	userInfo	= [notification userInfo]; 
	PNApplication*	application	= [userInfo objectForKey: PNApplicationInstanceParam]; 
	
	unsigned int index = [mApplications indexOfObjectIdenticalTo: application]; 
	
	// check if we already know about this instance 
	if (index == NSNotFound) {
		return; 
	}
	
	// remove observer status 
	[application removeObserver: self forKeyPath: @"windows"]; 
	// remove it from our list 
	[mApplications removeObjectAtIndex: index]; 
	
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
		
		// iterate all windows and move them if necessary 
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

- (void) createApplications {
	// clean array 
	[mApplications removeAllObjects]; 
	
	// walk the desktops to find us an application matching our bundle 
	NSEnumerator*	desktopIter	= [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		// walk all applications to find our bundle string 
		NSEnumerator*	applicationIter	= [[desktop applications] objectEnumerator]; 
		PNApplication*	application		= nil; 
		
		while (application = [applicationIter nextObject]) {
			if ([application bundlePath] && [[application bundlePath] isEqualToString: mBundle]) {
				[mApplications addObject: application]; 
				
				// now apply attributes 
				[application setSticky: mSticky]; 
				[application setHidden: mHidden]; 
				
				// plus we are now officially interested in changes of the windows of this 
				// application 
				[application addObserver: self forKeyPath: @"windows" options: NSKeyValueObservingOptionNew context: NULL]; 
				
				// and skip to next desktop, as we expect only one application
				// for a bundle per desktop 
				break; 
			}
		}
	}
	
	if ([mApplications count] > 0) {
		PNApplication* application = [[mApplications objectAtIndex: 0] retain]; 
		if (application == nil)
			return; 
		
		mPid = [application pid]; 
		
		ZEN_ASSIGN_COPY(mTitle, [application name]); 
		ZEN_ASSIGN(mImage, [application icon]);
		
		[application release]; 
		
		// check if we should move this application to another desktop 
		if ((mSticky == NO) && (mBindDesktop == YES) && (mDesktop != nil) && (mDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
			[mApplications makeObjectsPerformSelector: @selector(setDesktop:) withObject: mDesktop]; 	
		}
		
		return; 
	}
	
	// if the application is not running, we fetch the information from the
	// bundle itself 
	mPid = 0; 

	NSBundle* bundle		= [NSBundle bundleWithPath: mBundle]; 
	NSString* imageFile = [bundle objectForInfoDictionaryKey: @"CFBundleIconFile"];
	NSString* imagePath	= [bundle pathForResource: [imageFile stringByDeletingPathExtension] ofType: [imageFile pathExtension]];
	
	mImage	= [[NSImage alloc] initByReferencingFile: imagePath];
	mTitle	= [[bundle objectForInfoDictionaryKey: @"CFBundleName"] retain]; 
}

@end 

