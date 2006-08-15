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

#import <Foundation/Foundation.h>
#import "VTTrigger.h"
#import "VTCoding.h"

@class VTTriggerGroup;

@interface VTTriggerNotification : NSObject<VTCoding> {
  NSString*             mName;					//!< The notification to trigger for this event

  NSString*             mNotification;  //!< Human readable localized name for the notification event
  NSString*             mDescription;   //!< Human readable localized description for the notification event

  NSMutableDictionary*  mUserInfo;      //!< User info passed on to the NSNotifications posted by this instance
  BOOL                  mEnabled;				//!< Indicates the enabled state

  NSMutableArray*       mTriggers;      //!< Triggers assigned to the notification
  VTTriggerGroup*       mGroup;
}

#pragma mark -
#pragma mark Lifetime
+ (id) triggerNotificationForName: (NSString*) name;
- (id) initWithName: (NSString*) name;

#pragma mark -
#pragma mark Attributes
- (NSString*) name;

#pragma mark -
- (NSString*) description;
- (void) setDescription: (NSString*) description;

#pragma mark -
- (NSString*) notification;
- (void) setNotification: (NSString*) notification;

#pragma mark -
- (NSMutableDictionary*) userInfo;
- (void) setUserInfo: (NSDictionary*) userInfo;

#pragma mark -
- (NSArray*) triggers;
- (void) insertObjectInTriggers: (VTTrigger*) trigger atIndex: (unsigned int) index;
- (void) removeObjectFromTriggersAtIndex: (unsigned int) index;

#pragma mark -
- (VTTriggerGroup*) group;
- (void) setGroup: (VTTriggerGroup*) group;

#pragma mark -
- (void) setEnabled: (BOOL) enabled;
- (BOOL) isEnabled;

#pragma mark -
#pragma mark Triggering notifications
- (void) requestNotification;

@end
