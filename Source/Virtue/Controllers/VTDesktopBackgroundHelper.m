/******************************************************************************
 * 
 * VirtueDesktops 
 *
 * A desktop extension for MacOS X
 *
 * Copyright 2004, Thomas Staller (playback@users.sourceforge.net)
 * Copyright 2007, Tony Arnold (tony@tonyarnold.com)
 *
 * See COPYING for licensing details
 * 
 * Copyright 2001-2004 Brian Bergstrand
 * See File Footer for information 
 * 
 *****************************************************************************/ 

#import "VTDesktopBackgroundHelper.h"
#import <Zen/Zen.h>

enum {
	kFinderSig					= 'FNDR',
	kFinderCreator			= 'MACS',
	typeDesktopPicture	= 'dpic', 
};

#define NO_INDEX -1
// timeout is 12 seconds (in ticks 720) 
#define FINDER_AE_TIMEOUT 720

#define VTBackgroundHelperPListDomainName					@"com.apple.desktop"
#define VTBackgroundHelperPListDesktopName				@"Background"
#define VTBackgroundHelperPListDefaultScreenName	@"default"
#define VTBackgroundHelperFinderName							@"com.apple.finder"

OSStatus AEHelperCoerceNSURL (NSURL *furl, DescType toType, AEDesc *result); 

@interface VTDesktopBackgroundHelper(Private) 
- (void) updateMode; 
@end 

#pragma mark -
@interface VTDesktopBackgroundHelper(VTBackground)
#pragma mark -
- (void) setBackgroundUsingFinder: (NSString*) file; 
- (NSString*) backgroundUsingFinder; 
#pragma mark -
- (void) setBackgroundUsingPList: (NSString*) file; 
- (NSString*) backgroundUsingPList; 
@end 

#pragma mark -
@implementation VTDesktopBackgroundHelper

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		// init attributes 
		mMode       = VTBackgroundHelperModeNone; 
		mFinderPid  = 0; 
		
		// find out which mode to use 
		[self updateMode];
		ZEN_ASSIGN(mDefaultDesktopBackgroundPath, [self background]);
		
		return self; 
	}
	
	return nil; 
}

+ (id) sharedInstance {
	static VTDesktopBackgroundHelper* msINSTANCE = nil; 
	
	if (msINSTANCE == nil) {
		msINSTANCE = [[VTDesktopBackgroundHelper alloc] init]; 
	}
	
	return msINSTANCE; 
}

- (void) dealloc {		
  ZEN_RELEASE(mDefaultDesktopBackgroundPath);
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (VTBackgroundHelperMode) mode {
	return mMode; 
}

#pragma mark -
- (BOOL) canSetBackground {
	return (mMode != VTBackgroundHelperModeNone); 
}

#pragma mark -
#pragma mark Operations 
- (void) setBackground: (NSString*) path {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath: path] == NO)
		return;
	
	
	switch (mMode) {
	case VTBackgroundHelperModeFinder: 
		[self setBackgroundUsingFinder: path]; 
		break; 
	case VTBackgroundHelperModePList: 
		[self setBackgroundUsingPList: path]; 
		break; 
	case VTBackgroundHelperModeNone: 
		// Fallthrough
	default: 
		break; 
	}; 
}

- (NSString*) background {
	// As a first implementation we always query the PList for the desktop 
	// @TODO@ Implement Finder querying 
#if 0	
	switch (mMode) {
	case VTBackgroundHelperModeFinder: 
		return [self backgroundUsingFinder]; 
	case VTBackgroundHelperModePList: 
#endif 
		return [self backgroundUsingPList]; 
#if 0
	case VTBackgroundHelperModeNone: 
		// Fallthrough
	default: 
		break; 
	}; 
	
	return nil; 
#endif 
}

- (void) setDefaultBackground: (NSString*) path {
	if (path == nil)
		return;
	
	ZEN_ASSIGN_COPY(mDefaultDesktopBackgroundPath, path);
}

- (NSString*) defaultBackground {
	return [[mDefaultDesktopBackgroundPath copy] autorelease];
}

@end

#pragma mark -
@implementation VTDesktopBackgroundHelper(Private) 

- (void) updateMode {
	// here we gonna find out which mode to use to switch desktop background pictures
	// the preference list is 
	// 1) Finder
	// 2) PList modification
	// 
	
	// first try to find the Finder process, and if it is there, use it 
	NSArray*			applications		= [[NSWorkspace sharedWorkspace] launchedApplications]; 
	NSEnumerator*	applicationIter	= [applications objectEnumerator];  
	NSDictionary*	application			= nil; 
	
	while (application = [applicationIter nextObject]) {
		if ([[application objectForKey: @"NSApplicationBundleIdentifier"] isEqualToString: VTBackgroundHelperFinderName]) {
			// fetch the finder pid
			mFinderPid	= [[application objectForKey: @"NSApplicationProcessIdentifier"] intValue]; 
			// set our mode 
			mMode		= VTBackgroundHelperModeFinder; 
			
			// done here 
			return; 
		}
	}
	
	// check if we find the PList we need 
	NSUserDefaults* plistDef	= [[[NSUserDefaults alloc] init] autorelease];  
	NSDictionary*	plist		= [plistDef persistentDomainForName: VTBackgroundHelperPListDomainName]; 
	
	if (plist != nil) {
		mMode = VTBackgroundHelperModePList; 
		return; 
	}
	
	// got no chance here, we cannot do any desktop background changes 
	mMode = VTBackgroundHelperModeNone; 
}

