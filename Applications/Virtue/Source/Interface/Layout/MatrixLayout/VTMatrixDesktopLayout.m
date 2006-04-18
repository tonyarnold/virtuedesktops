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

#import "VTMatrixDesktopLayout.h"
#import "VTMatrixPager.h" 
#import <Virtue/VTDesktopController.h>
#import <Zen/Zen.h>

#define kVtCodingRowCount				@"rows"
#define kVtCodingColCount				@"cols"
#define kVtCodingWraps					@"wrapsAround"
#define kVtCodingJumps					@"jumpsGaps"
#define kVtCodingCompacted			@"compacted"
#define kVtCodingContinous			@"continous"
#define kVtCodingDesktopLayout	@"desktopLayout"
#define kVtCodingPager					@"pager"
#define kVtCodingDraggable			@"draggable"

#pragma mark -
#define kFreeDesktopSlotIdentifier @"" 

#pragma mark -
@interface VTMatrixDesktopLayout(Private) 
- (int) columnForIndex: (unsigned int) index; 
- (int) rowForIndex: (unsigned int) index; 
- (unsigned int) indexOfDesktop: (VTDesktop*) desktop; 

- (NSArray*) indicesForColumn: (unsigned int) column; 
- (NSArray*) indicesForRow: (unsigned int) row; 
- (NSArray*) indicesForAll; 

- (void) resizeDesktopLayout; 
- (void) synchronizeDesktopLayout; 
@end 

