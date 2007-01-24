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

#import "NSStringFSRef.h"


@implementation NSString(VTFSRef)

- (BOOL) createFSRef: (FSRef*) fsRef createIfNecessary: (BOOL) create {
	CFURLRef	urlRef;
	Boolean		gotFSRef;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: self]) {
        if (create) {
            if (![@"" writeToFile: self atomically: YES]) {
                return NO;
            }
        } 
		else {
            return NO;
        }
    }
	
    // Create a CFURL with the specified POSIX path.
    urlRef = CFURLCreateWithFileSystemPath( kCFAllocatorDefault,
                                            (CFStringRef) self,
                                            kCFURLPOSIXPathStyle,
                                            FALSE);
    if (urlRef == NULL) {
		//        printf( "** Couldn't make a CFURLRef for the file.\n" );
        return NO;
    }
    
    // Try to create an FSRef from the URL.  (If the specified file doesn't exist, this
    // function will return false, but if we've reached this code we've already insured
    // that the file exists.)
    gotFSRef = CFURLGetFSRef(urlRef, fsRef);
    CFRelease(urlRef);
	
    if (!gotFSRef) {
        return NO;
    }
    
    return YES;
}

- (BOOL) createFSSpec: (FSSpec*) fsSpec createIfNecessary: (BOOL) create {
    FSRef fsRef;
	
    if (![self createFSRef: &fsRef createIfNecessary: create])
        return NO;
    
    if (FSGetCatalogInfo( &fsRef,
                          kFSCatInfoNone,
                          NULL,
                          NULL,
                          fsSpec,
                          NULL ) != noErr) {
        return NO;
    }
	
    return YES;
}


@end
