/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDesktopDecoration.h"
#import "VTDesktop.h" 
#import <Zen/ZNMemoryManagementMacros.h>

#pragma mark Coding Keys 
#define kVtCodingPrimitives			@"primitives"
#define kVtCodingDesktop				@"desktop"
#define kVtCodingEnabled				@"enabled"
#define kVtCodingPrimitiveType	@"type"

#pragma mark -
@interface VTDesktopDecoration(KVOCompliance) 
- (void) insertPrimitive: (VTDecorationPrimitive*) primitive atIndex: (unsigned int) index; 
- (void) removePrimitiveAtIndex: (unsigned int) index; 
@end 

#pragma mark -
@implementation VTDesktopDecoration

#pragma mark -
#pragma mark Lifetime 

- (id) initWithDesktop: (VTDesktop*) desktop {
	if (self = [super init]) {
		mDecorationPrimitives	= [[NSMutableArray alloc] init]; 
		mControlView          = nil; 
		mEnabled              = YES;
		
		ZEN_ASSIGN(mDesktop, desktop); 
				
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mDesktop); 
	ZEN_RELEASE(mControlView); 
	ZEN_RELEASE(mDecorationPrimitives); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init]) {
		// decode primitives 
		mControlView          = nil; 
		mDesktop              = [[coder decodeObjectForKey: kVtCodingDesktop] retain]; 
		mEnabled              = [coder decodeBoolForKey: kVtCodingEnabled]; 
		mDecorationPrimitives	= [[coder decodeObjectForKey: kVtCodingPrimitives] retain]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	// encode all our decoration primitives 
	[coder encodeObject: mDesktop forKey: kVtCodingDesktop]; 
	[coder encodeBool: mEnabled forKey: kVtCodingEnabled]; 
	[coder encodeObject: mDecorationPrimitives forKey: kVtCodingPrimitives]; 

}

#pragma mark -

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	// now assemble our primitive list 
	NSEnumerator*						primitiveIter	= [mDecorationPrimitives objectEnumerator]; 
	VTDecorationPrimitive*	primitive			= nil; 
	NSMutableArray*					primitiveList	= [NSMutableArray array]; 
	
	while (primitive = [primitiveIter nextObject]) {    
		// fetch the type of this primitive and persist it 
		NSMutableDictionary*	primitiveDict = [NSMutableDictionary dictionary]; 
		
		[primitiveDict setObject: NSStringFromClass([primitive class]) forKey: kVtCodingPrimitiveType];
		[primitive encodeToDictionary: primitiveDict]; 
		
		[primitiveList addObject: primitiveDict]; 
	}
	
	[dictionary setObject: [NSNumber numberWithBool: mEnabled] forKey: kVtCodingEnabled];
	[dictionary setObject: primitiveList forKey: kVtCodingPrimitives]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	// first we fetch our primitives 
	mEnabled = [[dictionary objectForKey: kVtCodingEnabled] boolValue]; 
	
	// now start decoding the list of primitives 
	NSArray* primitiveList = [dictionary objectForKey: kVtCodingPrimitives]; 
	if (primitiveList == nil)
		return self; 
	
	NSEnumerator*	primitiveIter	= [primitiveList objectEnumerator]; 
	NSDictionary*	primitiveDict	= nil; 
	
	while (primitiveDict = [primitiveIter nextObject]) {    
		// check type and try to create an instance of the primitive 
		NSString*	type	= [primitiveDict objectForKey: kVtCodingPrimitiveType]; 
		Class			primitiveClass	= NSClassFromString(type); 
		
		// if we do not know about this type, ignore it and go on to 
		// interpret the next entry 
		if (primitiveClass == nil)
			continue; 
		
		
		VTDecorationPrimitive* primitive = [[primitiveClass alloc] init]; 
		if (primitive == nil)
			continue; 
		
		[primitive decodeFromDictionary: primitiveDict]; 

		// now add the primitive to our list 
		[self addDecorationPrimitive: primitive]; 
	}
	
	return self; 
}

#pragma mark -
#pragma mark Attributes 

- (NSArray*) decorationPrimitives {
	return mDecorationPrimitives; 
}

- (void) addDecorationPrimitive: (VTDecorationPrimitive*) primitive {
	[self willChangeValueForKey: @"decorationPrimitives"]; 
	[self insertPrimitive: primitive atIndex: [mDecorationPrimitives count]]; 
	[self didChangeValueForKey: @"decorationPrimitives"]; 
}

