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
#import <Peony/Peony.h> 
#import "VTCoding.h" 
#import "VTApplicationWrapper.h" 

@interface VTApplicationController : NSObject<VTCoding> {
	NSMutableDictionary *mApplications; 
}

+ (VTApplicationController *) sharedInstance; 
- (void) scanApplications; 

- (NSArray *) applications; 
- (VTApplicationWrapper *) applicationForPath: (NSString *) path;
- (VTApplicationWrapper *) applicationForPSN: (ProcessSerialNumber*) psn;
- (VTApplicationWrapper *) applicationForPid: (pid_t) pid;
- (VTApplicationWrapper *) application: (PNApplication*) app;

- (void) attachApplication: (VTApplicationWrapper *) wrapper; 
- (void) detachApplication: (VTApplicationWrapper *) wrapper; 

- (BOOL)appRunningWithBundleIdentifier: (NSString *)bundleIdentifier;


- (void) onApplicationAttachedLocal: (NSString *) bundlePath;
- (void) onApplicationDetachedLocal: (NSString *) bundlePath;

@end
