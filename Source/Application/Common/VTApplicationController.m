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
/*!
    @class       VTApplicationController
    @abstract    Maintains and provides information about the current list of applications under the running user account
*/

#import "VTApplicationController.h"
#import "VTDesktopController.h" 
#import "VTNotifications.h"
#include <Carbon/Carbon.h>
#import <Zen/Zen.h>

#define kVtCodingApplications	@"applications"

@interface VTApplicationController (KVO)

- (void) insertObjectInApplications: (VTApplicationWrapper*) wrapper atIndex: (unsigned int) index; 
- (void) removeObjectFromApplicationsAtIndex: (unsigned int) index; 
	
@end 

#pragma mark -
@interface VTApplicationController (Content) 

- (void) createApplications; 

@end 

#pragma mark -
@implementation VTApplicationController

+ (VTApplicationController*) sharedInstance {
	static VTApplicationController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil) {
		ms_INSTANCE = [[VTApplicationController alloc] init]; 
	}
	
	return ms_INSTANCE; 
}

- (id) init {
	if (self = [super init]) {
		mApplications = [[NSMutableDictionary alloc] init];
		
		// and register for notifications about added and removed applications 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onApplicationAttached:) name: PNApplicationWasAdded object: nil]; 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onApplicationDetached:) name: PNApplicationWasRemoved object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onApplicationOptionsChanged:) name: kVtNotificationApplicationWrapperOptionsChanged object: nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(onApplicationLaunched:) name: NSWorkspaceDidLaunchApplicationNotification object: nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(onApplicationTerminated:) name: NSWorkspaceDidTerminateApplicationNotification object: nil];
    
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mApplications);
  [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc]; 
}

- (void) scanApplications {
	[self createApplications]; 
}

#pragma mark -
#pragma mark Coding 

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	NSMutableArray*			applicationList	= [NSMutableArray array]; 
	NSEnumerator*			applicationIter = [mApplications objectEnumerator]; 
	VTApplicationWrapper*	application		= nil; 
	
	while (application = [applicationIter nextObject]) {
		// decide if we want to code this application 
		if (([application isSticky] == NO) && ([application isHidden] == NO) && ([application isUnfocused] == NO) && ([application boundDesktop] == nil))
			continue; 
		
		NSMutableDictionary* applicationDict = [[NSMutableDictionary alloc] init]; 
		// encode application 
		[application encodeToDictionary: applicationDict]; 
		// and add for later setting 
		[applicationList addObject: applicationDict]; 
		[applicationDict release]; 
	}
	
	[dictionary setObject: applicationList forKey: kVtCodingApplications]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	NSArray* applications = [dictionary objectForKey: kVtCodingApplications]; 
	if (applications == nil)
		return self; 
	
	NSEnumerator*	applicationIter	= [applications objectEnumerator]; 
	NSDictionary*	applicationDict = nil; 
	
	while (applicationDict = [applicationIter nextObject]) {
		// create new application wrapper and decode 
		VTApplicationWrapper* newWrapper = [[VTApplicationWrapper alloc] init]; 
		newWrapper = [newWrapper decodeFromDictionary: applicationDict]; 
		
		if (newWrapper == nil)
			break; 
        
        if ([[NSFileManager defaultManager] fileExistsAtPath: [newWrapper bundlePath]] == NO)
        {  
            break;
        }
		
		// and add it 
		[self attachApplication: newWrapper]; 
		[newWrapper release]; 
	}
    return self;
}

#pragma mark -
#pragma mark Attributes 

- (NSArray*) applications {
	return [mApplications allValues]; 
}

- (VTApplicationWrapper*) applicationForPath: (NSString*) path
{
    return [mApplications objectForKey: path];
}

- (VTApplicationWrapper*) applicationForPSN: (ProcessSerialNumber *) psn
{
	OSStatus status;
	pid_t    pid;
	status = GetProcessPID(psn, &pid);
	if (status) {
		return nil;
	}
	return [self applicationForPid:pid];
}

- (VTApplicationWrapper*) applicationForPid: (pid_t) pid
{
    NSEnumerator *enumerator = [mApplications objectEnumerator];
    VTApplicationWrapper *wrapper = nil;
    while (wrapper = [enumerator nextObject]) {
        if ([wrapper processIdentifier] == pid) {
            return wrapper;
        }
    }
    return nil;
}

- (VTApplicationWrapper*) application: (PNApplication*) app {
    return [self applicationForPid: [app pid]];
}

#pragma mark -
- (void) attachApplication: (VTApplicationWrapper*) wrapper {
	[self willChangeValueForKey: @"applications"];
    if (![wrapper isMe]) {
        [mApplications setObject: wrapper forKey: [wrapper bundlePath]];
    }
	[self didChangeValueForKey: @"applications"]; 	
}

- (void) detachApplication: (VTApplicationWrapper*) wrapper {
	[self willChangeValueForKey: @"applications"]; 	
	[mApplications removeObjectForKey: [wrapper bundlePath]]; 
	[self didChangeValueForKey: @"applications"]; 
}

