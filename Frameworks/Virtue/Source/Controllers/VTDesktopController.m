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

#import "VTDesktopController.h"
#import "VTDesktopDecorationController.h" 
#import "VTPreferences.h" 
#import "VTDesktopLayout.h" 
#import "VTLayoutController.h" 
#import "VTNotifications.h" 
#import "VTPluginCollection.h" 
#import "VTPluginScript.h" 
#import "VTDesktopBackgroundHelper.h" 

#import <Zen/Zen.h> 
#import <Zen/NSMethodSignatureArguments.h> 

@interface VTDesktopController (Private)
- (void) createDefaultDesktops; 
#pragma mark -
- (VTDesktop*) desktopForId: (int) idendifier; 
#pragma mark -
- (void) doActivateDesktop: (VTDesktop*) desktop withDirection: (VTDirection) direction; 
- (void) doActivateDesktop: (VTDesktop*) desktop usingTransition: (PNTransitionType) type withOptions: (PNTransitionOption) option andDuration: (float) duration; 
#pragma mark -
- (void) applyDecorationPrototypeForDesktop: (VTDesktop*) desktop overwrite: (BOOL) overwrite; 
- (void) applyDesktopBackground; 
@end

#pragma mark -
@implementation VTDesktopController

#pragma mark -
#pragma mark Lifetime 

+ (VTDesktopController*) sharedInstance {
	static VTDesktopController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[VTDesktopController alloc] init]; 
	
	return ms_INSTANCE; 
}

#pragma mark -

