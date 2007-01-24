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

#import "VTDecorationPrimitiveBindings.h" 

@implementation VTDecorationPrimitive(VTBindings)

#pragma mark -
#pragma mark Attributes 
- (int) positionTypeTag {
	switch (mPositionType) {
		case kVtDecorationPositionAbsolute: 
			return 0; 
		case kVtDecorationPositionTL: 
			return 1; 
		case kVtDecorationPositionTR: 
			return 2; 
		case kVtDecorationPositionLL: 
			return 3; 
		case kVtDecorationPositionLR: 
			return 4; 
		case kVtDecorationPositionTop: 
			return 5; 
		case kVtDecorationPositionBottom: 
			return 6; 
		case kVtDecorationPositionLeft: 
			return 7; 
		case kVtDecorationPositionRight: 
			return 8; 
    case kVtDecorationPositionCenter:
      return 9;
	}
	
	return 0; 
}

- (void) setPositionTypeTag: (int) tag {
	[self willChangeValueForKey: @"positionType"]; 
	[self willChangeValueForKey: @"absolutePosition"]; 
	
	switch (tag) {
		case 0: 
			[self setPositionType: kVtDecorationPositionAbsolute]; 
			break; 
		case 1: 
			[self setPositionType: kVtDecorationPositionTL]; 
			break; 
		case 2:
			[self setPositionType: kVtDecorationPositionTR];
			break; 
		case 3: 
			[self setPositionType: kVtDecorationPositionLL]; 
			break; 
		case 4: 
			[self setPositionType: kVtDecorationPositionLR]; 
			break; 
		case 5: 
			[self setPositionType: kVtDecorationPositionTop]; 
			break; 
		case 6: 
			[self setPositionType: kVtDecorationPositionBottom]; 
			break; 
		case 7: 
			[self setPositionType: kVtDecorationPositionLeft]; 
			break; 
		case 8: 
			[self setPositionType: kVtDecorationPositionRight]; 
			break; 
    case 9:
      [self setPositionType: kVtDecorationPositionCenter];
	}
	
	[self didChangeValueForKey: @"positionType"]; 
	[self didChangeValueForKey: @"absolutePosition"]; 
	
	[self setNeedsDisplay]; 
}

#pragma mark -
- (BOOL) isAbsolutePosition {
	return (mPositionType == kVtDecorationPositionAbsolute); 
}

- (void) setAbsolutePosition: (BOOL) flag {
	[self willChangeValueForKey: @"relativePosition"]; 
	
	if (flag == YES) {
		[self setPositionTypeTag: 0]; 
		[self didChangeValueForKey: @"relativePosition"]; 
		
		return; 
	}
	
	NSEnumerator*	tagIter = [[self supportedPositionTypes] objectEnumerator]; 
	NSNumber*		tag		= nil; 
	NSNumber*		tagCurr	= [NSNumber numberWithInt: [self positionType]]; 
	
	while (tag = [tagIter nextObject]) {
		if ([tag isEqual: tagCurr]) 
			continue; 
		
		break; 
	}
	
	if (tag == nil) {
		[self setPositionType: [[[self supportedPositionTypes] objectAtIndex: 0] intValue]]; 
		[self setPositionTypeTag: [self positionTypeTag]]; 

		[self didChangeValueForKey: @"relativePosition"]; 

		return; 
	}
	
	[self setPositionType: [tag intValue]]; 
	[self setPositionTypeTag: [self positionTypeTag]]; 

	[self didChangeValueForKey: @"relativePosition"]; 
}

- (BOOL) isRelativePosition {
	return ![self isAbsolutePosition]; 
}

- (void) setRelativePosition: (BOOL) flag {
	[self setAbsolutePosition: !flag]; 
}

- (int) absolutePositionTag {
	if ([self isAbsolutePosition])
		return 0; 

	return 1; 
}

- (void) setAbsolutePositionTag: (int) tag {
	if (tag == 0) {
		[self setPositionTypeTag: 0]; 
		return; 
	}
	
	// otherwise we query the position type from our control to set 
	[self setPositionTypeTag: 6]; 
}

#pragma mark -
- (BOOL) supportsAbsolutePosition {
	return [[self supportedPositionTypes] containsObject: [NSNumber numberWithInt: kVtDecorationPositionAbsolute]]; 
}

- (BOOL) supportsRelativePosition {
	if ([self supportsAbsolutePosition])
		return [[self supportedPositionTypes] count] > 1; 
	
	return [[self supportedPositionTypes] count] > 0; 
}

#pragma mark -
- (int) positionX {
	return mPosition.x; 
}

- (void) setPositionX: (int) x {
	[self willChangeValueForKey: @"position"]; 
	mPosition.x = x; 
	[self didChangeValueForKey: @"position"]; 
	
	[self setNeedsDisplay]; 
}

#pragma mark -
- (int) positionY {
	return mPosition.y; 
}

- (void) setPositionY: (int) y {
	[self willChangeValueForKey: @"position"]; 
	mPosition.y = y; 
	[self didChangeValueForKey: @"position"]; 
	
	[self setNeedsDisplay]; 
}

@end
