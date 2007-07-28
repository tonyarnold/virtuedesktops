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

#import "VTTriggerDesktopNotification.h"
#import "VTNotifications.h" 
#import "VTDesktopController.h" 
#import <Zen/Zen.h> 

#define kVtCodingDesktop	@"desktop"

@implementation VTTriggerDesktopNotification

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super initWithName: VTRequestChangeDesktopName]) {
		mNotificationFormat = nil; 
		mDescriptionFormat  = nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	if ([mUserInfo objectForKey: VTRequestChangeDesktopParamName]) {
		VTDesktop* desktop = [mUserInfo objectForKey: VTRequestChangeDesktopParamName]; 
		
		[desktop removeObserver: self forKeyPath: @"name"]; 
	}
	
	ZEN_RELEASE(mNotificationFormat); 
	ZEN_RELEASE(mDescriptionFormat); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 
- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	[dictionary setObject: [[mUserInfo objectForKey: VTRequestChangeDesktopParamName] uuid] forKey: kVtCodingDesktop]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) {
		NSString* uuid = [dictionary objectForKey: kVtCodingDesktop]; 
		if (uuid == nil || [uuid isEqualToString: @""]) {
			// no desktop assigned, return right now killing ourselves by returning
			// nil
			[self autorelease]; 
			return nil; 
		}
		
		// we now have to find the desktop with the correct identifier 
		NSEnumerator*	desktopIter = [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
		VTDesktop*		desktop		= nil; 
		
		while (desktop = [desktopIter nextObject]) {
			if ([[desktop uuid] isEqualToString: uuid]) {
				[self setDesktop: desktop];
				// we found a desktop, so we still exist, and can return 
				return self; 
			}
		}
		
		// fall through... 
		// we can only come this far, if we did not find a desktop with the 
		// uuid we got persisted, so we have to assume, the desktop is no longer
		// existing.. thus we remove ourselves... 
	}
	
	[self autorelease]; 
	return nil; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop {
	// unregister if necessary 
	if ([mUserInfo objectForKey: VTRequestChangeDesktopParamName]) {
		VTDesktop* oldDesktop = [mUserInfo objectForKey: VTRequestChangeDesktopParamName]; 
		[oldDesktop removeObserver: self forKeyPath: @"name"]; 
	}
	
	// add it to our user info dictionary 
	[mUserInfo setObject: desktop forKey: VTRequestChangeDesktopParamName]; 
	
	// and bind our description to the desktop name 
	if (desktop) {
		[desktop addObserver: self 
				  forKeyPath: @"name"
					 options: NSKeyValueObservingOptionNew
					 context: NULL]; 
	}
}

- (VTDesktop*) desktop {
	return [mUserInfo objectForKey: VTRequestChangeDesktopParamName]; 
}

#pragma mark -
- (void) setDescription: (NSString*) description {
	ZEN_ASSIGN_COPY(mDescriptionFormat, description); 
	
	[super setDescription: [NSString stringWithFormat: description, [[self desktop] name]]]; 
}

- (void) setNotification: (NSString*) notification {
	ZEN_ASSIGN_COPY(mNotificationFormat, notification); 
	
	[super setNotification: [NSString stringWithFormat: notification, [[self desktop] name]]]; 
}

#pragma mark -
#pragma mark KVO Sink 

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context {
	if ([keyPath isEqualToString: @"name"]) {
		if (mDescriptionFormat)
			[self setDescription: mDescriptionFormat]; 
		if (mNotificationFormat)
			[self setNotification: mNotificationFormat]; 
	}
}

@end
