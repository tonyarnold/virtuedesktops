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

#define kVtCodingName											@"name"
#define kVtCodingBackgroundImage					@"backgroundImage"
#define kVtCodingDefaultBackgroundImage		@"usesDefaultBackgroundImage"
#define kVtCodingDecoration								@"decoration" 
#define kVtCodingUUID											@"UUID"
#define kVtCodingColorLabel								@"colorLabel"

#pragma mark -
@implementation VTDesktop

#pragma mark -
#pragma mark Lifetime 

+ (id) desktopWithIdentifier: (int) identifier {
	return [VTDesktop desktopWithName: nil identifier: identifier]; 
}

+ (id) desktopWithName: (NSString*) name identifier: (int) identifier {
	return [[[VTDesktop alloc] initWithName: name identifier: identifier] autorelease]; 
}

#pragma mark -
- (id) initWithName: (NSString*) name identifier: (int) identifier {
	if (self = [super initWithId: identifier andName: name]) {
		mDesktopBackgroundImagePath					= nil;
		mDefaultDesktopBackgroundImagePath	= nil;
		mDecoration													= [[VTDesktopDecoration alloc] initWithDesktop: self]; 
		mUUID																= [[ZNUUID uuid] retain];
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mDesktopBackgroundImagePath);
	ZEN_RELEASE(mDefaultDesktopBackgroundImagePath);
	ZEN_RELEASE(mUUID);
	ZEN_RELEASE(mDecoration);
	
	[super dealloc];
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init]) {
		if ([coder decodeBoolForKey: kVtCodingDefaultBackgroundImage] == FALSE)
			[self setDesktopBackground: [coder decodeObjectForKey: kVtCodingBackgroundImage]];
		else
			[self setDesktopBackground: mDefaultDesktopBackgroundImagePath];
		
		[self setName: [coder decodeObjectForKey: kVtCodingName]];
		mDecoration = [[coder decodeObjectForKey: kVtCodingDecoration] retain];
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeBool: [self showsDefaultBackground] forKey: kVtCodingDefaultBackgroundImage];
	[coder encodeObject: mDesktopBackgroundImagePath forKey: kVtCodingBackgroundImage];
	[coder encodeObject: mDecoration forKey: kVtCodingDecoration];
	[coder encodeObject: [self name] forKey: kVtCodingName];
}

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	if ([self showsDefaultBackground] == FALSE && [self showsBackground])
		[dictionary setObject: mDesktopBackgroundImagePath forKey: kVtCodingBackgroundImage];
		
	[dictionary setObject: [NSNumber numberWithBool: [self showsDefaultBackground]] forKey: kVtCodingDefaultBackgroundImage];
	[dictionary setObject: [self name] forKey: kVtCodingName];
	[dictionary setObject: mUUID forKey: kVtCodingUUID]; 
	
	if (mColorLabel)
		[dictionary setObject: [mColorLabel stringValue] forKey: kVtCodingColorLabel]; 
	
	NSMutableDictionary* decoration = [NSMutableDictionary dictionary]; 
	[mDecoration encodeToDictionary: decoration]; 
	[dictionary setObject: decoration forKey: kVtCodingDecoration]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	NSNumber *mUseDefaultBG = [[dictionary objectForKey: kVtCodingDefaultBackgroundImage] copy];
	if ([mUseDefaultBG boolValue] == YES) {
		mDesktopBackgroundImagePath = [self defaultDesktopBackgroundPath];
	} else {
		mDesktopBackgroundImagePath = [[dictionary objectForKey: kVtCodingBackgroundImage] copy];
	}
	
	mUUID												= [[dictionary objectForKey: kVtCodingUUID] copy];
	NSColor* colorData					= [NSColor colorWithString: [dictionary objectForKey: kVtCodingColorLabel]];
	
	[self setName: [dictionary objectForKey: kVtCodingName]];
	
	if (colorData) 
		mColorLabel = [colorData retain]; 
	
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
	ZEN_ASSIGN_COPY(mDesktopBackgroundImagePath, path);
}

- (NSString*) desktopBackground {
	return mDesktopBackgroundImagePath;
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
	return (nil != mDesktopBackgroundImagePath && [mDesktopBackgroundImagePath length] > 1);
}

- (BOOL) showsDefaultBackground {
	return [mDesktopBackgroundImagePath isEqualToString: mDefaultDesktopBackgroundImagePath];
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
	
	// now set the name 
	[super setName: name]; 
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
#pragma mark Desktop background 

- (void) applyDesktopBackground {
	[[VTDesktopBackgroundHelper sharedInstance] setBackground: mDesktopBackgroundImagePath];
}

- (void) applyDefaultDesktopBackground {
	[[VTDesktopBackgroundHelper sharedInstance] setBackground: mDefaultDesktopBackgroundImagePath]; 
}

#pragma mark -
#pragma mark Class methods 

+ (NSString*) currentDesktopBackground {
	return [[VTDesktopBackgroundHelper sharedInstance] background]; 
}

@end