@end 

#pragma mark -
@implementation VTDesktopBackgroundHelper(VTBackground)

#pragma mark -

// 
// Based on an implementation by Brian Bergstrand, Copyright 2001-2004  
// 
// TODO: This one could certainly use some optimization, I guess. Development build performs in 0.03 seconds on my machine..
//  
- (void) setBackgroundUsingFinder: (NSString*) file {
	OSErr err;
	AppleEvent ev = {typeNull, nil};
	AEAddressDesc addr = {typeNull, nil};
	OSType sig;
	NSURL *url;
	BOOL eventResent = NO;
	
	// Get a URL to later convert to an alias
	url = [NSURL fileURLWithPath: file];
	if (NULL == url)
		return;	
	
	// Create an address descriptor
	err = AECreateDesc (typeKernelProcessID, (char*)&mFinderPid, sizeof(pid_t), &addr);
	if (noErr == err) {
		// Create the event
		err = AECreateAppleEvent (kAECoreSuite, kAESetData, &addr, kAutoGenerateReturnID,
		kAnyTransactionID, &ev);
		AEDisposeDesc(&addr);
		if (noErr == err) {
			AEDesc containerObj = {typeNull, nil};
			AEDesc myDesc = {typeNull, nil};
			AEDesc cmonDesc = {typeNull, nil};
			AEDesc propertyObject = {typeNull, nil};
			
			long displaysIndex = 1; 
			err = AECreateDesc(typeSInt32, &displaysIndex, sizeof(long), &myDesc);
			if (noErr == err) {
				AEDisposeDesc(&myDesc);
				
				if (noErr == err) {
					// create the picture description
					sig = typeDesktopPicture;
					err = AECreateDesc(typeType, &sig, sizeof(OSType), &myDesc);
					if (noErr == err) {      // if it worked
						err = CreateObjSpecifier(typeProperty,&cmonDesc,formPropertyID,&myDesc,FALSE,&propertyObject);
						if (cmonDesc.dataHandle) AEDisposeDesc(&cmonDesc);
						AEDisposeDesc(&myDesc);
					}
				}
			}
			
			if (noErr == err) {
				// add the picture desc to the event
				err = AEPutParamDesc(&ev, keyDirectObject, &propertyObject);
				AEDisposeDesc(&propertyObject); // Always dispose ASAP
				
				if (noErr == err) {
					AEDesc tAEObject = {typeNull, nil};
					
					// convert the file url to an alias descriptor
					err = AEHelperCoerceNSURL (url, typeAlias, &tAEObject);
					if (noErr == err) {
						// put the alias descriptor into the event
						err = AEPutParamDesc(&ev, keyAEData, &tAEObject);
						AEDisposeDesc(&tAEObject);
						if (noErr == err) {
							// Finally, send the event - There seems to be a bug with
							// this call, in that it continually spins the CPU trying
							// to send the event, so we provide a short timeout
							// (kAEDefaultTimeout == 1min).
							err = AESendMessage (&ev, NULL, kAENoReply, FINDER_AE_TIMEOUT);
							
							// procNotFound will be returned on 10.2, but 10.1 will just timeout
							if ((errAETimeout == err/*-1712*/ || procNotFound == err/*-600*/) && NO == eventResent) {
								[self updateMode]; 
							}
						}
					} else {
						err = 0;
					}
				}
			}
			
			AEDisposeDesc(&ev);
		}
	}
}

- (NSString*) backgroundUsingFinder {
	return nil; 
}

