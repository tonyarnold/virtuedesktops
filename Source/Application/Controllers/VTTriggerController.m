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

#import "VTTriggerController.h"
#import "VTTriggerNotification.h" 
#import "VTHotkeyTrigger.h" 
#import "VTTriggerDesktopNotification.h" 
#import "VTNotifications.h" 
#import "VTTrigger.h" 
#import "VTDesktopController.h" 
#import "VTPreferences.h" 
#import <Zen/Zen.h>

#define kVtCodingType		@"notificationType"

#pragma mark -
@interface VTTriggerController(Private) 
- (void) registerObservers; 
@end

#pragma mark -
@interface VTTriggerController(Persistency)

- (void) readPreferences; 
- (void) writePreferences; 
- (void) readLocalizedNamesForGroup: (VTTriggerGroup*) group;

@end 

#pragma mark -
@implementation VTTriggerController

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// initialize attributes 
		mNotifications	= [[VTTriggerGroup alloc] initWithKey: @"VT_HOTKEY_ROOT"];  
		mIsEnabled      = YES; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// remove observer 
	[[VTDesktopController sharedInstance] removeObserver: self forKeyPath: @"desktops"]; 
  [[NSNotificationCenter defaultCenter] removeObserver: self]; 
	
	// free attributes 
	ZEN_RELEASE(mNotifications); 
	
	[super dealloc]; 
}

#pragma mark -
+ (VTTriggerController*) sharedInstance {
	static VTTriggerController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil) {
		ms_INSTANCE = [[VTTriggerController alloc] init]; 
		
		[ms_INSTANCE registerObservers]; 		
		[ms_INSTANCE readPreferences]; 
	}
	
	return ms_INSTANCE; 
}

#pragma mark -
#pragma mark Operations  

- (void) addGroup: (VTTriggerGroup*) group {
	[mNotifications addGroup: group]; 
}

#pragma mark -
- (void) addNotification: (VTTriggerNotification*) notification {
	[mNotifications addNotification: notification]; 
}

#pragma mark -
- (void) synchronize {
	[self writePreferences]; 
}

#pragma mark -
#pragma mark Attributes 
- (NSArray*) items {
	return [mNotifications items];  
}

#pragma mark -
- (VTTriggerGroup*) root {
	return mNotifications; 
}

#pragma mark -
- (NSArray*) notificationsWithName: (NSString*) name {
	NSMutableArray*	notifications     = [NSMutableArray array]; 
	NSArray*				allNotifications	= [mNotifications allNotifications]; 
	
	// Now filter for the name of the notification and return it
	NSEnumerator*			notificationIter	= [allNotifications objectEnumerator]; 
	VTTriggerNotification*	notification		= nil; 
	
	while (notification = [notificationIter nextObject]) {
		if ([[notification name] isEqual: name])
			[notifications addObject: notification]; 
	}
	
	return notifications; 
}

- (VTTriggerGroup*) groupWithName: (NSString*) name {
	NSArray* groups = [mNotifications allGroups]; 
	
	// now filter and return the first one we find 
	NSEnumerator*	groupIter	= [groups objectEnumerator]; 
	VTTriggerGroup*	group		= nil; 
	
	while (group = [groupIter nextObject]) {
		if ([[group key] isEqual: name])
			return group; 
	}
	
	return nil; 
}

#pragma mark -
- (void) setEnabled: (BOOL) enabled {
	// set member and unregister all hotkeys 
	mIsEnabled = enabled; 
	
	// iterate over all notifications and try to find the hotkey ref 
	// we just got passed in the notification 
	NSEnumerator*			notificationIter	= [[mNotifications allNotifications] objectEnumerator]; 
	VTTriggerNotification*	currentNotification	= nil; 
	
	while (currentNotification = [notificationIter nextObject]) {
		[currentNotification setEnabled: enabled]; 
	}
}

- (BOOL) isEnabled {
	return mIsEnabled; 
}

#pragma mark -
#pragma mark Notification Sinks 