- (id) init {
	if (self = [super init]) {
		// init attributes 
		mDesktops											= [[NSMutableArray alloc] init];
		mPreviousDesktop							= nil; 
		mSnapbackDesktop							= nil; 
		mDecorationPrototype					= nil; 
		mNeedDesktopBackgroundUpdate	= NO; 
		mExpectingBackgroundChange		= NO; 
		
		ZEN_ASSIGN_COPY(mDefaultDesktopBackgroundPath, [VTDesktop currentDesktopBackground]); 
		
		// register as observer for desktop switches 
		[[NSNotificationCenter defaultCenter] 
			addObserver: self selector: @selector(onDesktopWillChange:) name: kPnOnDesktopWillActivate object: nil]; 
		[[NSNotificationCenter defaultCenter] 
			addObserver: self selector: @selector(onDesktopDidChange:) name: kPnOnDesktopDidActivate object: nil]; 
		[[NSDistributedNotificationCenter defaultCenter]
            addObserver: self
			   selector: @selector(onDesktopBackgroundChanged:)
				   name: VTBackgroundHelperDesktopChangedName
				 object: VTBackgroundHelperDesktopChangedObject]; 
			
		// create timer loop to update desktops 
		[NSTimer scheduledTimerWithTimeInterval: 1.5 target: self selector: @selector(onUpdateDesktops:) userInfo: nil repeats: NO]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// unbind desktop 
	[[self activeDesktop] removeObserver: self forKeyPath: @"managesIconset"]; 
	[[self activeDesktop] removeObserver: self forKeyPath: @"showsBackground"]; 
		
	// get rid of observer status 
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self]; 
	
	// get rid of attributes 
	ZEN_RELEASE(mDesktops);
	ZEN_RELEASE(mPreviousDesktop); 
	ZEN_RELEASE(mSnapbackDesktop); 
	ZEN_RELEASE(mDefaultDesktopBackgroundPath); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Factories 

- (VTDesktop*) desktopWithFreeId {
	return [VTDesktop desktopWithIdentifier: [self freeId]]; 
}

- (int) freeId {
	int i = [PNDesktop firstDesktopIdentifier]; 
	
	while (YES) {
		if ([self desktopForId: i] == nil)
			return i; 
			
		// try next one 
		i++; 
	}	
}


#pragma mark -
#pragma mark Attributes 

- (NSArray*) desktops {
	return mDesktops;
}

- (void) addInDesktops: (VTDesktop*) desktop {
	// and add 
	[self insertObject: desktop inDesktopsAtIndex: [mDesktops count]]; 
}

- (void) insertObject: (VTDesktop*) desktop inDesktopsAtIndex: (unsigned int) index {
	[[NSNotificationCenter defaultCenter] postNotificationName: VTDesktopWillAddNotification object: desktop]; 
	// notification that canDelete will change 
	[self willChangeValueForKey: @"canDelete"]; 
	
	// and add 
	[mDesktops insertObject: desktop atIndex: index]; 
	// set up desktop 
	[desktop attachToDisk]; 
	[desktop setDefaultDesktopBackgroundPath: mDefaultDesktopBackgroundPath]; 
	// attach the decoration 
	[[VTDesktopDecorationController sharedInstance] attachDecoration: [desktop decoration]]; 
	// and apply our default decoration if we should 
	if (mUsesDecorationPrototype && mDecorationPrototype) {
		[self applyDecorationPrototypeForDesktop: desktop overwrite: NO]; 
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: VTDesktopDidAddNotification object: desktop]; 
	
	// here we are sure we created the desktop, so we will trigger some 
	// notifications by hand to inform our plugins 
	NSMethodSignature*	signature	= [NSMethodSignature methodSignatureWithReturnAndArgumentTypes: @encode(void), @encode(VTDesktop*), nil];
	NSInvocation*		invocation	= [NSInvocation invocationWithMethodSignature: signature];
	
	[invocation setSelector: @selector(onDesktopDidCreateNotification:)];
	[invocation setArgument: &desktop atIndex: 2];
	
	[[VTPluginCollection sharedInstance] makePluginsOfType: @protocol(VTPluginScript) performInvocation: invocation];	
	
	// KVO notification for canDelete
	[self didChangeValueForKey: @"canDelete"]; 	
}

- (void) removeObjectFromDesktopsAtIndex: (unsigned int) index {
	VTDesktop* desktopToRemove = [[mDesktops objectAtIndex: index] retain]; 
	
	// here we are sure we want to delete the desktop, so we will trigger some 
	// notifications by hand to inform our plugins 
	NSMethodSignature*	signature	= [NSMethodSignature methodSignatureWithReturnAndArgumentTypes: @encode(void), @encode(VTDesktop*), nil];
	NSInvocation*		invocation	= [NSInvocation invocationWithMethodSignature: signature];
	
	[invocation setSelector: @selector(onDesktopWillDeleteNotification:)];
	[invocation setArgument: &desktopToRemove atIndex: 2];
	
	[[VTPluginCollection sharedInstance] makePluginsOfType: @protocol(VTPluginScript) performInvocation: invocation];
	
	
	// check which desktop to move them to 
	int targetIndex = index - 1; 
	if (targetIndex < 0)
		targetIndex = [mDesktops count] - 1; 
	
	VTDesktop* target = [mDesktops objectAtIndex: targetIndex]; 

	if ([[self activeDesktop] isEqual: desktopToRemove]) 
		[self activateDesktop: target]; 
	
	[[NSNotificationCenter defaultCenter] postNotificationName: VTDesktopWillRemoveNotification object: desktopToRemove]; 
	
	// check if we hit the previous desktop and if so, let it point to nil 
	if ([desktopToRemove isEqual: mPreviousDesktop]) {
		[self willChangeValueForKey: @"previousDesktop"]; 
		ZEN_RELEASE(mPreviousDesktop); 
		[self didChangeValueForKey: @"previousDesktop"]; 
	}
	// check if we hit the snapback desktop and if so, let it point to nil 
	if ([desktopToRemove isEqual: mSnapbackDesktop]) {
		[self willChangeValueForKey: @"snapbackDesktop"]; 
		ZEN_RELEASE(mSnapbackDesktop); 
		[self didChangeValueForKey: @"snapbackDesktop"]; 
	}
		
	// remove all persistent traces of the desktop 
	[desktopToRemove detachFromDisk]; 
	// detach the decoration 
	[[VTDesktopDecorationController sharedInstance] detachDecorationForDesktop: desktopToRemove];
	
	// now check if we should move windows 
	if (([[NSUserDefaults standardUserDefaults] boolForKey: VTWindowsCollectOnDelete]) && 
		([mDesktops count] > 1)) {
		[desktopToRemove moveAllWindowsToDesktop: target]; 
	}
	
	// and remove the object 
	[self willChangeValueForKey: @"canDelete"]; 
	[mDesktops removeObjectAtIndex: index]; 
	[self didChangeValueForKey: @"canDelete"]; 
	
	[[NSNotificationCenter defaultCenter] postNotificationName: VTDesktopDidRemoveNotification object: desktopToRemove]; 
	ZEN_RELEASE(desktopToRemove); 
	
	// check if we got any desktops left, and if we don't, we will create our
	// default desktops 
	if ([mDesktops count] == 0)
		[self createDefaultDesktops]; 
}

#pragma mark -

- (BOOL) canDelete {
	return ([mDesktops count] > 1); 
}

#pragma mark -

- (VTDesktop*) activeDesktop {
	// ask the desktop class for the active one 
	int activeDesktopId = [PNDesktop activeDesktopIdentifier]; 
	
	// return that desktop 
	return [self desktopForId: activeDesktopId]; 	
}

#pragma mark -
- (VTDesktop*) previousDesktop {
	return mPreviousDesktop; 
}

#pragma mark -
- (VTDesktop*) snapbackDesktop {
	return mSnapbackDesktop; 
}

- (void) setSnapbackDesktop: (VTDesktop*) desktop {
	ZEN_ASSIGN(mSnapbackDesktop, desktop); 
}

#pragma mark -
- (VTDesktopDecoration*) decorationPrototype {
	return mDecorationPrototype; 
}

- (void) setDecorationPrototype: (VTDesktopDecoration*) prototype {
	ZEN_ASSIGN(mDecorationPrototype, prototype); 
}

#pragma mark -
- (void) setUsesDecorationPrototype: (BOOL) flag {
	mUsesDecorationPrototype = flag; 
}

- (BOOL) usesDecorationPrototype {
	return mUsesDecorationPrototype; 
}

#pragma mark -
#pragma mark Querying 
- (VTDesktop*) desktopWithUUID: (NSString*) uuid {
	NSEnumerator*	desktopIter		= [mDesktops objectEnumerator]; 
	VTDesktop*		desktop			= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		if ([[desktop uuid] isEqualToString: uuid]) 
			return desktop; 
	}
	
	return nil; 
}

