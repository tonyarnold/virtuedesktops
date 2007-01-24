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

#import <Cocoa/Cocoa.h>
#import "VTCoding.h"

@class VTTriggerNotification;

@interface VTTrigger : NSObject<NSCopying, VTCoding> {
	NSString*								mStringValue; 
	BOOL										mRegistered; 
	VTTriggerNotification*	mNotification; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Coding 
- (void) encodeToDictionary: (NSMutableDictionary*) dictionary;
- (id) decodeFromDictionary: (NSDictionary*) dictionary; 
	
#pragma mark -
#pragma mark Attributes 
- (NSString*) stringValue; 

#pragma mark -
- (BOOL) isRegistered; 
- (BOOL) canRegister; 

#pragma mark -
- (VTTriggerNotification*) notification; 
- (void) setNotification: (VTTriggerNotification*) notification; 

#pragma mark -
#pragma mark Operations 
- (void) registerTrigger; 
- (void) unregisterTrigger; 

@end