#pragma mark -
@implementation VTMatrixDesktopLayout

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	// fetch localized name for our layout 
	NSString* name = NSLocalizedString(@"VTMatrixLayoutName", @"Matrix Layout name"); 
	if (name == nil) 
		name = @"Matrix Layout"; 
	
	if (self = [super initWithName: name]) {
		// attributes 
		mRows				= 2; 
		mColumns		= 2; 
		mWraps			= YES;
		mJumpsGaps	= YES;
		mCompacted	= NO; 
		mContinous	= NO; 
		mDraggable	= YES;
		
		// pager 
		mPager		= [[VTMatrixPager alloc] initWithLayout: self]; 
		
		// set up desktop layout 
		[self resizeDesktopLayout]; 
		[self synchronizeDesktopLayout]; 
		
		// and listen to desktop changes 
		[[VTDesktopController sharedInstance] addObserver: self forKeyPath: @"desktops" options: NSKeyValueObservingOptionNew context: NULL]; 
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// no notifications anymore please 
	[[VTDesktopController sharedInstance] removeObserver: self forKeyPath: @"desktops"]; 
	
	ZEN_RELEASE(mPager); 
	ZEN_RELEASE(mDesktopLayout); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	// layout information 
	[dictionary setObject: [NSNumber numberWithInt: mRows] forKey: kVtCodingRowCount];
	[dictionary setObject: [NSNumber numberWithInt: mColumns] forKey: kVtCodingColCount]; 
	
	// properties of layout 
	[dictionary setObject: [NSNumber numberWithBool: mWraps] forKey: kVtCodingWraps]; 
	[dictionary setObject: [NSNumber numberWithBool: mJumpsGaps] forKey: kVtCodingJumps]; 
	[dictionary setObject: [NSNumber numberWithBool: mCompacted] forKey: kVtCodingCompacted]; 
	[dictionary setObject: [NSNumber numberWithBool: mContinous] forKey: kVtCodingContinous]; 
	
	// pager preferences 
	NSMutableDictionary* pagerDict = [NSMutableDictionary dictionary]; 
	[(VTMatrixPager*)mPager encodeToDictionary: pagerDict]; 
	[dictionary setObject: pagerDict forKey: kVtCodingPager]; 
	
	// our desktop layout 
	[dictionary setObject: mDesktopLayout forKey: kVtCodingDesktopLayout]; 
	
	// Do we allow dragging cells to re-arrange?
	[dictionary setObject: [NSNumber numberWithBool: mDraggable]	forKey: kVtCodingDraggable];
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) {	
		// read information 
		if ([dictionary objectForKey: kVtCodingRowCount])
			mRows = [[dictionary objectForKey: kVtCodingRowCount] intValue]; 
		if ([dictionary objectForKey: kVtCodingColCount])
			mColumns = [[dictionary objectForKey: kVtCodingColCount] intValue]; 

		// read layout information 
		mWraps = [[dictionary objectForKey: kVtCodingWraps] boolValue]; 
		mJumpsGaps = [[dictionary objectForKey: kVtCodingJumps] boolValue]; 
		mCompacted = [[dictionary objectForKey: kVtCodingCompacted] boolValue]; 
		mContinous = [[dictionary objectForKey: kVtCodingContinous] boolValue]; 	
		mDraggable = [[dictionary objectForKey: kVtCodingDraggable] boolValue];
		
		// read pager information
		if ([dictionary objectForKey: kVtCodingPager])
			mPager = [(VTMatrixPager*)mPager decodeFromDictionary: [dictionary objectForKey: kVtCodingPager]]; 
		
		// read desktop layout 
		if ([dictionary objectForKey: kVtCodingDesktopLayout])  {
			// exchange the desktop layout and have our synchronization 
			// algorithm clean it up 
			ZEN_RELEASE(mDesktopLayout); 
			mDesktopLayout = [[dictionary objectForKey: kVtCodingDesktopLayout] retain]; 
			
			[self resizeDesktopLayout]; 
			[self synchronizeDesktopLayout]; 
		}
		else {
			[self resizeDesktopLayout]; 
			[self synchronizeDesktopLayout]; 
		}
	
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Attributes 
- (NSObject<VTPager>*) pager {
	return mPager;
}

- (NSArray*) desktops {
	return mDesktopLayout; 
}

- (NSArray*) orderedDesktops {
	// assemble new array containing our desktops in the correct order and 
	// excluding empty slots 
	NSMutableArray* orderedDesktops = [NSMutableArray array]; 
	NSEnumerator*	desktopIter		= [mDesktopLayout objectEnumerator]; 
	NSString*		desktopUUID		= nil; 
	
	while (desktopUUID = [desktopIter nextObject]) {
		// jump over empty slots 
		if ([desktopUUID isEqualToString: kFreeDesktopSlotIdentifier]) 
			continue; 
		
		// and add the desktop instance 
		[orderedDesktops addObject: [[VTDesktopController sharedInstance] desktopWithUUID: desktopUUID]]; 
	}

	return orderedDesktops; 
}

#pragma mark -
- (unsigned int) numberOfRows {
	return mRows; 
}

- (unsigned int) numberOfDisplayedRows {
	// TODO: Consider compacted flag 	
	return mRows; 
}

- (void) setNumberOfRows: (unsigned int) rows {
	if (rows == mRows)
		return; 
	
	mRows = rows; 
	
	[self resizeDesktopLayout]; 
	[self synchronizeDesktopLayout]; 
}

#pragma mark -
- (unsigned int) numberOfColumns {
	return mColumns; 
}

- (unsigned int) numberOfDisplayedColumns {
	// TODO: Consider compacted flag 
	return mColumns; 
}

- (void) setNumberOfColumns: (unsigned int) cols {
	if (mColumns == cols)
		return; 
	
	mColumns = cols; 
	
	[self resizeDesktopLayout]; 
	[self synchronizeDesktopLayout]; 
}

#pragma mark -
- (BOOL) bindsNumberOfColumnsToRows {
	return NO; 
}

- (void) setBindsNumberOfColumnsToRows: (BOOL) flag {
}

#pragma mark -
- (BOOL) isCompacted {
	return mCompacted; 
}

- (void) setCompacted: (BOOL) flag {
	mCompacted = flag; 
	
	// we only need to resize if we were switching to compacted mode as 
	// we do not have information about the previous layout with empty 
	// cells, so we cannot undo compacting... 
	if (mCompacted == YES)
		[self resizeDesktopLayout]; 
}

#pragma mark -
- (BOOL) isWrapping {
	return mWraps; 
}

- (void) setWrapping: (BOOL) flag {
	mWraps = flag; 
}

#pragma mark -
- (BOOL) isJumpingGaps {
	return mJumpsGaps; 
}

- (void) setJumpingGaps: (BOOL) flag {
	mJumpsGaps = flag;
}

#pragma mark -
- (BOOL) isContinous {
	return mContinous; 
}

- (void) setContinous: (BOOL) flag {
	mContinous = flag; 
}

#pragma mark -
- (BOOL) isDraggable {
	return mDraggable; 
}

- (void) setDraggable: (BOOL) flag {
	mDraggable = flag; 
}

#pragma mark -
- (NSArray*) desktopLayout {
	return mDesktopLayout; 
}

- (void) swapDesktopAtIndex: (unsigned int) index withIndex: (unsigned int) otherIndex {
	if (index == otherIndex)
		return; 
	
	[self willChangeValueForKey: @"desktopLayout"];
	[self willChangeValueForKey: @"desktops"]; 
	[self willChangeValueForKey: @"orderedDesktops"]; 
	
	NSString* uuidOfFirst	= [[[mDesktopLayout objectAtIndex: index] retain] autorelease]; 
	NSString* uuidOfSecond	= [[[mDesktopLayout objectAtIndex: otherIndex] retain] autorelease]; 
	
	[mDesktopLayout replaceObjectAtIndex: index withObject: uuidOfSecond]; 
	[mDesktopLayout replaceObjectAtIndex: otherIndex withObject: uuidOfFirst]; 
	
	[self didChangeValueForKey: @"orderedDesktops"]; 
	[self didChangeValueForKey: @"desktops"]; 
	[self didChangeValueForKey: @"desktopLayout"]; 
}

#pragma mark -
#pragma mark KVO Sink 

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context {
	if ([keyPath isEqualToString: @"desktops"]) {
		// sync our layout 
		[self synchronizeDesktopLayout]; 
	}
}

#pragma mark -
#pragma mark VTDesktopLayout implementation 
- (VTDesktop*) desktopInDirection: (VTDirection) direction ofDesktop: (VTDesktop*) desktop {
	int				indexOfReferenceDesktop = [self indexOfDesktop: desktop]; 
	int				indicesArrayIncrement		= 0; 
	NSArray*	indicesArray						= nil; 
	
	if (direction == kVtDirectionEast) {
		indicesArrayIncrement = 1; 
		if (mContinous) 
			indicesArray = [self indicesForAll]; 
		else
			indicesArray = [self indicesForRow: [self rowForIndex: indexOfReferenceDesktop]]; 
	}
	else if (direction == kVtDirectionWest) {
		indicesArrayIncrement = -1; 
		if (mContinous)
			indicesArray = [self indicesForAll]; 
		else
			indicesArray = [self indicesForRow: [self rowForIndex: indexOfReferenceDesktop]]; 
	}
	else if (direction == kVtDirectionNorth) {
		indicesArrayIncrement = -1; 
		indicesArray = [self indicesForColumn: [self columnForIndex: indexOfReferenceDesktop]]; 
	}
	else if (direction == kVtDirectionSouth) {
		indicesArrayIncrement = 1; 
		indicesArray = [self indicesForColumn: [self columnForIndex: indexOfReferenceDesktop]]; 
	}
	else {
		// we do not support other directions 
		return desktop; 
	}
		
	// now we can search the desktop we need 
	int referenceIndex = [indicesArray indexOfObject: [NSNumber numberWithInt: indexOfReferenceDesktop]]; 
	// find our adjacent desktop 
	int index = referenceIndex + indicesArrayIncrement; 
	
	while (index != referenceIndex) {
		if ((index == [indicesArray count]) || (index < 0)) {
			// if we should not wrap, we return 
			if (mWraps == NO) 
				return desktop; 
			
			if (index < 0)
				index = [indicesArray count] - 1; 
			else
				index = 0; 
		}
		else {
			if ([[mDesktopLayout objectAtIndex: [[indicesArray objectAtIndex: index] intValue]] isEqualToString: kFreeDesktopSlotIdentifier]) {
				// if we should not jump gaps of non-taken slots, we return 
				if (mJumpsGaps == NO)
					return desktop; 
				
				index += indicesArrayIncrement; 
			}
			else {
				// find the desktop 
				NSString* identifier = [mDesktopLayout objectAtIndex: [[indicesArray objectAtIndex: index] intValue]]; 				
				return [[VTDesktopController sharedInstance] desktopWithUUID: identifier]; 
			}
		}
	}

	// if we came here, we did not find any desktop 
	return desktop; 
}

- (VTDirection) directionFromDesktop: (VTDesktop*) referenceDesktop toDesktop: (VTDesktop*) desktop {
	// we need indices of both desktops... 
	unsigned int indexOfTarget			=	[self indexOfDesktop: desktop]; 
	unsigned int indexOfReference   = [self indexOfDesktop: referenceDesktop]; 
	// and also their rows...
	int rowOfTarget					= [self rowForIndex: indexOfTarget]; 
	int rowOfReference			= [self rowForIndex: indexOfReference]; 
	int columnOfTarget			= [self columnForIndex: indexOfTarget];
	int columnOfReference		=	[self columnForIndex: indexOfReference];
	
	
	// Interesting problem here:
	//	None of Apple's transitions appear to be finished -- they don't support diagonal directions properly (those that do are reversed)
	//	Another argument for CoreImage transitions? (if they're ever fast enough)
	
	// If they are in the same row.. 
	if (rowOfTarget == rowOfReference) {
		if (columnOfTarget > columnOfReference)
			return kVtDirectionEast; 
		if (columnOfTarget < columnOfReference)
			return kVtDirectionWest;
	}
	else
	{
		if (rowOfTarget > rowOfReference) {
			if (columnOfTarget > columnOfReference)
				return kVtDirectionSoutheast; 
			if (columnOfTarget < columnOfReference)
				return kVtDirectionSouthwest;
			
			return kVtDirectionSouth;
		}
		else
		{
			if (columnOfTarget > columnOfReference)
				return kVtDirectionNortheast; 
			if (columnOfTarget < columnOfReference)
				return kVtDirectionNorthwest;
			
			return kVtDirectionNorth;
		}
	}
	
	// If all else fails...
	return kVtDirectionNone; 
}


@end

#pragma mark -
@implementation VTMatrixDesktopLayout(Private) 

- (int) columnForIndex: (unsigned int) index {
	return (index % mColumns);
}

- (int) rowForIndex: (unsigned int) index {
	return (index / mColumns); 
}

#pragma mark -
- (unsigned int) indexOfDesktop: (VTDesktop*) desktop {
	return [mDesktopLayout indexOfObject: [desktop uuid]]; 
}

- (NSArray*) indicesForColumn: (unsigned int) column {
	NSMutableArray* indices = [[NSMutableArray alloc] initWithCapacity: mRows]; 
	
	unsigned int index = column; 
	for (index; index < [mDesktopLayout count]; index += mColumns) {
		[indices addObject: [NSNumber numberWithUnsignedInt: index]]; 
	}
	
	return [indices autorelease]; 
}

- (NSArray*) indicesForRow: (unsigned int) row {
	NSMutableArray* indices = [[NSMutableArray alloc] initWithCapacity: mColumns]; 
	
	unsigned int index = row * mColumns; 
	for (index; index < (mColumns * (row + 1)); index++) {
		[indices addObject: [NSNumber numberWithUnsignedInt: index]]; 
	}
	
	return [indices autorelease]; 
}

- (NSArray*) indicesForAll {
	NSMutableArray* indices = [[NSMutableArray alloc] initWithCapacity: (mColumns * mRows)];
	
	unsigned int index = 0; 
	for (index; index < (mColumns * mRows); index++) {
		[indices addObject: [NSNumber numberWithUnsignedInt: index]]; 
	}
	
	return [indices autorelease]; 
}

#pragma mark -

- (void) resizeDesktopLayout {
	[self willChangeValueForKey: @"desktopLayout"];
	[self willChangeValueForKey: @"desktops"]; 
	[self willChangeValueForKey: @"orderedDesktops"]; 
	
	// resize and fill empty slots with null markers 
	NSMutableArray*	newLayout = [[NSMutableArray alloc] initWithCapacity: (mRows * mColumns)]; 

	NSEnumerator*		oldIter		= [mDesktopLayout objectEnumerator]; 
	NSString*				old				= nil; 
	int							index			= 0; 
	
	// copy over old entries 
	while ((index < (mRows * mColumns)) && (old = [oldIter nextObject])) {
		// if we are doing this in compacted mode, we will ignore missing 
		// desktop slots and only deal with filled ones here 
		if (mCompacted) {
			if ([old isEqualToString: kFreeDesktopSlotIdentifier]) 
				continue; 
		}
		
		[newLayout addObject: old]; 
		index++; 
	}
	
	// fill up any missing slots 
	while ([newLayout count] < (mRows * mColumns)) {
		[newLayout addObject: kFreeDesktopSlotIdentifier]; 
	}
	
	// now get rid of original 
	ZEN_RELEASE(mDesktopLayout); 
	// remember new 
	mDesktopLayout = newLayout; 
	
	[self didChangeValueForKey: @"orderedDesktops"];
	[self didChangeValueForKey: @"desktops"]; 
	[self didChangeValueForKey: @"desktopLayout"]; 
}

/**
 * Synchronizes the desktop layout with the currently available desktops 
 *
 * Currently implemented as a two pass synchronization; the first pass will 
 * clean up all non-existing entries from our mapping, the second pass will 
 * add desktops we do not have in our mapping yet, filling up gaps from the 
 * start of the map
 *
 */ 
- (void) synchronizeDesktopLayout {
	[self willChangeValueForKey: @"desktopLayout"]; 
	[self willChangeValueForKey: @"desktops"]; 
	[self willChangeValueForKey: @"orderedDesktops"]; 
	
	// FIRST pass 
	// Remove entries referencing non-existant desktops 
	NSEnumerator*	uuidIter	= [mDesktopLayout objectEnumerator]; 
	NSString*			uuid		= nil; 
	
	while (uuid = [uuidIter nextObject]) {
		if ([[VTDesktopController sharedInstance] desktopWithUUID: uuid] == nil) 
			[mDesktopLayout replaceObjectAtIndex: [mDesktopLayout indexOfObject: uuid] withObject: kFreeDesktopSlotIdentifier]; 
	}
	
	// SECOND pass 
	// Add new desktops 
	NSEnumerator*	desktopIter	= [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		// check if we know this desktop already 
		if ([mDesktopLayout containsObject: [desktop uuid]])
			continue; 
		
		// now we are dealing with a new desktop, find us a free slot 
		int index = [mDesktopLayout indexOfObject: kFreeDesktopSlotIdentifier]; 
		// if there are no more free slots, we will ignore this desktop
		if (index == NSNotFound) 
			continue; 
		
		[mDesktopLayout replaceObjectAtIndex: index withObject: [desktop uuid]]; 
	}
	
	[self didChangeValueForKey: @"orderedDesktops"];
	[self didChangeValueForKey: @"desktops"];
	[self didChangeValueForKey: @"desktopLayout"]; 
}

@end 