#pragma mark -
#pragma mark Notification sink 
- (void) onApplicationAttached: (NSNotification*) notification {
	NSString* bundlePath = [notification object]; 
  	
	// return nil Ids 
	if (bundlePath == nil)
		return;
  
  // if we know about this application already, delegate to the wrapper 
	VTApplicationWrapper* wrapper = [mApplications objectForKey: bundlePath]; 
	
	if (wrapper != nil) {
		[wrapper onApplicationAttached: notification]; 
		return; 
	}
  
  [self onApplicationAttachedLocal: bundlePath];
}

- (void) onApplicationAttachedLocal: (NSString *) bundlePath
{
  // return nil Ids 
	if (bundlePath == nil)
		return; 
  
  // if we know about this application already, delegate to the wrapper 
	VTApplicationWrapper* wrapper = [mApplications objectForKey: bundlePath]; 
	
	if (wrapper != nil)
		return; 
	
	// otherwise create a new wrapper 
	wrapper = [[[VTApplicationWrapper alloc] initWithPath: bundlePath] autorelease];
	if (wrapper == nil) 
		return; 
	
	[self attachApplication: wrapper]; 
}

- (void) onApplicationDetached: (NSNotification*) notification {
	NSString* bundlePath = [notification object]; 
  if (bundlePath == nil) 
		return;
  
  // if we know about this application, let it know of the notification 
	VTApplicationWrapper* wrapper = [mApplications objectForKey: bundlePath]; 
	if (wrapper == nil)
		return; 
	
	[wrapper onApplicationDetached: notification]; 
  [self onApplicationDetachedLocal: bundlePath];
}

- (void) onApplicationDetachedLocal: (NSString *) bundlePath
{  
	// ignore nil paths 
	if (bundlePath == nil) 
		return; 
	
	// if we know about this application, let it know of the notification 
	VTApplicationWrapper* wrapper = [mApplications objectForKey: bundlePath]; 
	if (wrapper == nil)
		return; 
	
	// now check if the application is still running, or has customized settings and just return if it is
	if ([wrapper isRunning] || [wrapper hasCustomizedSettings])
		return;
  
	// if the application died, we will potentially remove it from our list 
	// TODO: Consider user added flag 
	[self detachApplication: wrapper];
}

- (void) onApplicationLaunched: (NSNotification*) notification
{
  [self onApplicationAttachedLocal: [[notification userInfo] objectForKey: @"NSApplicationPath"]];
}

- (void) onApplicationTerminated: (NSNotification*) notification
{
    [self onApplicationDetachedLocal: [[notification userInfo] objectForKey: @"NSApplicationPath"]];
}

- (void) onApplicationOptionsChanged: (NSNotification*) notification
{
  VTApplicationWrapper *applicationWrapper = [[notification object] retain];
  if ([applicationWrapper isRunning] == NO)
    [self onApplicationDetachedLocal: [applicationWrapper bundlePath]];

  [applicationWrapper release];
}

- (BOOL)appRunningWithBundleIdentifier:(NSString *)bundleIdentifier
{
  BOOL result = NO;
  
  NSArray       *allApps = [[NSWorkspace sharedWorkspace] launchedApplications];
  NSEnumerator  *enumerator = [allApps objectEnumerator];
  NSDictionary  *app;
  while (app = [enumerator nextObject]) {
    if ([[app objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString: bundleIdentifier])
    {
      result = YES;
      break;
    }    
  }
  return result;
}

@end

#pragma mark -
@implementation VTApplicationController (Content) 

/*!
    @method     createApplications
    @abstract   Gathers applications and adds them to the current controller
    @discussion This method walks through our list of desktops, asking them for known application instances (those with attached windows), and adding them to the list of applications that this controller knows about. Once it has this list, it appends any running applications that the desktops were unaware of (this occurs when an application is an LSUIElement or has no recognised window instances).
*/

- (void) createApplications {
	NSEnumerator*	desktopIter	= [[[VTDesktopController sharedInstance] desktops] objectEnumerator];
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		NSEnumerator*	applicationIter	= [[desktop applications] objectEnumerator]; 
		PNApplication*	application		= nil; 
		
		while (application = [applicationIter nextObject]) {
      NSString *applicationReferencePath = [NSString stringWithString: [application path]];
      
			if (applicationReferencePath != nil && [mApplications objectForKey: applicationReferencePath] == nil)
      {
        [self onApplicationAttachedLocal: applicationReferencePath];
      } 
		}
	}
  
  NSArray *launchedApplications = [[[NSWorkspace sharedWorkspace] launchedApplications] retain];
  NSEnumerator *applicationEnum = [[launchedApplications objectEnumerator] retain];
  NSDictionary *applicationReference;
  
  while (applicationReference = [applicationEnum nextObject])
  {
    NSString *applicationReferencePath = [NSString stringWithString: [applicationReference objectForKey: @"NSApplicationPath"]];
    if (applicationReferencePath != nil && [mApplications objectForKey: applicationReferencePath] == nil)
    {
      [self onApplicationAttachedLocal: applicationReferencePath];
    }
  }
  
  [launchedApplications release];
  [applicationEnum release]; 
}

@end 