- (void) delDecorationPrimitive: (VTDecorationPrimitive*) primitive {
	// remove from our container 
	[self willChangeValueForKey: @"decorationPrimitives"];
	[self removePrimitiveAtIndex: [mDecorationPrimitives indexOfObject: primitive]]; 
	[self didChangeValueForKey: @"decorationPrimitives"]; 
}

#pragma mark -
- (NSView*) controlView {
	return mControlView; 
}

- (void) setControlView: (NSView*) view {
	ZEN_ASSIGN(mControlView, view); 
	
	// and apply to all primitives 
	NSEnumerator*						decorationIter	= [mDecorationPrimitives objectEnumerator]; 
	VTDecorationPrimitive*	decoration			= nil; 
	
	while (decoration = [decorationIter nextObject])
		[decoration setControlView: mControlView]; 
}

#pragma mark -
- (BOOL) isEnabled {
	return mEnabled; 
}

- (void) setEnabled: (BOOL) flag {
	mEnabled = flag; 
	
	[mControlView setNeedsDisplay: YES]; 
}

#pragma mark -
- (VTDesktop*) desktop {
	return mDesktop; 
}

- (void) setDesktop: (VTDesktop*) desktop {
	ZEN_ASSIGN(mDesktop, desktop); 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawInView: (NSView*) view withRect: (NSRect) rect {
	// if we are disabled, return 
	if (mEnabled == NO)
		return; 
	
	// forward to primitives if they are enabled, we will not call drawing 
	// methods on a primitive if it is not enabled; we are drawing from the
	// end to the begin of the array 
	NSEnumerator*						primitiveIter	= [mDecorationPrimitives reverseObjectEnumerator]; 
	VTDecorationPrimitive*	primitive			= nil; 
	
	while (primitive = [primitiveIter nextObject]) {
		if ([primitive isEnabled])
			[primitive drawInView: view withRect: rect]; 
	}
}

#pragma mark -
#pragma mark Bindings 

- (void) insertObjectInDecorationPrimitives: (VTDecorationPrimitive*) primitive atIndex: (unsigned int) objIndex {
	[self insertPrimitive: primitive atIndex: objIndex]; 
}

- (void) insertIntoDecorationPrimitives: (VTDecorationPrimitive*) primitive atIndex: (unsigned int) objIndex {
	[self insertPrimitive: primitive atIndex: objIndex]; 
}

- (void) removeObjectFromDecorationPrimitivesAtIndex: (unsigned int) objIndex {
	[self removePrimitiveAtIndex: objIndex]; 
}

- (void) removeFromDecorationPrimitivesAtIndex: (unsigned int) objIndex {
	[self removePrimitiveAtIndex: objIndex]; 
}

- (void) moveObjectAtIndex: (unsigned int) objIndex toIndex: (unsigned int) otherIndex {
	// this is no vto compliant message, so we will have to do the notification ourselves 
	[self willChangeValueForKey: @"decorationPrimitives"]; 
	
	// get the object instance we move 
	VTDecorationPrimitive* primitiveToMove = [[mDecorationPrimitives objectAtIndex: objIndex] retain]; 
	
	// correct insertion index 
	if (objIndex < otherIndex)
		otherIndex--; 
	
	// remove and reinsert object
	[mDecorationPrimitives removeObjectAtIndex: objIndex]; 
	[mDecorationPrimitives insertObject: primitiveToMove atIndex: otherIndex]; 
	
	// and notify that we finished the move 
	[self didChangeValueForKey: @"decorationPrimitives"]; 
	
	// and update our control view 
	[mControlView setNeedsDisplay: YES];
}

@end

#pragma mark -
@implementation VTDesktopDecoration(Private) 

- (void) insertPrimitive: (VTDecorationPrimitive*) primitive atIndex: (unsigned int) objIndex {
	[primitive setControlView: mControlView]; 
	[primitive setContainer: self]; 
	
	[mDecorationPrimitives insertObject: primitive atIndex: objIndex]; 
	
	if (mControlView)
		// and update our control view 
		[mControlView setNeedsDisplay: YES]; 	
}

- (void) removePrimitiveAtIndex: (unsigned int) objIndex {
	VTDecorationPrimitive* primitiveToRemove = [mDecorationPrimitives objectAtIndex: objIndex]; 
		
	// unhook the primitive 
//	[primitiveToRemove setControlView: nil]; 
//	[primitiveToRemove setContainer: nil]; 
	
	
	// remove from our container 
	[mDecorationPrimitives removeObject: primitiveToRemove]; 
	
	if (mControlView)
		// and update our control view 
		[mControlView setNeedsDisplay: YES]; 		
}

@end 