- (void) onHotKeyPressed: (NSNotification*) notification {
	// ignore if we are not enabled 
	if (mIsEnabled == NO)
		return;

	// fetch the object of the notification object 
	NSValue* oValue = [notification object];
	
	// fetch the hot key reference for identifying the hotkey 
	EventHotKeyRef hotKeyRef;
	[oValue getValue: &hotKeyRef];
	
	// iterate over all notifications and try to find the hotkey ref 
	// we just got passed in the notification 
	NSEnumerator*						notificationIter		= [[mNotifications allNotifications] objectEnumerator]; 
	VTTriggerNotification*	currentNotification	= nil; 
	  
	while (currentNotification = [notificationIter nextObject]) {
		// we have to iterate over all triggers in this notification object 
		NSEnumerator*	triggerIter	= [[currentNotification triggers] objectEnumerator]; 
		VTTrigger*		trigger			= nil; 
		
		while (trigger = [triggerIter nextObject]) {      
			// ignore triggers other than hotkey triggers 
			if ([trigger isKindOfClass: [VTHotkeyTrigger class]] == NO)
				continue;
      
			if ([(VTHotkeyTrigger*)trigger hotkeyRef] == hotKeyRef) {
				// request the notification 
				[currentNotification requestNotification]; 
				// we are done here 
				return; 
			}
		}
	}
	
	// no notification for us here...
}

- (void) onHotKeyRegistered: (NSNotification*) aNotification {
#if 0
	// get the notification that posted the event 
	VTTriggerNotification* notification = [aNotification object]; 
	
	// now iterate over all notifications we know about and unset the hotkey there if they are the same 
	NSEnumerator*			notificationIter	= [[mNotifications allNotifications] objectEnumerator]; 
	VTTriggerNotification*	currentNotification	= nil; 
	
	while (currentNotification = [notificationIter nextObject]) {
		// check if hotkeys are the same 
		if ((currentNotification != notification) && ([[currentNotification trigger] isEqual: [notification trigger]])) {
			// unset the notifications hotkey 
			[currentNotification setTrigger: nil];
			// continue just to be sure we find all duplicates at all times 
		}
	}
	
	if (mIsEnabled == NO)
		return; 
#endif 
}

- (void) onHotKeyUnregistered: (NSNotification*) aNotification {
	if (mIsEnabled == NO)
		return; 
}

#pragma mark -
#pragma mark KVO Sink 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// check for path that changed 
	if ([keyPath isEqual: @"desktops"]) {
		// desktop array 
		NSArray* desktops = [[VTDesktopController sharedInstance] desktops];  
		
		// bring our notifications up to date 
		NSEnumerator*           notificationIter  = [[self notificationsWithName: VTRequestChangeDesktopName] objectEnumerator]; 
		VTTriggerNotification*	notification      = nil; 
		
		while (notification = [notificationIter nextObject]) {
			VTDesktop* desktop = [[notification userInfo] objectForKey: VTRequestChangeDesktopParamName]; 
			
			// check if the desktop is still contained within the desktop collection 
			if ((desktop) && ([desktops containsObject: [[notification userInfo] objectForKey: VTRequestChangeDesktopParamName]] == NO)) {
				// remove the desktop from the user info dictionary 
				[[notification userInfo] removeObjectForKey: VTRequestChangeDesktopParamName]; 
				// remove the notification 
				VTTriggerGroup* desktopGroup = [self groupWithName: VTTriggerGroupNavigationName]; 
				[desktopGroup removeNotification: notification]; 
			}
		}
		
		// now check that every desktop has a notification object 
		NSEnumerator*	desktopIter		= [desktops objectEnumerator]; 
		VTDesktop*		desktop			= nil; 
		VTTriggerGroup*	navigationGroup	= [self groupWithName: VTTriggerGroupNavigationName]; 
		
		while (desktop = [desktopIter nextObject]) {
			VTTriggerDesktopNotification*	desktopNotification		= nil; 
			notificationIter	= [[[VTTriggerController sharedInstance] notificationsWithName: VTRequestChangeDesktopName] objectEnumerator]; 
			
			while (desktopNotification = [notificationIter nextObject]) {
				if ([[desktopNotification desktop] isEqual: desktop]) {
					break; 
				}
			}
			
			if (desktopNotification == nil) {
				// add new notification for this group 
				VTTriggerDesktopNotification *newNotification = [[VTTriggerDesktopNotification alloc] init];
				[navigationGroup addNotification: newNotification]; 
				
				// and we also need to localize the notification correctly 
				[newNotification setDesktop: desktop]; 
				[newNotification setNotification: NSLocalizedStringFromTable([[newNotification name] stringByAppendingString: @"_name"], @"Notifications", @"Notification name")];  
				[newNotification setDescription: NSLocalizedStringFromTable([[newNotification name] stringByAppendingString: @"_desc"], @"Notifications", @"Notification description")];
        [newNotification release];
			}
		}
		
	}
}

