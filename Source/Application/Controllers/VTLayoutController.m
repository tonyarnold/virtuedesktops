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

#import "VTLayoutController.h"
#import "VTPreferences.h" 
#import <Zen/Zen.h> 

#define	kVtCodingLayouts			@"layouts"
#define kVtCodingLayout				@"layout"
#define kVtCodingLayoutType		@"type"
#define kVtCodingLayoutName		@"name"
#define kVtCodingActiveLayout	@"activeLayout"

#pragma mark -
@interface VTLayoutController(Private) 
- (void) writePreferences; 
- (void) readPreferences; 
@end 

#pragma mark -
@implementation VTLayoutController

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// attributes 
		mActiveLayout	= nil; 
		mLayouts 			= [[NSMutableArray alloc] init]; 
		
		[self readPreferences]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mActiveLayout); 
	ZEN_RELEASE(mLayouts); 
	
	[super dealloc]; 
}

#pragma mark -

+ (VTLayoutController*) sharedInstance {
	static VTLayoutController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[VTLayoutController alloc] init]; 
	
	return ms_INSTANCE; 
}

#pragma mark -
#pragma mark Persistentcy 

- (void) synchronize {
	[self writePreferences]; 
}

#pragma mark -
#pragma mark Attributes 

- (VTDesktopLayout*) activeLayout {
	return mActiveLayout; 
}

- (void) setActiveLayout: (VTDesktopLayout*) layout {
	ZEN_ASSIGN(mActiveLayout, layout); 
}

#pragma mark -

- (NSArray*) layouts {
	return mLayouts; 
}

- (void) attachLayout: (VTDesktopLayout*) layout {
	// check if we already know about this type of layout 
	; 
	
	// now add it 
	[self willChangeValueForKey: @"layouts"]; 
	[mLayouts addObject: layout]; 
	[self didChangeValueForKey: @"layouts"]; 
}

- (void) detachLayout: (VTDesktopLayout*) layout {
	// check if we know about the passed layout 
	; 
	
	// if it is the active layout, set that to nil 
	if ([mActiveLayout isEqual: layout])
		[self setActiveLayout: nil]; 
	
	// now remove it 
	[self willChangeValueForKey: @"layouts"]; 
	[mLayouts removeObject: layout]; 
	[self didChangeValueForKey: @"layouts"]; 
}

@end

#pragma mark -
@implementation VTLayoutController(Private) 

- (void) writePreferences {
	NSMutableDictionary*	dictionary	= [NSMutableDictionary dictionary]; 
	NSMutableArray*			layouts		= [NSMutableArray array]; 
	
	[dictionary setObject: [[self activeLayout] name] forKey: kVtCodingActiveLayout]; 
	
	NSEnumerator*			layoutIter	= [mLayouts objectEnumerator]; 
	VTDesktopLayout*		layout		= nil; 
	
	while (layout = [layoutIter nextObject]) {
		NSMutableDictionary* layoutDict			= [NSMutableDictionary dictionary]; 
		NSMutableDictionary* layoutContentDict	= [NSMutableDictionary dictionary]; 
		
		[layoutDict setObject: NSStringFromClass([layout class]) forKey: kVtCodingLayoutType]; 
		[layoutDict setObject: [layout name] forKey: kVtCodingLayoutName]; 
		
		[layout encodeToDictionary: layoutContentDict]; 
		[layoutDict setObject: layoutContentDict forKey: kVtCodingLayout]; 
		
		[layouts addObject: layoutDict]; 
	}
	
	[dictionary setObject: layouts forKey: kVtCodingLayouts]; 
	[[NSUserDefaults standardUserDefaults] setObject: dictionary forKey: VTLayouts]; 
}

- (void) readPreferences {
	// read information back in 
	NSDictionary*	layoutsDict	= [[NSUserDefaults standardUserDefaults] objectForKey: VTLayouts]; 
	NSString*		activeLayout	= [layoutsDict objectForKey: kVtCodingActiveLayout]; 
	
	if (layoutsDict == nil) 
		return; 
	
	NSArray*			layouts		= [layoutsDict objectForKey: kVtCodingLayouts]; 
	NSEnumerator*		layoutIter	= [layouts objectEnumerator]; 
	NSDictionary*		layoutDict	= nil; 
	
	while (layoutDict = [layoutIter nextObject]) {
		Class		layoutClass = NSClassFromString([layoutDict objectForKey: kVtCodingLayoutType]); 
		NSString*	layoutName	= [layoutDict objectForKey: kVtCodingLayoutName]; 
		
		VTDesktopLayout* layout = [[layoutClass alloc] init]; 
		if (layout) {
			layout = [layout decodeFromDictionary: [layoutDict objectForKey: kVtCodingLayout]]; 
			
			if (layout) {
				[self attachLayout: layout];
				if ([layoutName isEqualToString: activeLayout]) 
					[self setActiveLayout: layout]; 
				
				[layout release]; 
			}
		}
	}
}
@end 