- (VTDesktop*) desktopWithIdentifier: (int) identifier {
	return [self desktopForId: identifier]; 
}

#pragma mark -
#pragma mark Desktop switching 

- (void) activateDesktop: (VTDesktop*) desktop {
	// fetch direction to foward 
	VTDirection direction = [[[VTLayoutController sharedInstance] activeLayout] directionFromDesktop: [[VTDesktopController sharedInstance] activeDesktop] toDesktop: desktop];

	[self doActivateDesktop: desktop withDirection: direction]; 
}

- (void) activateDesktop: (VTDesktop*) desktop usingTransition: (PNTransitionType) type withOptions: (PNTransitionOption) option withDuration: (float) duration {
	// if we got passed the active desktop, we do not do anything 
	if ([[self activeDesktop] isEqual: desktop])
		return; 
	
	[self doActivateDesktop: desktop usingTransition: type withOptions: option andDuration: duration]; 
}

- (void) activateDesktopInDirection: (VTDirection) direction {
	// get desktop 
	VTDesktop* desktop = [[[VTLayoutController sharedInstance] activeLayout] desktopInDirection: direction ofDesktop: [[VTDesktopController sharedInstance] activeDesktop]]; 
	
	[self doActivateDesktop: desktop withDirection: direction]; 
}