@end

#pragma mark -
@implementation VTTriggerController(Private) 

- (void) registerObservers {
	// register ourselves as an observer for key presses 
	[[NSNotificationCenter defaultCenter] addObserver: self 
                                           selector: @selector(onHotKeyPressed:) 
                                               name: kVtNotificationOnKeyPress 
                                             object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self 
                                           selector: @selector(onHotKeyRegistered:) 
                                               name: kVtNotificationWasRegistered 
                                             object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self 
                                           selector: @selector(onHotKeyUnregistered:) 
                                               name: kVtNotificationWasRegistered 
                                             object: nil];
	
	[[VTDesktopController sharedInstance] addObserver: self 
                                         forKeyPath: @"desktops" 
                                            options: NSKeyValueObservingOptionNew 
                                            context: NULL];
}

@end 

#pragma mark -
@implementation VTTriggerController(Persistency) 

// TODO: Move into application bundle code 
- (void) readLocalizedNamesForGroup: (VTTriggerGroup*) group {
	// First, fetch the group 
	[group setName: NSLocalizedStringFromTable([[group key] stringByAppendingString: @"_name"], @"Notifications", @"Group name")]; 
	
	// get notifications 		
	NSEnumerator*	itemIter	= [[group items] objectEnumerator]; 
	id				item		= nil;
	
	while (item = [itemIter nextObject]) {
		// if we deal with a group, call ourselves recursively 
		if ([item isKindOfClass: [VTTriggerGroup class]])
			[self readLocalizedNamesForGroup: item]; 
		else if ([item isKindOfClass: [VTTriggerNotification class]]) {
			VTTriggerNotification* notification = (VTTriggerNotification*)item; 
			
			// get name and description for notification 
			[notification setNotification: NSLocalizedStringFromTable([[notification name] stringByAppendingString: @"_name"], @"Notifications", @"Notification name")];  
			[notification setDescription: NSLocalizedStringFromTable([[notification name] stringByAppendingString: @"_desc"], @"Notifications", @"Notification description")];
    }
	}
}

#pragma mark -
- (void) readPreferences {
  // @TODO@: Rewrite me to only unarchive objects with modified keys, and not the actual objects, but just the key values.
  NSString* defaultHotkeysPath = [[NSBundle bundleForClass: [VTTriggerController class]] pathForResource: @"DefaultHotkeys" ofType: @"plist"];
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithContentsOfFile: defaultHotkeysPath];
  [dictionary addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] objectForKey: VTHotkeys]];
	[mNotifications decodeFromDictionary: dictionary]; 
  	
	// Now we ensure that all desktops have their notification registered 
	NSArray*      desktopNotifications	= [self notificationsWithName: VTRequestChangeDesktopName];
  NSEnumerator*	desktopIter           = [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop               = nil;
	
	while (desktop = [desktopIter nextObject]) {
		NSEnumerator*           notificationIter  = [desktopNotifications objectEnumerator]; 
		VTTriggerNotification*	notification      = nil;
		
		while (notification = [notificationIter nextObject]) {
      
			if ([notification isKindOfClass: [VTTriggerDesktopNotification class]] == NO)
				continue; 
			
			if ([[(VTTriggerDesktopNotification*)notification desktop] isEqual: desktop]) 
				break; 
      
      if (notification == nil) {
        notification = [[[VTTriggerDesktopNotification alloc] init] autorelease]; 
        [(VTTriggerDesktopNotification*)notification setDesktop: desktop]; 
        
        [[self groupWithName: VTTriggerGroupNavigationName] addNotification: notification];
      }
		}		
	}
  
	// try to localize 
	[self readLocalizedNamesForGroup: mNotifications];
}

- (void) writePreferences {
  // @TODO@: Rewrite me to only archive objects with keys, and not the actual objects, but just the key values. What a mess!
  
	NSMutableDictionary* groupDict = [NSMutableDictionary dictionary]; 
	
	[mNotifications encodeToDictionary: groupDict]; 
	[[NSUserDefaults standardUserDefaults] setObject: groupDict forKey: VTHotkeys]; 
}

@end
