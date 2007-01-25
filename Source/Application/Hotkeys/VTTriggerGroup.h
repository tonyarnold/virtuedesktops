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
#import "VTTriggerNotification.h"
#import "VTCoding.h"

#define VTTriggerGroupNavigationName    @"VTGroupNavigation"
#define VTTriggerGroupDesktopsName      @"VTGroupDesktops"
#define VTTriggerGroupInspectionName    @"VTGroupInspection"
#define VTTriggerGroupWindowsName       @"VTGroupWindows"

#pragma mark -
@interface VTTriggerGroup : NSObject<VTCoding> {
  NSString*         mName;            //!< Name of the hotkey group
  NSString*         mKey;             //!< Key of the hotkey group
  NSMutableArray*   mNotifications;   //!< Notifications contained in this group
}

#pragma mark -
#pragma mark Lifetime

- (id) initWithKey: (NSString*) key;
- (id) initWithKey: (NSString*) key andName: (NSString*) name;

#pragma mark -
#pragma mark Attributes

- (NSString*) name;
- (void) setName: (NSString*) name;

#pragma mark -
- (NSString*) key;

#pragma mark -
- (NSArray*) items;

#pragma mark -
#pragma mark Notifications

- (void) addNotification: (VTTriggerNotification*) notification;
- (void) removeNotification: (VTTriggerNotification*) notification;
- (NSArray*) notifications;
- (NSArray*) allNotifications;

#pragma mark -
#pragma mark Groups

- (void) addGroup: (VTTriggerGroup*) group;
- (void) removeGroup: (VTTriggerGroup*) group;
- (NSArray*) groups;
- (NSArray*) allGroups;

@end