#pragma mark -
#pragma mark Desktop persistency 

- (void) serializeDesktops {
	// iterate over all desktops and archive them 
	NSEnumerator*	desktopIter	= [mDesktops objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		NSString* file = [[VTDesktop virtualDesktopPath: desktop] 
			stringByAppendingPathComponent: [VTDesktop virtualDesktopMetadataName]];
		
		NSMutableDictionary* dictionary = [NSMutableDictionary dictionary]; 
		[desktop encodeToDictionary: dictionary]; 
		[dictionary writeToFile: file atomically: YES]; 
	}
}

- (void) deserializeDesktops {
	// we will create desktops as they are found in our desktop container directory and 
	// name them accordingly 
	NSString*		virtualDesktopPath		= [VTDesktop virtualDesktopContainerPath]; 
	
	// iterate all desktops found there 
	NSArray*		virtualDesktopFiles		= [[NSFileManager defaultManager] directoryContentsAtPath: virtualDesktopPath]; 
	NSEnumerator*	virtualDesktopFilesIter	= [virtualDesktopFiles objectEnumerator]; 
	NSString*		virtualDesktopFile		= nil; 
	
	// desktop id 
	int  desktopId = [PNDesktop firstDesktopIdentifier]; 
	BOOL isDirectory; 	
	
	while (virtualDesktopFile = [virtualDesktopFilesIter nextObject]) {
		// check if the current file is a directory
		NSString* targetPath = [virtualDesktopPath stringByAppendingPathComponent: virtualDesktopFile]; 
		[[NSFileManager defaultManager] fileExistsAtPath: targetPath isDirectory: &isDirectory]; 
		
		if (isDirectory == YES) {
			NSString*	metadataPath	= [targetPath stringByAppendingPathComponent: [VTDesktop virtualDesktopMetadataName]]; 
			VTDesktop*	desktop			= [[VTDesktop alloc] initWithName: [virtualDesktopFile lastPathComponent] identifier: desktopId];  
			
			// check if there is a metafile to load and if there is, load it ;) 
			if ([[NSFileManager defaultManager] fileExistsAtPath: metadataPath]) {
				NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile: metadataPath]; 
				if (dictionary)
					[desktop decodeFromDictionary: dictionary]; 
			}
			
			// insert into our array of desktops 
			[self insertObject: desktop inDesktopsAtIndex: [mDesktops count]]; 
			
			// and release temporary instance 
			[desktop release]; 
			
			desktopId++; 
		}
	}
	
	// if we still have zero desktops handy, we will trigger creation of 
	// our default desktops 
	if ([mDesktops count] == 0)
		[self createDefaultDesktops]; 
	
	VTDesktop* activeDesktop = [[[self activeDesktop] retain] autorelease]; 
	
	// bind to active desktop 
	[activeDesktop addObserver: self forKeyPath: @"managesIconset" options: NSKeyValueObservingOptionNew context: NULL]; 
	[activeDesktop addObserver: self forKeyPath: @"showsBackground" options: NSKeyValueObservingOptionNew context: NULL]; 
	[activeDesktop addObserver: self forKeyPath: @"desktopBackground" options: NSKeyValueObservingOptionNew context: NULL]; 
	
	// and apply settings of active desktop 
	if ([activeDesktop showsBackground])
		[self applyDesktopBackground]; 
		
	// iconset
	if ([activeDesktop managesIconset]) 
		[activeDesktop showIconset]; 
	else
		[activeDesktop hideIconset]; 	
}

#pragma mark -
- (void) applyDecorationPrototype: (BOOL) overwrite {
	// we walk through all desktops and attach the decoration primitives from our 
	// prototype if if is not included yet... 
	NSEnumerator*	desktopIter		= [mDesktops objectEnumerator]; 
	VTDesktop*		desktop			= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		[self applyDecorationPrototypeForDesktop: desktop overwrite: overwrite]; 
	}
}

#pragma mark -
#pragma mark Notification sinks