#pragma mark -
// 
// Based on an implementation by Brian Bergstrand, Copyright 2001-2004  
// 
- (void) setBackgroundUsingPList: (NSString*) file {
	NSMutableDictionary*	rootDictionary		= nil; 
	NSMutableDictionary*	bkgdDictionary		= nil;
	NSMutableDictionary*	screenDictionary	= nil; 
	NSArray*				screenKeys			= nil;
	
	NSUserDefaults* userDefaults = [[[NSUserDefaults alloc] init] autorelease];
	
	NSString*	mkey;
	NSString*	tmp;
	
	int i, j;
	BOOL done = NO;
	
	// Get the desktop root dict
	rootDictionary = [[[userDefaults persistentDomainForName: VTBackgroundHelperPListDomainName] mutableCopyWithZone: nil] autorelease];
	if (rootDictionary == nil)
		return; 
	
	bkgdDictionary = [[[rootDictionary objectForKey: VTBackgroundHelperPListDesktopName] mutableCopyWithZone: nil] autorelease];
	
	// Get an array of the monitor keys
	screenKeys = [bkgdDictionary allKeys];
	if (screenKeys == nil)
		return; 
	
	done = YES;
	
	NSEnumerator*	screenKeyIter	= [screenKeys objectEnumerator]; 
	NSString*		screenKey		= nil; 
	
	AliasHandle		fileAlias; 
	NSData*			fileAliasData = nil; 
	
	fileAlias		= [[NSFileManager defaultManager] makeAlias: file];
	fileAliasData	= [[NSData alloc] initWithBytes: (void*)*fileAlias length: GetHandleSize((Handle)fileAlias)];
	
	while (screenKey = [screenKeyIter nextObject]) {
		screenDictionary = [[bkgdDictionary objectForKey: screenKey] mutableCopyWithZone: nil]; 
		
		// we are going to change the ImageFilePath and ImageFileAlias entries in there 
		[screenDictionary setObject: file forKey: @"ImageFilePath"]; 
		[screenDictionary setObject: fileAliasData forKey: @"ImageFileAlias"]; 
		
		[bkgdDictionary setObject: screenDictionary forKey: screenKey]; 
		// and get rid of this instance 
		[screenDictionary release]; 
	}
	
	// kill data 
	[fileAliasData release]; 
	// kill handle 
	DisposeHandle((Handle)fileAlias);
	
	// Replace with the modified dict
	[rootDictionary setObject: bkgdDictionary forKey: VTBackgroundHelperPListDesktopName];
	
	// Update the desktop domain on disk
	[userDefaults removePersistentDomainForName: VTBackgroundHelperPListDomainName];
	[userDefaults setPersistentDomain: rootDictionary forName: VTBackgroundHelperPListDomainName];
	[userDefaults synchronize];
	
	// Plus we have to send a nice notification so clients know that we changed
	// the desktop plist file so they update themselves 
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName: VTBackgroundHelperDesktopChangedName object: VTBackgroundHelperDesktopChangedObject userInfo: nil];	
}

- (NSString*) backgroundUsingPList {
	// fetch the entry from the plist file from the default screen 
	NSDictionary*	rootDictionary		= nil; 
	NSDictionary*	bkgdDictionary		= nil;
	NSDictionary*	screenDictionary	= nil; 
	
	NSUserDefaults* userDefaults		= [[[NSUserDefaults alloc] init] autorelease];
	[userDefaults synchronize]; 
	
	// Get the desktop root dict
	rootDictionary = [userDefaults persistentDomainForName: VTBackgroundHelperPListDomainName];
	if (rootDictionary == nil)
		return nil; 
	
	// Background dict 
	bkgdDictionary = [rootDictionary objectForKey: VTBackgroundHelperPListDesktopName];
	
	// now the screen dict 
	screenDictionary = [bkgdDictionary objectForKey: VTBackgroundHelperPListDefaultScreenName]; 
	// if we did not find it, return 
	if (screenDictionary == nil)
		return nil; 
	
	return [screenDictionary objectForKey: @"ImageFilePath"]; 
}


@end 

#pragma mark -

#import <stdlib.h>
#import <stdarg.h>
#import <unistd.h>
#import <sys/errno.h>
#import <sys/sysctl.h>

// 
// Brian Bergstrand, Copyright 2001-2004
//  
// Culled from examples in TN2022 - The Death of FSSpec
//<http://developer.apple.com/technotes/tn/tn2022.html>
OSStatus AEHelperCoerceNSURL (NSURL *furl, DescType toType, AEDesc *result)
{
	OSStatus err = noErr;
	CFURLRef url;
	FSRef        ref;
	FSSpec spec;
	AliasHandle  alias;
	
	url = (CFURLRef)furl; // we don't own this, so don't release it
	
	switch(toType){
	case cFile:
	case typeFSRef: 
	case typeFSS: 
	case typeAlias:
		
		if (CFURLGetFSRef(url, &ref)) {
			switch (toType) {
			case typeFSRef:
				err = AECreateDesc(typeFSRef, &ref, sizeof(FSRef), result);
				break;
				
			case cFile:
			case typeFSS:
				err = FSGetCatalogInfo(&ref, kFSCatInfoNone, NULL, NULL, &spec, NULL);
				if (noErr == err)
					err = AECreateDesc(typeFSS, &spec, sizeof(FSSpec), result);
				break;
				
			case typeAlias:
				err = FSNewAliasMinimal(&ref, &alias);
				if (noErr == err) {
					// HLock((Handle)alias); // not needed on X
					err = AECreateDesc(typeAlias, *alias, GetHandleSize((Handle)alias), result);
					// HUnlock((Handle)alias); // ditto
					DisposeHandle((Handle)alias);
				}
				break;
			}
		} else {
			err = coreFoundationUnknownErr;
		}
		break;
		
	default:
		break;
	}
	
	return err;
}

/*
 * Copyright 2001-2004 Brian Bergstrand.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *
 * 1.  Redistributions of source code must retain the above copyright notice, this list of
 *     conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright notice, this list of
 *     conditions and the following disclaimer in the documentation and/or other materials provided
 *     with the distribution.
 * 3.  The name of the author may not be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */  