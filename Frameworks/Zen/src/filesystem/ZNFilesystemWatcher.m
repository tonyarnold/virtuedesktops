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

#import <Foundation/Foundation.h> 
#import "ZNFilesystemWatcher.h"
#import "ZNMemoryManagementMacros.h" 
#import <stdio.h>
#import <fcntl.h>
#import <unistd.h> 


#define kZnFSRef		@"ZNFSRef"
#define kZnFSHandle		@"ZNFSHandle"

@interface ZNFilesystemWatcher(Private)
- (void) service: (id) sender; 
- (void) postNotification: (NSString*) name forPath: (NSString*) path; 
@end 

@implementation ZNFilesystemWatcher

#pragma mark -
#pragma mark Lifetime 

+ (ZNFilesystemWatcher*) sharedInstance {
	static ZNFilesystemWatcher* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[ZNFilesystemWatcher alloc] init]; 
	
	return ms_INSTANCE; 
}

#pragma mark -

- (id) init {
	if (self = [super init]) {
		// create a new queue 
		mKQueueDescriptor = kqueue();
		if (mKQueueDescriptor == -1) {
			// if we cannot create a queue, it does not make sense to continue 
			ZEN_RELEASE(self); 
			return nil;
		}
		
		// attributes 
		mPaths = [[NSMutableDictionary alloc] init];
		
		// start our service method in its own thread 
		[NSThread detachNewThreadSelector: @selector(service:) toTarget: self withObject: self];
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	if (mKQueueDescriptor != -1) {
		// we got to remember the descriptor and set it to -1 to trigger shutdown of 
		// our service method 
		int descriptorToClose = mKQueueDescriptor; 
		mKQueueDescriptor = -1; 

		// now close the descriptor 
		close(descriptorToClose); 
	}
	
	ZEN_RELEASE(mPaths); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Watcher operations 

- (void) attachPath: (NSString*) path {
	// forward to more sophisticated method filtering for renames, writes, deletes and attribute changes 
	[self attachPath: path filter: kZnNotifyAboutRename |
								   kZnNotifyAboutWrite  |
								   kZnNotifyAboutDelete |
								   kZnNotifyAboutAttributeChange]; 
}

- (void) attachPath: (NSString*) path filter: (u_int) flags {
	struct timespec		noTimespec = {0, 0};
	struct kevent		event;
	int					descriptor	= open([path fileSystemRepresentation], O_RDONLY, 0);
	FSRef				fsref; 
	
	// if we could not open the file, we will bail immediately 
	if (descriptor <= 0)
		return; 
	// create the fsref structure 
	if (FSPathMakeRef([path fileSystemRepresentation], &fsref, NULL)) 
		return; 
	
	EV_SET(&event, descriptor, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, flags, 0, (void*)[path copy]);
	
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary]; 
	[dictionary setObject: [NSNumber numberWithInt: descriptor] forKey: kZnFSHandle]; 
	[dictionary setObject: [NSData dataWithBytes: &fsref length: sizeof(FSRef)] forKey: kZnFSRef]; 	
	[mPaths setObject: dictionary forKey: path]; 
  	
	kevent(mKQueueDescriptor, &event, 1, NULL, 0, &noTimespec);	
}

- (void) detachPath: (NSString*) path {
	NSDictionary* dict = [mPaths objectForKey: path]; 

	// check that we know about the path we are about to delete 
	if (dict == nil)
		return; 
	
	NSNumber*	descriptorObject	= [dict objectForKey: kZnFSHandle];
	
	// close the descriptor 
	close([descriptorObject intValue]);
	// remove the object from our dictionary 
	[mPaths removeObjectForKey: path]; 
}

@end 

#pragma mark -
@implementation ZNFilesystemWatcher(Private) 

- (void) service: (id) sender {
	int					number;
    struct kevent		event;
    
    while (mKQueueDescriptor != -1) {
		NSAutoreleasePool* autoreleasePool = [[NSAutoreleasePool alloc] init];
		
		NS_DURING
			number = kevent(mKQueueDescriptor, NULL, 0, &event, 1, NULL);
			
			// if we have to handle an event, do so 
			if (number > 0) {
				if (event.filter == EVFILT_VNODE) {
					if (event.fflags) {
						// fetch the path 
						NSString* path = (NSString*)event.udata;
						
						if (path == nil)
							continue; 
						
						// trigger notification via the shared workspace instance 
						[[NSWorkspace sharedWorkspace] noteFileSystemChanged: path];
						
						// check which notifications we should send to our listeners 
						if ((event.fflags & NOTE_RENAME) == NOTE_RENAME)
							[self postNotification: ZNFileRenamedNotification forPath: path];
						if ((event.fflags & NOTE_WRITE) == NOTE_WRITE)
							[self postNotification: ZNFileWrittenToNotification forPath: path];
						if ((event.fflags & NOTE_DELETE) == NOTE_DELETE)
							[self postNotification: ZNFileDeletedNotification forPath: path];
						if ((event.fflags & NOTE_ATTRIB) == NOTE_ATTRIB)
							[self postNotification: ZNFileAttributesChangedNotification forPath: path];
						if ((event.fflags & NOTE_EXTEND) == NOTE_EXTEND)
							[self postNotification: ZNFileSizeChangedNotification forPath: path];
						if ((event.fflags & NOTE_LINK) == NOTE_LINK)
							[self postNotification: ZNFileLinkCountChangedNotification forPath: path];
						if ((event.fflags & NOTE_REVOKE) == NOTE_REVOKE)
							[self postNotification: ZNFileAccessRevocationNotification forPath: path];
					}
				}
			}
		NS_HANDLER
			NSLog(@"Error handling kqueue event: %@", localException);
		NS_ENDHANDLER
			
		ZEN_RELEASE(autoreleasePool); 
    }
}

- (void) postNotification: (NSString*) name forPath: (NSString*) path {
	// first create the user info needed; we could optimize here a bit.. 
	NSMutableDictionary* userInfo	= [NSMutableDictionary dictionary]; 
	NSDictionary*		 dict		= [mPaths objectForKey: path]; 
	
	// get the current filename
	CFURLRef	url		= CFURLCreateFromFSRef(kCFAllocatorDefault, [[dict objectForKey: kZnFSRef] bytes]);
	NSString*	string	= @"";
	if (url != NULL) {
		string = (NSString*)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		CFRelease(url);
	}
	[userInfo setObject: string forKey: kZnUserInfoCurrentPath];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName: name object: path userInfo: userInfo];
}

@end
