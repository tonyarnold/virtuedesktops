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
#import "VTDesktop.h" 
#import "VTDesktopController.h" 
#import "VTDesktopDecorationController.h" 
#import "VTDesktopBackgroundHelper.h" 
#import "NSColorString.h" 
#import <Zen/Zen.h> 

#define kVtCodingName									@"name"
#define kVtCodingBackgroundImage			@"backgroundImage"
#define kVtCodingDecoration						@"decoration" 
#define kVtCodingUUID									@"UUID"
#define kVtCodingColorLabel						@"colorLabel"

#pragma mark -
@interface VTDesktop(Private) 
- (NSString*) virtualDesktopMetadataPath; 
@end 


#pragma mark -
@implementation VTDesktop

#pragma mark -
#pragma mark Lifetime 

+ (id) desktopWithIdentifier: (int) identifier {
	return [VTDesktop desktopWithName: nil identifier: identifier]; 
}

+ (id) desktopWithName: (NSString*) name identifier: (int) identifier {
	// create desktop 
	return [[[VTDesktop alloc] initWithName: name identifier: identifier] autorelease]; 
}

#pragma mark -
- (id) initWithName: (NSString*) name identifier: (int) identifier {
	if (self = [super initWithId: identifier andName: name]) {
		// Attributes 
		mDesktopBackgroundImagePath = nil;
		mManagesIconset							= NO;
		mShowsBackground						= NO;	
		mDecoration									= [[VTDesktopDecoration alloc] initWithDesktop: self]; 
		mUUID												= [[ZNUUID uuid] retain]; 
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// Attributes
	ZEN_RELEASE(mDesktopBackgroundImagePath);
	ZEN_RELEASE(mDefaultDesktopBackgroundImagePath);
	ZEN_RELEASE(mUUID);
	
	// decoration
	ZEN_RELEASE(mDecoration);
	
	[super dealloc];
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init]) {
		[self setName: [coder decodeObjectForKey: kVtCodingName]];
		if ([coder decodeObjectForKey: kVtCodingBackgroundImage] != nil)
			[self setDesktopBackground: [coder decodeObjectForKey: kVtCodingBackgroundImage]];
		
		mDecoration = [[coder decodeObjectForKey: kVtCodingDecoration] retain];
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeObject: mDesktopBackgroundImagePath forKey: kVtCodingBackgroundImage];
	[coder encodeObject: mDecoration forKey: kVtCodingDecoration];
	[coder encodeObject: [self name] forKey: kVtCodingName];
}

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	
	[dictionary setObject: [self name] forKey: kVtCodingName];
	
	if (mDesktopBackgroundImagePath && mDesktopBackgroundImagePath != mDefaultDesktopBackgroundImagePath)
		[dictionary setObject: mDesktopBackgroundImagePath forKey: kVtCodingBackgroundImage];
	else
		[dictionary setObject: nil forKey: kVtCodingBackgroundImage];
	
	[dictionary setObject: mUUID forKey: kVtCodingUUID]; 
	
	
	if (mColorLabel)
		[dictionary setObject: [NSArchiver archivedDataWithRootObject: mColorLabel] forKey: kVtCodingColorLabel]; 
	
	NSMutableDictionary* decoration = [NSMutableDictionary dictionary]; 
	[mDecoration encodeToDictionary: decoration]; 
	[dictionary setObject: decoration forKey: kVtCodingDecoration]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	[self setDefaultDesktopBackgroundPath: [[VTDesktopBackgroundHelper sharedInstance] background]];
	
	if ([dictionary objectForKey: kVtCodingBackgroundImage])
		mDesktopBackgroundImagePath = [[dictionary objectForKey: kVtCodingBackgroundImage] copy];
	else
		mDesktopBackgroundImagePath = mDefaultDesktopBackgroundImagePath;
			
	
	mUUID									= [[dictionary objectForKey: kVtCodingUUID] copy];
	NSData* colorData			= [dictionary objectForKey: kVtCodingColorLabel];
	[self setName: [dictionary objectForKey: kVtCodingName]];
	
	if (colorData) 
		mColorLabel = (NSColor*)[[NSUnarchiver unarchiveObjectWithData: colorData] retain]; 
	
	// ensure an UUID 
	if ((mUUID == nil) || ([mUUID length] == 0)) 
		mUUID = [[ZNUUID uuid] retain]; 
	
	// now the decoration 
	[mDecoration decodeFromDictionary: [dictionary objectForKey: kVtCodingDecoration]]; 
	
	return self; 
}

