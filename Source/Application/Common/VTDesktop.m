/******************************************************************************
 *
 * VirtueDesktops framework
 *
 * Copyright 2004, Thomas Staller playback@users.sourceforge.net
 * Copyright 2007, Tony Arnold tony@tonyarnold.com
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

#define kVtCodingShowsBackgroundImage     @"showsBackground"
#define kVtCodingName                     @"name"
#define kVtCodingBackgroundImage          @"backgroundImage"
#define kVtCodingDefaultBackgroundImage   @"usesDefaultBackgroundImage"
#define kVtCodingDecoration               @"decoration"
#define kVtCodingUUID                     @"UUID"
#define kVtCodingColorLabel               @"colorLabel"

#pragma mark -
@implementation VTDesktop

#pragma mark -
#pragma mark Lifetime

+ (id) desktopWithIdentifier: (int) identifier {
	return [[VTDesktop desktopWithName: nil identifier: identifier] autorelease];
}

+ (id) desktopWithName: (NSString*) name identifier: (int) identifier {
	return [[[VTDesktop alloc] initWithName: name identifier: identifier] autorelease];
}

#pragma mark -
- (id) initWithName: (NSString*) name identifier: (int) identifier {
	if (self = [super initWithId: identifier andName: name]) {
		mDesktopBackgroundImagePath = nil;
		mDecoration                 = [[VTDesktopDecoration alloc] initWithDesktop: self];
		mUUID                       = [NSString stringWithUUID];
		mShowsBackground            = NO;
		
		return self;
	}
	
	return nil;
}

- (void) dealloc {
	ZEN_RELEASE(mDesktopBackgroundImagePath);
	ZEN_RELEASE(mUUID);
	ZEN_RELEASE(mDecoration);
	
	[super dealloc];
}

#pragma mark -
#pragma mark Coding

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init]) {
		[self setShowsBackground: [coder decodeBoolForKey: kVtCodingShowsBackgroundImage]];
		
		if ([self showsBackground])
			[self setDesktopBackground: [coder decodeObjectForKey: kVtCodingBackgroundImage]];
		
		[self setName: [coder decodeObjectForKey: kVtCodingName]];
		mDecoration = [[coder decodeObjectForKey: kVtCodingDecoration] retain];
    mColorLabel = [[coder decodeObjectForKey: kVtCodingColorLabel] retain];
		
		return self;
	}
	
	return nil;
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeBool: [self showsBackground] forKey: kVtCodingShowsBackgroundImage];
	
	if ([self showsBackground])
		[coder encodeObject: [self desktopBackground] forKey: kVtCodingBackgroundImage];
	
	[coder encodeObject: mDecoration forKey: kVtCodingDecoration];
	[coder encodeObject: [self name] forKey: kVtCodingName];
  [coder encodeObject: mColorLabel forKey: kVtCodingColorLabel];
}

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	if ([self showsBackground] && [self desktopBackground])
		[dictionary setObject: [self desktopBackground] forKey: kVtCodingBackgroundImage];
	
	[dictionary setObject: [NSNumber numberWithBool: [self showsBackground]] forKey: kVtCodingShowsBackgroundImage];
	[dictionary setObject: [self name] forKey: kVtCodingName];
	[dictionary setObject: [self uuid] forKey: kVtCodingUUID];
	
	if ([self colorLabel])
		[dictionary setObject: [mColorLabel stringValue] forKey: kVtCodingColorLabel];
	
	NSMutableDictionary* decoration = [NSMutableDictionary dictionary];
	[mDecoration encodeToDictionary: decoration];
	
	if (decoration)
		[dictionary setObject: decoration forKey: kVtCodingDecoration];
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
  [self setName: [dictionary objectForKey: kVtCodingName]];
	[self setShowsBackground: [[dictionary objectForKey: kVtCodingShowsBackgroundImage] boolValue]];

	if ([self showsBackground]) {
		[self setDesktopBackground: [dictionary objectForKey: kVtCodingBackgroundImage]];
	}
	
  NSString *uuidString = [NSString stringWithString: [dictionary objectForKey: kVtCodingUUID]];
  if (mUUID)
    mUUID = [uuidString retain];
  
	NSColor* colorData	= [NSColor colorWithString: [dictionary objectForKey: kVtCodingColorLabel]];
  
	if (colorData)
		mColorLabel = [colorData retain];
	
	// ensure an UUID
	if ((mUUID == nil) || ([mUUID length] == 0))
		mUUID = [NSString stringWithUUID];
	
	// now the decoration
	[mDecoration decodeFromDictionary: [dictionary objectForKey: kVtCodingDecoration]];
	
	return self;
}

#pragma mark -
#pragma mark Attributes

- (void) setDesktopBackground: (NSString*) path {
	if ([self showsBackground] == NO || path == nil)
		return;
	
	ZEN_ASSIGN_COPY(mDesktopBackgroundImagePath, path);
}

- (NSString*) desktopBackground {
	if (mDesktopBackgroundImagePath == nil) {
		ZEN_ASSIGN_COPY(mDesktopBackgroundImagePath, [[VTDesktopBackgroundHelper sharedInstance] defaultBackground]);
	}
	
	return mDesktopBackgroundImagePath;
}

- (void) setDefaultDesktopBackgroundIfNeeded: (NSString*) path {
	if ( ([self showsBackground] == YES) || path == nil )
		return;
	
	ZEN_ASSIGN_COPY(mDesktopBackgroundImagePath, path);
}

#pragma mark -

- (void) setShowsBackground: (BOOL) showsBackground {
	mShowsBackground = showsBackground;
	[self applyDesktopBackground];
}

- (BOOL) showsBackground {
	return mShowsBackground;
}

#pragma mark -
- (VTDesktopDecoration*) decoration {
	return [[mDecoration retain] autorelease];
}

#pragma mark -
- (void) setName: (NSString*) name {
	// reject if name is empty or nil, or if we already have a name like the one provided
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
	return [[mColorLabel copy] autorelease];
}

#pragma mark -
#pragma mark Desktop background

- (void) applyDesktopBackground {
	if ([self showsBackground]) {
		[[VTDesktopBackgroundHelper sharedInstance] setBackground: [self desktopBackground]];
	} else {
    [[VTDesktopBackgroundHelper sharedInstance] setBackground: [[VTDesktopBackgroundHelper sharedInstance] defaultBackground]];
	}
}

@end