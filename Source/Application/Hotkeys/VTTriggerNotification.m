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

#import "VTTriggerNotification.h"
#import "VTTriggerGroup.h"
#import "VTHotkeyTrigger.h"
#import "VTNotifications.h"
#import <Zen/Zen.h>

#define kVtCodingEnabled			@"enabled"
#define kVtCodingName					@"name"
#define kVtCodingTriggerType  @"triggerType"
#define kVtCodingTrigger			@"trigger"
#define kVtCodingTriggers			@"triggers"
#define kVtCodingHotkey				@"hotkey"

#pragma mark -
@implementation VTTriggerNotification

#pragma mark -
#pragma mark Lifetime
+ (id) triggerNotificationForName: (NSString*) name {
  return [[[VTTriggerNotification alloc] initWithName: name] autorelease];
}

#pragma mark -
- (id) initWithName: (NSString*) name {
  if (self = [super init]) {
    ZEN_ASSIGN_COPY(mName, name);

    mNotification = nil;
    mDescription  = nil;

    mEnabled    = YES;

    mUserInfo   = [[NSMutableDictionary alloc] init];
    mTriggers   = [[NSMutableArray alloc] init];
    mGroup      = nil;
    
    return self;
  }

  return nil;
}

- (void) dealloc {
  ZEN_RELEASE(mNotification);
  ZEN_RELEASE(mName);
  ZEN_RELEASE(mDescription);
  ZEN_RELEASE(mUserInfo);
  ZEN_RELEASE(mTriggers);
  ZEN_RELEASE(mGroup);

  [super dealloc];
}

#pragma mark -
- (id) copyWithZone: (NSZone*) zone {
  VTTriggerNotification* notification = [[VTTriggerNotification allocWithZone: zone] initWithName: [[mName copyWithZone: zone] autorelease]];
  [notification setNotification: [[mNotification copyWithZone: zone] autorelease]];
  [notification setDescription: [[mDescription copyWithZone: zone] autorelease]];
  [[notification userInfo] setValuesForKeysWithDictionary: mUserInfo];

  // TODO: Copy over triggers

  return notification;
}


#pragma mark -
#pragma mark Coding
- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
  // code notification
  [dictionary setObject: [NSNumber numberWithBool: mEnabled] forKey: kVtCodingEnabled];
  [dictionary setObject: mName forKey: kVtCodingName];

  // code trigger array
  NSEnumerator* triggerIter   = [mTriggers objectEnumerator];
  VTTrigger*    trigger     = nil;
  NSMutableArray* triggerArray  = [NSMutableArray array];

  while (trigger = [triggerIter nextObject]) {
    NSMutableDictionary* triggerDictionary = [[NSMutableDictionary alloc] init];
    [trigger encodeToDictionary: triggerDictionary];
    [triggerDictionary setObject: NSStringFromClass([trigger class]) forKey: kVtCodingTriggerType];
    // add to array
    [triggerArray addObject: triggerDictionary];

    [triggerDictionary release];
  }

  [dictionary setObject: triggerArray forKey: kVtCodingTriggers];
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {  
  mEnabled  = [[dictionary objectForKey: kVtCodingEnabled] boolValue];
  mName     = [[dictionary objectForKey: kVtCodingName] retain];
  if (mTriggers == nil)
    mTriggers = [[NSMutableArray alloc] init];

  NSArray*    triggerArray = [dictionary objectForKey: kVtCodingTriggers];
  // read in all triggers from the array
  NSEnumerator* triggerIter = [triggerArray objectEnumerator];
  NSDictionary* triggerDict = nil;

  while (triggerDict = [triggerIter nextObject]) {
    // type...
    NSString*   triggerType   = [triggerDict objectForKey: kVtCodingTriggerType];

    // instantiate trigger
    Class       triggerClass  = NSClassFromString(triggerType);
    VTTrigger*  trigger       = [[triggerClass alloc] init];

    trigger = [trigger decodeFromDictionary: triggerDict];
    
    if (trigger) {
      [self insertObjectInTriggers: trigger atIndex: 0];
      [trigger release];
    }
  }

  return self;
}


#pragma mark -
#pragma mark Attributes

- (NSString*) name {
  return mName;
}

#pragma mark -
- (NSString*) description {
  return mDescription;
}

- (void) setDescription: (NSString*) description {
  ZEN_ASSIGN_COPY(mDescription, description);
}

#pragma mark -
- (NSString*) notification {
  return mNotification;
}

- (void) setNotification: (NSString*) name {
  ZEN_ASSIGN_COPY(mNotification, name);
}

#pragma mark -
- (NSMutableDictionary*) userInfo {
  return mUserInfo;
}

- (void) setUserInfo: (NSDictionary*) userInfo {
  ZEN_RELEASE(mUserInfo);

  mUserInfo = [[NSMutableDictionary dictionaryWithDictionary: userInfo] retain];
}

#pragma mark -
- (NSArray*) triggers {
  return mTriggers;
}

- (void) insertObjectInTriggers: (VTTrigger*) trigger atIndex: (unsigned int) index {
  // now register the passed trigger and set it
  [trigger registerTrigger];
  [trigger setNotification: self];
  // and add to our list
  [mTriggers insertObject: trigger atIndex: index];
  // and send notification
  [[NSNotificationCenter defaultCenter] postNotificationName: kVtNotificationWasRegistered object: self];
}

- (void) removeObjectFromTriggersAtIndex: (unsigned int) index {
  VTTrigger* trigger = [mTriggers objectAtIndex: index];

  if (trigger == nil)
    return;

  [trigger unregisterTrigger];
  [trigger setNotification: nil];
  [mTriggers removeObjectAtIndex: index];
}


#pragma mark -
- (VTTriggerGroup*) group {
  return mGroup;
}

- (void) setGroup: (VTTriggerGroup*) group {
  ZEN_ASSIGN(mGroup, group);
}

#pragma mark -
- (void) setEnabled: (BOOL) enabled {
  mEnabled = enabled;

  // and unregister all triggers
  NSEnumerator* triggerIter = [mTriggers objectEnumerator];
  VTTrigger*    trigger   = nil;

  while (trigger = [triggerIter nextObject]) {
    if (enabled)
      [trigger registerTrigger];
    else
      [trigger unregisterTrigger];
  }
}

- (BOOL) isEnabled {
  return mEnabled;
}

#pragma mark -
#pragma mark Requesting notification

- (void) requestNotification {
  if (mEnabled == NO)
    return;
  // post the notification passing self as the object and providing user info
  [[NSNotificationCenter defaultCenter] postNotificationName: mName object: self userInfo: mUserInfo];
}

@end