#pragma mark -
#pragma mark Attributes 

- (void) setDesktopBackground: (NSString*) path {
	if (path != nil)
		ZEN_ASSIGN_COPY(mDesktopBackgroundImagePath, path);
}

- (NSString*) desktopBackground {
	if (mDesktopBackgroundImagePath != nil && ![mDesktopBackgroundImagePath isEqualToString:@""]) {
		return mDesktopBackgroundImagePath;
	}
	else
	{
		return mDefaultDesktopBackgroundImagePath;
	}
}

#pragma mark -

- (void) setDefaultDesktopBackgroundPath: (NSString*) path {
	ZEN_ASSIGN_COPY(mDefaultDesktopBackgroundImagePath, path); 
	
	if (mDesktopBackgroundImagePath == nil)
		[self setDesktopBackground: path];
}

- (NSString*) defaultDesktopBackgroundPath {
	return mDefaultDesktopBackgroundImagePath;
}

- (BOOL) showsBackground {
	return ([self desktopBackground] != nil);
}

#pragma mark -
- (VTDesktopDecoration*) decoration {
	return mDecoration; 
}

#pragma mark -
- (void) setName: (NSString*) name {
	// reject if name is empty or nil, or if we already have a name like the 
	// one provided 
	if ((name == nil) || ([name length] == 0))
		return; 
	
	// take care of renaming the desktop directory to the new desktop name 
	NSString* oldNamePath = [VTDesktop virtualDesktopPath: self]; 

	// now set the name 
	[super setName: name]; 
	
	NSString* newNamePath = [VTDesktop virtualDesktopPath: self]; 
	
	// now rename 
	[[NSFileManager defaultManager] movePath: oldNamePath toPath: newNamePath handler: nil]; 
}

#pragma mark -
- (NSString*) uuid {
	return mUUID; 
}

#pragma mark -
- (void) setColorLabel: (NSColor*) color {
	ZEN_ASSIGN(mColorLabel, color); 
}

- (NSColor*) colorLabel {
	return mColorLabel; 
}

#pragma mark -
#pragma mark Persistency 

- (void) attachToDisk {
	// first check for our directory, we expect the container to exist
	NSString* virtualDesktopPath = [VTDesktop virtualDesktopPath: self]; 
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: virtualDesktopPath] == NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath: virtualDesktopPath attributes: nil];
	}
}

- (void) detachFromDisk {
	// we will remove the directory and be gone 
	NSString* virtualDesktopPath = [VTDesktop virtualDesktopPath: self]; 
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: virtualDesktopPath] == YES) {
		[[NSFileManager defaultManager] removeFileAtPath: virtualDesktopPath handler: nil]; 
	}
}


#pragma mark -
#pragma mark Iconset

- (void) showIconset {
	// we are doing this by linking our contents to the main desktop directory, we won't refresh
	// but rely on the caller to trigger the update 

	NSString* virtualDesktopPath	= [VTDesktop virtualDesktopPath: self]; 
	NSString* desktopPath			= [VTDesktop desktopContainerPath];
	
	// all files in our virtual desktop directory 
	NSArray*  virtualDesktopFiles	= [[NSFileManager defaultManager] directoryContentsAtPath: virtualDesktopPath]; 

	NSEnumerator*	desktopFileIter	= [virtualDesktopFiles objectEnumerator]; 
	NSString*		desktopFile		= nil; 
	
	while (desktopFile = [desktopFileIter nextObject]) {
		NSString* targetPath = [desktopPath stringByAppendingPathComponent: desktopFile]; 
	
		// ignoring some special files 
		if ([desktopFile hasPrefix: @"."] || [desktopFile hasSuffix: @"\r"])
			continue; 
		
		[[NSFileManager defaultManager] createSymbolicLinkAtPath: targetPath 
																								 pathContent: [virtualDesktopPath stringByAppendingPathComponent: desktopFile]]; 
	}
}

