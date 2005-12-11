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

#import "VTDesktopFilesystemController.h"
#import "VTDesktopController.h" 
#import "VTNotifications.h" 
#import "NSStringFSRef.h" 
#import <Zen/Zen.h> 

@interface VTDesktopFilesystemController(Private) 
- (VTDesktop*) desktopForName: (NSString*) name; 
@end 


#pragma mark -
@implementation VTDesktopFilesystemController

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		// attributes
		mWatchers = [[NSMutableDictionary alloc] init];
		
		[VTDesktopFilesystemController createVirtualDesktopContainer]; 
		
		NSString*	virtualDesktopContainerPath = [VTDesktop virtualDesktopContainerPath]; 

		// now start watching the directory 
		[[ZNFilesystemWatcher sharedInstance] attachPath: virtualDesktopContainerPath filter: kZnNotifyAboutWrite]; 
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(onDesktopContainerPathWritten:) name: ZNFileWrittenToNotification object: virtualDesktopContainerPath]; 		
		
		// start watching for desktop changes 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWasAdded:) name: VTDesktopDidAddNotification object: nil]; 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWasRemoved:) name: VTDesktopWillRemoveNotification object: nil]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mWatchers); 
	
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self]; 
	
	[super dealloc]; 
}

+ (VTDesktopFilesystemController*) sharedInstance {
	static VTDesktopFilesystemController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[VTDesktopFilesystemController alloc] init]; 
	
	return ms_INSTANCE; 
} 

#pragma mark -
#pragma mark Persistency control 
+ (void) createVirtualDesktopContainer {
	// make sure that our virtual desktop path is existing 
	NSString*	path = [VTDesktop virtualDesktopContainerPath]; 
	BOOL			isDirectory; 
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory] == NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath: path attributes: nil];
	}
}

#pragma mark -
#pragma mark Notification Sinks 
- (void) onDesktopWasAdded: (NSNotification*) notification {
	VTDesktop*	desktop			= [notification object]; 
	NSString*		desktopPath	= [[VTDesktop virtualDesktopPath: desktop] stringByAppendingString: @".plist"]; 
	
	// attach watcher 
	[mWatchers setObject: desktop forKey: desktopPath]; 
	[[ZNFilesystemWatcher sharedInstance] attachPath: desktopPath filter: kZnNotifyAboutRename | kZnNotifyAboutDelete]; 
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(onDesktopDeleted:) name: ZNFileDeletedNotification object: desktopPath];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(onDesktopRenamed:) name: ZNFileRenamedNotification object: desktopPath];	
}

- (void) onDesktopWasRemoved: (NSNotification*) notification {
	VTDesktop* desktop = [notification object];
	
	// detach the watcher path 
	NSEnumerator*	enumerator	= [mWatchers keyEnumerator]; 
	NSString*			path				= nil; 
	
	while (path = [enumerator nextObject]) {
		if ([[mWatchers objectForKey: path] isEqual: desktop]) 
			break; 
	}
	
	if (path) {
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: ZNFileDeletedNotification object: path]; 		
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: ZNFileRenamedNotification object: path]; 		
		
		[[ZNFilesystemWatcher sharedInstance] detachPath: path]; 
		[mWatchers removeObjectForKey: path]; 
	}
	
}


#pragma mark -

- (void) onDesktopDeleted: (NSNotification*) notification {
	// trigger deletion by removing the desktop from the desktop controller 
	VTDesktop* desktop = [mWatchers objectForKey: [notification object]]; 
	
	if (desktop == nil)
		return; 
	
	[[VTDesktopController sharedInstance] removeObjectFromDesktopsAtIndex: [[[VTDesktopController sharedInstance] desktops] indexOfObject: desktop]]; 
}

- (void) onDesktopRenamed: (NSNotification*) notification {
	// trigger renaming of the desktop 
	VTDesktop* desktop = [mWatchers objectForKey: [notification object]]; 
	// fetch the current name of the desktop 
	NSString* desktopPath = [[notification userInfo] objectForKey: kZnUserInfoCurrentPath]; 

	// check if the desktop path is still within our desktop container directory, and 
	// treat a rename to another directory as a remove operation (the finder will just
	// rename files if dragged to the trash 
	if ([desktopPath hasPrefix: [VTDesktop virtualDesktopContainerPath]] == NO) {
		[self onDesktopDeleted: notification]; 
		return; 
	}
	
	// extract the name of the directory to use as the desktop name 
	NSString* desktopName = [desktopPath lastPathComponent]; 
	
	// and rename if necessary 
	if ([desktopName isEqual: [desktop name]])
		return;
	
	[desktop setName: desktopName]; 
}

- (void) onDesktopContainerPathWritten: (NSNotification*) notification {
	// First fetch contents of the directory
	NSString*			virtualDesktopPath			= [VTDesktop virtualDesktopContainerPath];
	
	// Iterate all desktops found there 
	NSArray*			virtualDesktopFiles			= [[NSFileManager defaultManager] directoryContentsAtPath: virtualDesktopPath];
	NSEnumerator*	virtualDesktopFilesIter	= [virtualDesktopFiles objectEnumerator];
	NSString*			virtualDesktopFile			= nil;
	
	BOOL						isDirectory; 
	NSMutableArray*	virtualDesktops			= [[NSMutableArray alloc] init]; 
	
	// filter array to only include directories 
	while (virtualDesktopFile = [virtualDesktopFilesIter nextObject]) {
		NSString* targetPath = [virtualDesktopPath stringByAppendingPathComponent: virtualDesktopFile];
		[[NSFileManager defaultManager] fileExistsAtPath: targetPath isDirectory: &isDirectory]; 
		
		if (isDirectory)
			[virtualDesktops addObject: virtualDesktopFile]; 
	}
	
	if ([virtualDesktops count] <= [[[VTDesktopController sharedInstance] desktops] count])
		return; 
	
	// identify the desktops to add 
	NSEnumerator*	desktopIter = [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		if ([virtualDesktops containsObject: [desktop name]] == YES)
			[virtualDesktops removeObject: [desktop name]]; 
	}
	
	// now iterate over all names left and create the desktops 
	NSEnumerator*	virtualDesktopIter	= [virtualDesktops objectEnumerator]; 
	NSString*			virtualDesktop			= nil; 
	
	while (virtualDesktop = [virtualDesktopIter nextObject]) {
		VTDesktop* newDesktop = [[VTDesktopController sharedInstance] desktopWithFreeId]; 
		[newDesktop setName: virtualDesktop]; 
		
		[[VTDesktopController sharedInstance] insertObject: newDesktop inDesktopsAtIndex: [[[VTDesktopController sharedInstance] desktops] count]]; 
	}
}

@end

#pragma mark -
@implementation VTDesktopFilesystemController(Private) 

- (VTDesktop*) desktopForName: (NSString*) name {
	NSEnumerator*	desktopIter = [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		if ([[desktop name] isEqual: name])
			return desktop; 
	}
	
	return nil; 
}

@end 