- (void) onDesktopBackgroundChanged: (NSNotification*) notification {
	// ignore if we expected it because we triggered the change 
	if (mExpectingBackgroundChange) {
		mExpectingBackgroundChange = NO; 
		return; 
	}
	
	// otherwise get the background picture and set it as the default 
	ZEN_ASSIGN_COPY(mDefaultDesktopBackgroundPath, [VTDesktop currentDesktopBackground]); 
		
	// and propagate to existing desktops 
	[[self desktops] makeObjectsPerformSelector: @selector(setDefaultDesktopBackgroundPath:) withObject: mDefaultDesktopBackgroundPath]; 
}

- (void) onUpdateDesktops: (NSTimer*) timer {
	[mDesktops makeObjectsPerformSelector: @selector(updateDesktop)]; 
	[NSTimer scheduledTimerWithTimeInterval: 1.5 target: self selector: @selector(onUpdateDesktops:) userInfo: nil repeats: NO]; 
}

- (void) onDesktopWillChange: (NSNotification*) notification {
	VTDesktop* desktop = [[[self activeDesktop] retain] autorelease]; 
	
	// propagate key change 
	[self willChangeValueForKey: @"activeDesktop"]; 
	
	// do not process further if the changed desktop is already the active one 
	if ([[notification object] isEqual: desktop])
		return; 
	
	// propagate key change for previous desktop 
	[self willChangeValueForKey: @"previousDesktop"]; 
	// remember the old desktop for the last desktop 
	ZEN_ASSIGN(mPreviousDesktop, [self activeDesktop]); 
	// propagate key change for previous desktop completed 
	[self didChangeValueForKey: @"previousDesktop"]; 
	
	// handle iconset
	if ([desktop managesIconset])
		[desktop hideIconset]; 

	// handle background image changes... if we are currently displaying a 
	// custom image, next desktop has to overwrite it... 
	if ([desktop showsBackground])  {
		mNeedDesktopBackgroundUpdate = YES;
	}
	else {
		mNeedDesktopBackgroundUpdate = NO; 
	}

	[VTDesktop updateDesktopPath]; 
	
	// unbind desktop 
	[desktop removeObserver: self forKeyPath: @"managesIconset"]; 
	[desktop removeObserver: self forKeyPath: @"showsBackground"]; 
	[desktop removeObserver: self forKeyPath: @"desktopBackground"]; 
}

- (void) onDesktopDidChange: (NSNotification*) notification {
	VTDesktop* desktop = [[[self activeDesktop] retain] autorelease]; 
	
	// bind desktop 
	[desktop addObserver: self forKeyPath: @"managesIconset" options: NSKeyValueObservingOptionNew context: NULL]; 
	[desktop addObserver: self forKeyPath: @"showsBackground" options: NSKeyValueObservingOptionNew context: NULL]; 
	[desktop addObserver: self forKeyPath: @"desktopBackground" options: NSKeyValueObservingOptionNew context: NULL]; 

	// handle iconset 
	if ([desktop managesIconset])
		[desktop showIconset]; 
	
	// handle background picture 
	if (mNeedDesktopBackgroundUpdate || [desktop showsBackground]) {
		[self applyDesktopBackground]; 
	}
	mNeedDesktopBackgroundUpdate = NO; 
	
	[VTDesktop updateDesktopPath]; 
	
	[self didChangeValueForKey: @"activeDesktop"]; 
}

#pragma mark -
#pragma mark KVO Sink 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString: @"showsBackground"] || [keyPath isEqualToString: @"desktopBackground"]) {
		mExpectingBackgroundChange = YES; 
		
		// toggle background on and off 
		if ([[self activeDesktop] showsBackground])
			[[self activeDesktop] applyDesktopBackground]; 
		else 
			[[self activeDesktop] applyDefaultDesktopBackground]; 
	}
	else if ([keyPath isEqualToString: @"managesIconset"]) {
		// toggle iconset 
		if ([[self activeDesktop] managesIconset]) 
			[[self activeDesktop] showIconset]; 
		else
			[[self activeDesktop] hideIconset]; 
	}
}