- (void) hideIconset {
	// we are doing this by unlinking our contents from the main desktop directory, we won't refresh
	// but rely on the caller to trigger the update. we will only touch files, that are contained in 
	// our virtual desktop directory, currently we will miss files that were deleted from there before 
	// we switched. we should work around that by remembering which files we linked into the directory. 
	
	NSString* virtualDesktopPath	= [VTDesktop virtualDesktopPath: self]; 
	NSString* desktopPath					= [VTDesktop desktopContainerPath];
	
	// all files in our virtual desktop directory 
	NSArray*  virtualDesktopFiles	= [[NSFileManager defaultManager] directoryContentsAtPath: virtualDesktopPath]; 
	
	NSEnumerator*	desktopFileIter	= [virtualDesktopFiles objectEnumerator]; 
	NSString*			desktopFile			= nil; 
	
	while (desktopFile = [desktopFileIter nextObject]) {
		NSString* targetPath = [desktopPath stringByAppendingPathComponent: desktopFile]; 

		// ignoring some special files 
		if ([desktopFile hasPrefix: @"."] || [desktopFile hasSuffix: @"\r"])
			continue; 
		
		// unlink in our file if it exists 
		if ([[NSFileManager defaultManager] fileExistsAtPath: targetPath])
			[[NSFileManager defaultManager] removeFileAtPath: targetPath handler: nil]; 
	}	
}


#pragma mark -
#pragma mark Desktop background 

- (void) applyDesktopBackground {
	[[VTDesktopBackgroundHelper sharedInstance] setBackground: mDesktopBackgroundImagePath]; 
}

- (void) applyDefaultDesktopBackground {
	[[VTDesktopBackgroundHelper sharedInstance] setBackground: mDefaultDesktopBackgroundImagePath]; 
}

#pragma mark -
#pragma mark Class methods 

+ (void) updateDesktopPath {
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged: [VTDesktop desktopContainerPath]]; 
}

+ (NSString*) virtualDesktopContainerPath {
	NSString* homeDirectory = NSHomeDirectory(); 
	// check for symlinks and traverse them in advance 
	NSDictionary* fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: homeDirectory traverseLink: NO]; 
	if ([[fileAttributes fileType] isEqualToString: NSFileTypeSymbolicLink]) 
		homeDirectory = [[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath: homeDirectory]; 
		
	return [homeDirectory stringByAppendingPathComponent: @"Library/Application Support/Virtue/Desktops"]; 
}

+ (NSString*) virtualDesktopPath: (VTDesktop*) desktop {
	return [[VTDesktop virtualDesktopContainerPath] stringByAppendingPathComponent: [desktop name]]; 
}

+ (NSString*) virtualDesktopMetadataName {
	return @".desktop.plist"; 
}

+ (NSString*) desktopContainerPath {
	NSString* homeDirectory = NSHomeDirectory(); 
	// check for symlinks and traverse them in advance 
	NSDictionary* fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: homeDirectory traverseLink: NO]; 
	if ([[fileAttributes fileType] isEqualToString: NSFileTypeSymbolicLink]) 
		homeDirectory = [[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath: homeDirectory]; 

	return [homeDirectory stringByAppendingPathComponent: @"Desktop"]; 
}

+ (NSString*) currentDesktopBackground {
	return [[VTDesktopBackgroundHelper sharedInstance] background]; 
}


@end

#pragma mark -
@implementation VTDesktop(Private) 

- (NSString*) virtualDesktopMetadataPath {
	return [[VTDesktop virtualDesktopPath: self] stringByAppendingPathComponent: [VTDesktop virtualDesktopMetadataName]]; 
}

@end 