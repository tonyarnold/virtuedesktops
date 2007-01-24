//
//  VTFileSystemExtensions.m
//  VirtueDesktops
//
//  Created by Tony on 2/09/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#import "VTFileSystemExtensions.h"


@implementation VTFileSystemExtensions
+ (NSString *)preferencesFolder {
	NSString *preferencesFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder(kUserDomain, kPreferencesFolderType, kDontCreateFolder, &foundRef);
	if (err != noErr) {
		NSRunAlertPanel(@"Alert", @"Can't find preferences folder", @"Quit", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	} else {
		unsigned char path[PATH_MAX];
		FSRefMakePath(&foundRef, path, sizeof(path));
		preferencesFolder = [NSString stringWithUTF8String:(char *)path];
	}
	return preferencesFolder;
}

+ (NSString *)applicationSupportFolder {
	NSString *applicationSupportFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
	if (err != noErr) {
		NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	} else {
		unsigned char path[PATH_MAX];
		FSRefMakePath(&foundRef, path, sizeof(path));
		applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
		applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:[NSString stringWithFormat: @"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]]];
	}
	return applicationSupportFolder;
}

+ (NSString *)globalApplicationSupportFolder {
	NSString *applicationSupportFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder(kLocalDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
	if (err != noErr) {
		NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	} else {
		unsigned char path[PATH_MAX];
		FSRefMakePath(&foundRef, path, sizeof(path));
		applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
		applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:[NSString stringWithFormat: @"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]]];
	}
	return applicationSupportFolder;
}


@end
