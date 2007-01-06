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

#import "VTDecorationPrimitive.h"
#import "VTDesktopDecoration.h" 
#import <Zen/Zen.h>

#define kVtCodingContainer			@"container"
#define kVtCodingEnabled			@"enabled"
#define kVtCodingName				@"name"
#define kVtCodingPosition			@"position"
#define kVtCodingPositionType		@"positionType"

#pragma mark -
@implementation VTDecorationPrimitive

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// attributes 
		mName = @"Decoration Primitive"; 
		
		mControlView	= nil; 
		mEnabled		= YES; 
		mPosition		= NSMakePoint(0, 0); 
		mPositionType	= kVtDecorationPositionAbsolute; 
		mContainer		= nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mName); 
	ZEN_RELEASE(mControlView); 
	ZEN_RELEASE(mContainer); 
	
	[super dealloc]; 
}

- (id) copyWithZone: (NSZone*) zone {
	VTDecorationPrimitive* newInstance = [[[self class] allocWithZone: zone] init]; 
	// and initialize 
	newInstance->mName					= [mName copyWithZone: zone]; 
	newInstance->mControlView		= nil; 
	newInstance->mContainer			= nil; 
	newInstance->mPosition			= mPosition; 
	newInstance->mPositionType	= mPositionType; 
	
	return newInstance; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init]) {
		mContainer		= [[coder decodeObjectForKey: kVtCodingContainer] retain]; 
		mName			= [[coder decodeObjectForKey: kVtCodingName] retain];
		mPosition		= [coder decodePointForKey: kVtCodingPosition]; 
		mPositionType	= [coder decodeIntForKey: kVtCodingPositionType]; 
		mEnabled		= [coder decodeBoolForKey: kVtCodingEnabled]; 
		
		mControlView	= nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeObject: mContainer forKey: kVtCodingContainer]; 
	[coder encodeObject: mName forKey: kVtCodingName]; 
	[coder encodePoint: mPosition forKey: kVtCodingPosition]; 
	[coder encodeInt: mPositionType forKey: kVtCodingPositionType]; 
	[coder encodeBool: mEnabled forKey: kVtCodingEnabled]; 
}

#pragma mark -

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[dictionary setObject: mName forKey: kVtCodingName]; 
	[dictionary setObject: NSStringFromPoint(mPosition) forKey: kVtCodingPosition]; 
	[dictionary setObject: [NSNumber numberWithBool: mEnabled] forKey: kVtCodingEnabled]; 
	[dictionary setObject: [NSNumber numberWithInt: mPositionType] forKey: kVtCodingPositionType]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	mName         = [[dictionary objectForKey: kVtCodingName] copy]; 
	mPosition     = NSPointFromString([dictionary objectForKey: kVtCodingPosition]); 
	mPositionType	= [[dictionary objectForKey: kVtCodingPositionType] intValue]; 
	mEnabled      = [[dictionary objectForKey: kVtCodingEnabled] boolValue]; 
	
	return self; 
}

#pragma mark -
#pragma mark Attributes 

- (void) setName: (NSString*) name {
	
	ZEN_ASSIGN_COPY(mName, name); 
}

- (NSString*) name {
	return mName; 
}

#pragma mark -
- (void) setContainer: (VTDesktopDecoration*) container {
	ZEN_ASSIGN(mContainer, container); 
}

- (VTDesktopDecoration*) container {
	return mContainer; 
}

#pragma mark -
- (void) setPosition: (NSPoint) position {
	mPosition = position; 
	
	[self setNeedsDisplay]; 
}

- (NSPoint) position {
	return mPosition; 
}

#pragma mark -
- (void) setPositionType: (VTDecorationPosition) positionType {
	mPositionType = positionType; 
	
	[self setNeedsDisplay]; 
}

- (VTDecorationPosition) positionType {
	return mPositionType; 
}

- (NSArray*) supportedPositionTypes {
	// support nothing per default 
	return nil; 
}


#pragma mark -
- (NSView*) controlView {
	return mControlView; 
}

- (void) setControlView: (NSView*) view {
	ZEN_ASSIGN(mControlView, view); 
}

#pragma mark -
- (BOOL) shouldDraw {
	return mEnabled; 
}

- (BOOL) isEnabled {
	return mEnabled; 
}

- (void) setEnabled: (BOOL) flag {
	mEnabled = flag; 
	
	[self setNeedsDisplay]; 
}


#pragma mark -
- (NSRect) bounds {
	return NSMakeRect(0, 0, 0, 0); 
}


#pragma mark -
#pragma mark Drawing 

- (void) drawInView: (NSView*) view withRect: (NSRect) rect { 
	// Default implementation does not do anything
}

- (void) setNeedsDisplay {
	// no view, no drawing 
	if (mControlView == nil)
		return; 
  
	// invalidate our bounds 
	[mControlView setNeedsDisplay: YES]; 
}


@end
