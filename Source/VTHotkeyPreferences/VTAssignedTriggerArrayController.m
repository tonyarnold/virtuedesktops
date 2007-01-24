//
//  VTAssignedTriggerArrayController.m
//  VirtueDesktops
//
//  Created by Tony Arnold on 15/08/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#import "VTAssignedTriggerArrayController.h"
#import "VTTrigger.h"
#import "VTTriggerNotification.h"


@implementation VTAssignedTriggerArrayController
- (NSArray*) arrangeObjects: (NSArray*) objects {
	NSMutableArray*	assignedTriggers	= [NSMutableArray array]; 
	NSEnumerator*		objectsIter				= [objects objectEnumerator]; 
	NSObject*				object						= nil; 
	
	while (object = [objectsIter nextObject]) {
		if ([object isKindOfClass: [VTTriggerNotification class]] == NO)
			continue;
		
		VTTriggerNotification* notification = (VTTriggerNotification*)object; 
		// if we have no triggers assigned, move to the next notification 
		if ([[notification triggers] count] == 0)
			continue; 
		
		NSEnumerator*	triggerIter	= [[notification triggers] objectEnumerator]; 
		VTTrigger*		trigger		= nil; 
		
		while (trigger = [triggerIter nextObject]) {
			// Create a new entry for each trigger 
			NSMutableDictionary* triggerInfo = [[NSMutableDictionary alloc] init]; 
			
			[triggerInfo setObject: notification forKey: @"notification"]; 
			[triggerInfo setObject: trigger			 forKey: @"trigger"]; 
			
			// Now add it to our array 
			[assignedTriggers addObject: triggerInfo]; 
			
			[triggerInfo release]; 
		}
	}
	
	return assignedTriggers; 
}
@end
