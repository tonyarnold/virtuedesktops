/*
 * 
 * VirtueDesktops 
 *
 * A desktop extension for MacOS X
 *
 * Copyright 2004, Thomas Staller playback@users.sourceforge.net
 * Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
 *
 * See COPYING for licensing details
 * 
 */ 

#import "VTTrigger.h"
#import "VTTriggerNotification.h"
#import <Zen/Zen.h> 

@implementation VTTrigger

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		// ivars 
		mStringValue	= nil; 
		mRegistered		= NO; 
		mNotification	= nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mStringValue); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 
- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	return self; 
}

#pragma mark -
#pragma mark Attributes 
- (NSString*) stringValue {
	return @""; 
}

#pragma mark -
- (BOOL) isRegistered {
	return mRegistered; 
}

- (BOOL) canRegister {
	return NO; 
}

#pragma mark -
- (VTTriggerNotification*) notification {
	return mNotification; 
}

- (void) setNotification: (VTTriggerNotification*) notification {
	ZEN_ASSIGN(mNotification, notification); 
}

#pragma mark -
#pragma mark Operations 
- (void) registerTrigger {
	// Implemented by subclasses 
}

- (void) unregisterTrigger {
	// Implemented by subclasses 
}

- (id)copyWithZone:(NSZone *)zone {
	id triggerCopy = NSCopyObject(self, 0, zone);
	return triggerCopy;
}

@end