@end 

#pragma mark -
@implementation VTDesktopController (Private) 

- (void) createDefaultDesktops {
	NSArray* defaultDesktops = nil; 
	
	// try to find the defaults definition in the main bundle 
	NSString* defaultsPath = [[NSBundle mainBundle] pathForResource: @"DefaultDesktops" ofType: @"plist"]; 
	if (defaultsPath == nil) {
		// eeeks, could not find our default desktops, lets come up with something 
		// at least
		defaultDesktops = [NSArray arrayWithObjects: @"Main Desktop", "eDesktop", "Fun", "Misc", nil]; 
	}
	else {
		defaultDesktops = [NSArray arrayWithContentsOfFile: defaultsPath]; 
	}
	
	// now iterate and create desktops 
	NSEnumerator*	desktopNameIter	= [defaultDesktops objectEnumerator]; 
	NSString*		desktopName		= nil; 
	int				desktopId		= [PNDesktop firstDesktopIdentifier]; 
	
	while (desktopName = [desktopNameIter nextObject]) {
		// create a nice desktop
		VTDesktop* desktop = [VTDesktop desktopWithName: desktopName identifier: desktopId];  
		// add it 
		[self insertObject: desktop inDesktopsAtIndex: [mDesktops count]]; 
		
		// next id
		desktopId++; 
	}
}

#pragma mark -
- (VTDesktop*) desktopForId: (int) identifier {
	NSEnumerator*	desktopIter	= [mDesktops objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		if ([desktop identifier] == identifier)
			return desktop; 
	}
	
	return nil; 	
}

#pragma mark -

- (void) doActivateDesktop: (VTDesktop*) desktop withDirection: (VTDirection) direction {
	if (direction == kVtDirectionNone)
		return;
	
	PNTransitionType type;
	PNTransitionOption option;
	float duration;
		
	// Make sure transition is enabled
	if ([[NSUserDefaults standardUserDefaults] boolForKey:VTDesktopTransitionEnabled]) {
		
		// fetch user default transition type, option and duration
		type     = [[NSUserDefaults standardUserDefaults] integerForKey: VTDesktopTransitionType];
		option   = [[NSUserDefaults standardUserDefaults] integerForKey: VTDesktopTransitionOptions];
		duration = [[NSUserDefaults standardUserDefaults] floatForKey:   VTDesktopTransitionDuration];
		
		// decide on the option if we should to 
		//if (option == kPnOptionAny) {
			// decide based on the direction 
			switch (direction) {
				case kVtDirectionNorth: 
					option = kPnOptionDown; 
					break; 
				case kVtDirectionSouth: 
					option = kPnOptionUp; 
					break; 
				case kVtDirectionWest: 
					option = kPnOptionRight; 
					break; 
				case kVtDirectionEast: 
					option = kPnOptionLeft; 
					break;
				case kVtDirectionNortheast: 
					option = kPnOptionTopRight; 
					break; 
				case kVtDirectionSoutheast: 
					option = kPnOptionBottomRight; 
					break; 
				case kVtDirectionSouthwest: 
					option = kPnOptionBottomLeft; 
					break; 
				case kVtDirectionNorthwest: 
					option = kPnOptionTopLeft; 
					break; 
					
				default: 
					option = kPnOptionLeft; 
			}
			
		//}
		
		// decide type 
		if (type == kPnTransitionAny) {
			type = 1 + (random() % 9); 
		}
	} else {
		type = kPnTransitionNone;
		option = kPnOptionAny;
		duration = 0.0;
	}
	// now do it ;) 
	[self doActivateDesktop: desktop usingTransition: type withOptions: option andDuration: duration]; 
}

