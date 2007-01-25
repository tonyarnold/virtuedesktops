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

#import "VTTriggerGroup.h"
#import <Zen/Zen.h>

#define kVtCodingType       @"type"
#define kVtCodingKey        @"groupKey"
#define kVtCodingItems      @"items"

#pragma mark -
@implementation VTTriggerGroup

#pragma mark -
#pragma mark Lifetime

- (id) initWithKey: (NSString*) key {
  return [self initWithKey: key andName: @""];
}

- (id) initWithKey: (NSString*) key andName: (NSString*) name {
  if (self = [super init]) {
    // initialize attributes
    ZEN_ASSIGN_COPY(mName, name);
    ZEN_ASSIGN_COPY(mKey, key);

    mNotifications  = [[NSMutableArray array] retain];

    return self;
  }

  return nil;
}

- (id) init {
  return [self initWithKey: @"" andName: @""];
}

- (void) dealloc {
  ZEN_RELEASE(mKey);
  ZEN_RELEASE(mName);
  ZEN_RELEASE(mNotifications);

  [super dealloc];
}

#pragma mark -
#pragma mark Coding

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
  NSEnumerator* itemIter  = [mNotifications objectEnumerator];
  NSObject*   item    = nil;

  NSMutableArray* items   = [NSMutableArray array];

  while (item = [itemIter nextObject]) {
    NSMutableDictionary* notificationDictionary = [NSMutableDictionary dictionary];
    [notificationDictionary setObject: NSStringFromClass([item class]) forKey: kVtCodingType];

    [(NSObject<VTCoding>*)item encodeToDictionary: notificationDictionary];
    [items addObject: notificationDictionary];
  }

  [dictionary setObject: mKey forKey: kVtCodingKey];
  [dictionary setObject: items forKey: kVtCodingItems];
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
  // decode key
  mKey = [[dictionary objectForKey: kVtCodingKey] retain];

  // fetch items from passed dictionary
  NSArray* items = [dictionary objectForKey: kVtCodingItems];
  if ((items == nil) || ([items count] == 0))
    return;    
    
  NSEnumerator* itemIter = [items objectEnumerator];
  NSDictionary* itemDict = nil;

  while (itemDict = [itemIter nextObject]) {
    NSString* itemType = [itemDict objectForKey: kVtCodingType];

    // Backwards compatibility
    if ([itemType isEqualToString: @"VTHotkeyGroup"])
      itemType = @"VTTriggerGroup";
    else if ([itemType isEqualToString: @"VTHotkeyNotification"])
      itemType = @"VTTriggerNotification";
    else if ([itemType isEqualToString: @"VTHotkeyNotificationDesktop"])
      itemType = @"VTTriggerDesktopNotification";
    // End Backwards compatibility

    Class itemClass = NSClassFromString(itemType);
    if (itemClass == nil)
      continue;

    if ([itemType isEqualToString: NSStringFromClass([VTTriggerGroup class])]) {
      VTTriggerGroup* group = [[[[VTTriggerGroup alloc] init] decodeFromDictionary: itemDict] autorelease];

      if (group)
        [self addGroup: group];
    }
    else 
    {
      VTTriggerNotification* notification = [[[itemClass alloc] init] decodeFromDictionary: itemDict];
      if (notification)
        [self addNotification: notification];
      
      [notification release];
    }
    
  }
  return self;
}

#pragma mark -
#pragma mark Accessors

- (NSString*) name {
  return mName;
}

- (void) setName: (NSString*) name {
  ZEN_ASSIGN_COPY(mName, name);
}

#pragma mark -
- (NSString*) key {
  return mKey;
}

#pragma mark -
- (NSArray*) items {
  return mNotifications;
}

- (NSArray*) groups {
  NSMutableArray* groups      = [NSMutableArray array];
  NSEnumerator*   groupsIter  = [mNotifications objectEnumerator];
  id              item        = nil;

  while (item = [groupsIter nextObject]) {
    if ([item isKindOfClass: [VTTriggerGroup class]])
      [groups addObject: item];
  }

  return groups;
}

#pragma mark -
- (NSArray*) notifications {
  NSMutableArray* notifications   = [NSMutableArray array];
  NSEnumerator* notificationsIter = [mNotifications objectEnumerator];
  id        item        = nil;

  while (item = [notificationsIter nextObject]) {
    if ([item isKindOfClass: [VTTriggerNotification class]])
      [notifications addObject: item];
  }

  return notifications;
}

- (NSArray*) allNotifications  {
  NSEnumerator* notificationIter  = [mNotifications objectEnumerator];
  id            item              = nil;
  NSMutableArray* notifications   = [NSMutableArray array];

  while (item = [notificationIter nextObject]) {
    // if the current item is a notification, add it to the
    // list...
    if ([item isKindOfClass: [VTTriggerNotification class]])
      [notifications addObject: item];
    // otherwise we will forward to the group...
    else {
      NSArray* subNotifications = [item allNotifications];

      if ([subNotifications count] > 0)
        [notifications addObjectsFromArray: subNotifications];
    }
  }

  return notifications;
}

#pragma mark -
- (NSArray*) allGroups {
  NSEnumerator* notificationIter  = [mNotifications objectEnumerator];
  id        item        = nil;

  NSMutableArray* groups        = [NSMutableArray array];

  while (item = [notificationIter nextObject]) {
    // if the current item is a group, add it to the
    // list and also fetch all subgroups to add
    if ([item isKindOfClass: [VTTriggerGroup class]]) {
      [groups addObject: item];
      // and also forward
      NSArray* subGroups = [item allGroups];
      [groups addObjectsFromArray: subGroups];
    }
  }

  return groups;
}

#pragma mark -
#pragma mark Notifications

- (void) addNotification: (VTTriggerNotification*) notification {
  if ([mNotifications containsObject: notification])
    return;

  [self willChangeValueForKey: @"notifications"];
  [notification setGroup: self];
  [mNotifications addObject: notification];
  [self didChangeValueForKey: @"notifications"];
}

- (void) removeNotification: (VTTriggerNotification*) notification {
  [self willChangeValueForKey: @"notifications"];

  // remove all triggers
  while ([[notification triggers] count] > 0) {
    [notification removeObjectFromTriggersAtIndex: 0];
  }

  [notification setGroup: nil];
  [mNotifications removeObject: notification];
  [self didChangeValueForKey: @"notifications"];
}


#pragma mark -
#pragma mark Groups

- (void) addGroup: (VTTriggerGroup*) group {
  // add a new subgroup
  if ([mNotifications containsObject: group])
    return;

  [self willChangeValueForKey: @"notifications"];
  [mNotifications addObject: group];
  [self didChangeValueForKey: @"notifications"];
}

- (void) removeGroup: (VTTriggerGroup*) group {
  [self willChangeValueForKey: @"notifications"];
  [mNotifications removeObject: group];
  [self didChangeValueForKey: @"notifications"];
}

@end
