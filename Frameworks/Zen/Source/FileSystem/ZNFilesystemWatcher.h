/******************************************************************************
* 
* Zen 
*
* A foundations framework 
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>
// kqueue includes 
#include <sys/types.h>
#include <sys/event.h>

#define kZnUserInfoCurrentPath					@"ZNUserInfoCurrentPath"

#define kZnNotifyAboutRename					NOTE_RENAME
#define kZnNotifyAboutWrite						NOTE_WRITE
#define kZnNotifyAboutDelete					NOTE_DELETE
#define kZnNotifyAboutAttributeChange			NOTE_ATTRIB
#define kZnNotifyAboutSizeIncrease				NOTE_EXTEND
#define kZnNotifyAboutLinkCountChanged			NOTE_LINK
#define kZnNotifyAboutAccessRevocation			NOTE_REVOKE

#define ZNFileRenamedNotification				@"ZNFileRenamedNotification"
#define ZNFileWrittenToNotification				@"ZNFileWrittenToNotification"
#define ZNFileDeletedNotification				@"ZNFileDeletedNotification"
#define ZNFileAttributesChangedNotification		@"ZNFileAttributesChangedNotification"
#define ZNFileSizeChangedNotification			@"ZNFileSizeChangedNotification"
#define ZNFileLinkCountChangedNotification		@"ZNFileLinkCountChangedNotification"
#define ZNFileAccessRevocationNotification		@"ZNFileAccessRevocationNotification"

#pragma mark -
@interface ZNFilesystemWatcher : NSObject {
	// our kqueue descriptor 
	int						mKQueueDescriptor;
	// stores the path as the key; the descriptor as the value object 
	NSMutableDictionary*	mPaths;
}

#pragma mark -
#pragma mark Lifetime 

+ (ZNFilesystemWatcher*) sharedInstance; 

#pragma mark -
- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Watcher operations 

- (void) attachPath: (NSString*) path;
- (void) attachPath: (NSString*) path filter: (u_int) flags; 
- (void) detachPath: (NSString*) path;

@end