- (void) doActivateDesktop: (VTDesktop*) desktop usingTransition: (PNTransitionType) type withOptions: (PNTransitionOption) option andDuration: (float) duration {
	// again, do the check for the active desktop and do not allow any switch resulting in the 
	// same desktop 
	if ([desktop isEqual: [self activeDesktop]])
		return;
		
	// we do not allow kPnOptionAny or kPnTransitionAny here (assuming we're donig any transition)
	if (type == kPnTransitionAny)
		return;
	if (option == kPnOptionAny && type != kPnTransitionNone)
		return;
	// here we are sure we want to switch desktops, so we will trigger some 
	// notifications by hand to inform our plugins 
	NSMethodSignature*	signature	= [NSMethodSignature methodSignatureWithReturnAndArgumentTypes: @encode(void), @encode(VTDesktop*), nil];
	NSInvocation*		invocation	= [NSInvocation invocationWithMethodSignature: signature];
	
	[invocation setSelector: @selector(onDesktopWillActivateNotification:)];
	[invocation setArgument: &desktop atIndex: 2];
	
	[[VTPluginCollection sharedInstance] makePluginsOfType: @protocol(VTPluginScript) performInvocation: invocation];
	
	// if there was no transition type given or the duration is below our threshold, we 
	// switch without animation 
	if (type == kPnTransitionNone || duration < 0.1) {
		[desktop activate]; 
	} else {
		[desktop activateWithTransition: type option: option duration: duration]; 
	}
	// and again to tell our clients we are done 
	signature	= [NSMethodSignature methodSignatureWithReturnAndArgumentTypes: @encode(void), @encode(VTDesktop*), nil];
	invocation	= [NSInvocation invocationWithMethodSignature: signature];
	
	[invocation setSelector: @selector(onDesktopDidActivateNotification:)];
	[invocation setArgument: &desktop atIndex: 2];
	
	[[VTPluginCollection sharedInstance] makePluginsOfType: @protocol(VTPluginScript) performInvocation: invocation];
	
}
	
#pragma mark -
- (void) applyDecorationPrototypeForDesktop: (VTDesktop*) desktop overwrite: (BOOL) overwrite {
	if (overwrite == YES) {
		// we will now remove all existing primitives and insert 
		// the new ones in their place 
		while ([[[desktop decoration] decorationPrimitives] count] > 0)
			[[desktop decoration] delDecorationPrimitive: [[[desktop decoration] decorationPrimitives] objectAtIndex: 0]]; 
	}
	
	NSEnumerator*			deskPrimitiveIter	= [[[desktop decoration] decorationPrimitives] objectEnumerator]; 
	VTDecorationPrimitive*	deskPrimitive		= nil; 
	NSMutableArray*			deskPrimitiveTypes	= [[NSMutableArray alloc] init]; 

	while (deskPrimitive = [deskPrimitiveIter nextObject]) {
		if ([deskPrimitiveTypes containsObject: NSStringFromClass([deskPrimitive class])] == NO)
			[deskPrimitiveTypes addObject: NSStringFromClass([deskPrimitive class])]; 
	}
	
	NSEnumerator*			primitiveIter		= [[mDecorationPrototype decorationPrimitives] objectEnumerator]; 
	VTDecorationPrimitive*	primitive			= nil; 
	
	while (primitive = [primitiveIter nextObject]) {
		// check if the desktop already contains a primitive of the passed type 
		if ([deskPrimitiveTypes containsObject: NSStringFromClass([primitive class])])
			continue;
		
		// copy the primitive 
		VTDecorationPrimitive* clonedPrimitive = [primitive copy]; 
		// and add the clone to our desktop decoration primitives 
		[[desktop decoration] addDecorationPrimitive: clonedPrimitive]; 
	}
	
	[deskPrimitiveTypes release];
}

- (void) applyDesktopBackground {
	VTDesktop* desktop = [[[self activeDesktop] retain] autorelease]; 
	mExpectingBackgroundChange = YES; 
	
	if ([desktop showsBackground] && [desktop desktopBackground] != nil)
		[desktop applyDesktopBackground]; 
}

@end 
