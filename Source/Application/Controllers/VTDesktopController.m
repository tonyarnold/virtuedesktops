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

#import "VTDesktopController.h"
#import "VTDesktopDecorationController.h" 
#import "VTPreferences.h" 
#import "VTDesktopLayout.h" 
#import "VTLayoutController.h" 
#import "VTNotifications.h" 
#import "VTPluginCollection.h" 
#import "VTPluginScript.h" 
#import "VTDesktopBackgroundHelper.h" 
#import "VTApplicationWrapper.h"
#import "VTApplicationController.h"

#import <Zen/Zen.h> 

#define VTDesktops @"VTDesktops"

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
		_desktops											= [[NSMutableArray alloc] init];
		mPreviousDesktop							= nil; 
		mSnapbackDesktop							= nil; 
		mDecorationPrototype					= nil; 
		mExpectingBackgroundChange		= NO; 
		
		ZEN_ASSIGN(mDefaultDesktopBackgroundPath, [[VTDesktopBackgroundHelper sharedInstance] background]); 
		
		// Register as observer for desktop switches 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWillChange:) name: kPnOnDesktopWillActivate object: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidChange:) name: kPnOnDesktopDidActivate object: nil];
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopBackgroundChanged:) name: VTBackgroundHelperDesktopChangedName object: VTBackgroundHelperDesktopChangedObject]; 
		
    /* *  
      * Expose SwitchTo(Next|Prev)Workspace to the DistributedNotificationCenter. 
      * 
      * Initial patch to archive something similar to 
      * [http://blog.medallia.com/2006/05/smacbook_pro.html] 
        */ 
		// Added 2006-05-25 Moritz Angermann - for the Apple Motion Sensor triggered DesktopSwitching 
		[[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(onNextEastDesktopRequest:) name: @"SwitchToNextWorkspace" object: nil]; 
		
		// Added 2006-05-25 Moritz Angermann - for the Apple Motion Sensor triggered DesktopSwitching 
		[[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(onNextWestDesktopRequest:) name: @"SwitchToPrevWorkspace" object: nil];
		
		// create timer loop to update desktops 
		[NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(onUpdateDesktops:) userInfo: nil repeats: NO]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {		
	// get rid of observer status 
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self]; 
	
	// get rid of attributes 
	ZEN_RELEASE(_desktops);
  ZEN_RELEASE(mApplications);
  ZEN_RELEASE(mDesktopWatchers);
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

- (NSMutableArray*) desktops {
	return _desktops;
}

- (void) setDesktops: (NSArray*)newDesktops {
	if (_desktops != newDesktops)
	{
    [_desktops autorelease];
    _desktops = [[NSArray alloc] initWithArray: newDesktops];
	}
}

- (void) addInDesktops: (VTDesktop*) desktop {
	// and add 
	[self insertObject: desktop inDesktopsAtIndex: [_desktops count]]; 
}

- (void) insertObject: (VTDesktop*) desktop inDesktopsAtIndex: (unsigned int) objIndex {
	[[NSNotificationCenter defaultCenter] postNotificationName: VTDesktopWillAddNotification object: desktop]; 
	// notification that canDelete will change 
	[self willChangeValueForKey: @"canAdd"];
	[self willChangeValueForKey: @"canDelete"]; 
	
	// and add 
	[_desktops insertObject: desktop atIndex: objIndex]; 
	
	// attach the decoration 
	[[VTDesktopDecorationController sharedInstance] attachDecoration: [desktop decoration]]; 
	
	// and apply our default decoration if we should 
	if (mUsesDecorationPrototype && mDecorationPrototype) {
		[self applyDecorationPrototypeForDesktop: desktop overwrite: NO]; 
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: VTDesktopDidAddNotification object: desktop]; 
	
	// here we are sure we created the desktop, so we will trigger some 
	// notifications by hand to inform our plugins 
	NSMethodSignature*	signature   = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes: @encode(void), @encode(VTDesktop*), nil];
	NSInvocation*       invocation	= [NSInvocation invocationWithMethodSignature: signature];
	
	[invocation setSelector: @selector(onDesktopDidCreateNotification:)];
	[invocation setArgument: &desktop atIndex: 2];
	
	[[VTPluginCollection sharedInstance] makePluginsOfType: @protocol(VTPluginScript) performInvocation: invocation];	
	
	// KVO notification for canAdd/canDelete
	[self didChangeValueForKey: @"canAdd"];
	[self didChangeValueForKey: @"canDelete"]; 	
}

- (void) removeObjectFromDesktopsAtIndex: (unsigned int) objIndex {
	VTDesktop* desktopToRemove = [[_desktops objectAtIndex: objIndex] retain]; 
	
	// here we are sure we want to delete the desktop, so we will trigger some 
	// notifications by hand to inform our plugins 
	NSMethodSignature*	signature   = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes: @encode(void), @encode(VTDesktop*), nil];
	NSInvocation*       invocation	= [NSInvocation invocationWithMethodSignature: signature];
	
	[invocation setSelector: @selector(onDesktopWillDeleteNotification:)];
	[invocation setArgument: &desktopToRemove atIndex: 2];
	
	[[VTPluginCollection sharedInstance] makePluginsOfType: @protocol(VTPluginScript) performInvocation: invocation];
	
	
	// check which desktop to move them to 
	int targetIndex = objIndex - 1; 
	if (targetIndex < 0)
		targetIndex = [_desktops count] - 1; 
	
	VTDesktop* target = [_desktops objectAtIndex: targetIndex]; 
	
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
	
	// detach the decoration 
	[[VTDesktopDecorationController sharedInstance] detachDecorationForDesktop: desktopToRemove];
	
	// now check if we should move windows 
	if (([[NSUserDefaults standardUserDefaults] boolForKey: VTWindowsCollectOnDelete]) && 
      ([_desktops count] > 1)) {
    [desktopToRemove moveAllWindowsToDesktop: target]; 
		}
	
	// and remove the object 
	[self willChangeValueForKey: @"canAdd"];
	[self willChangeValueForKey: @"canDelete"]; 
	[_desktops removeObjectAtIndex: objIndex]; 
	[self didChangeValueForKey: @"canAdd"];
	[self didChangeValueForKey: @"canDelete"]; 
	
	[[NSNotificationCenter defaultCenter] postNotificationName: VTDesktopDidRemoveNotification object: desktopToRemove]; 
	ZEN_RELEASE(desktopToRemove); 
	
	// check if we got any desktops left, and if we don't, we will create our
	// default desktops 
	if ([_desktops count] == 0)
		[self createDefaultDesktops]; 
}

- (void) sendWindowUnderCursorBack {
	[[self activeDesktop] sendWindowUnderCursorBack];
}

- (void) moveWindowUnderCursorToDesktop: (VTDesktop*) desktop {
    // Retreive the window
    PNDesktop *activeDesktop = [self activeDesktop];
    PNWindow *window = [activeDesktop windowUnderCursor];
    if (!window) {
        return;
    }
    
    // Check the application: do not move windows of application bounded to a desktop
    VTApplicationWrapper *wrapper = [[VTApplicationController sharedInstance] applicationForPid: [window ownerPid]];
    if ([wrapper boundDesktop]) {
        return;
    }
	[window setDesktop:desktop];
}

#pragma mark -
- (BOOL) canAdd {
	return ([[[VTLayoutController sharedInstance] activeLayout] maximumNumberOfDesktops] > [_desktops count]);	
}

- (BOOL) canDelete {
	return ([_desktops count] > 1); 
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
	NSEnumerator*	desktopIter		= [_desktops objectEnumerator]; 
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

- (VTDesktop*) getDesktopInDirection: (VTDirection) direction {
	return [[[VTLayoutController sharedInstance] activeLayout] desktopInDirection: direction ofDesktop: [[VTDesktopController sharedInstance] activeDesktop]];
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
	NSEnumerator*		desktopIter		= [_desktops objectEnumerator]; 
	VTDesktop*			desktop				= nil;
	NSMutableArray*	desktopsArray = [[NSMutableArray alloc] init];
	NSMutableArray* desktopsUUIDs = [[NSMutableArray alloc] init];
	
	while (desktop = [desktopIter nextObject])
	{
		// We ensure that preferences are not corrupt due to the bug in 0.53r210
		if ([desktopsUUIDs containsObject: [desktop uuid]]) {
			continue;
		}
		[desktopsUUIDs addObject: [desktop uuid]];
		
		// ...and continue
		[desktopsArray removeObjectIdenticalTo: desktop];
		NSMutableDictionary* dictionary = [[NSMutableDictionary dictionary] retain];
		[desktop encodeToDictionary: dictionary];
		[desktopsArray insertObject: dictionary atIndex: [desktopsArray count]];
		[dictionary release];
	}
  
  // write to preferences 
	[[NSUserDefaults standardUserDefaults] setObject: desktopsArray forKey: VTDesktops]; 
	// and sync 
	[[NSUserDefaults standardUserDefaults] synchronize];
  [desktopsArray release];
  [desktopsUUIDs release];
}

- (void) deserializeDesktops {
	// desktop id 
	int  desktopId = [PNDesktop firstDesktopIdentifier];
    NSArray* serialisedDesktops = [[NSUserDefaults standardUserDefaults] objectForKey: VTDesktops];
	NSEnumerator*     serialisedDesktopsIterator	= [serialisedDesktops objectEnumerator];
	NSDictionary*     serialisedDesktopDictionary;
	NSMutableArray*   uuidArray = [[NSMutableArray alloc] init];
	
	while (serialisedDesktopDictionary = [serialisedDesktopsIterator nextObject]) {
		if ([uuidArray containsObject: [serialisedDesktopDictionary valueForKey: @"UUID"]]) {
			continue;
		}
		[uuidArray addObject: [serialisedDesktopDictionary valueForKey: @"UUID"]];
		VTDesktop*	desktop	= [[VTDesktop alloc] initWithName: [serialisedDesktopDictionary valueForKey: @"name"]  identifier: desktopId];  
		[desktop decodeFromDictionary: serialisedDesktopDictionary]; 
		
		// insert into our array of desktops 
		[self addInDesktops: desktop]; 
		
		// and release temporary instance 
		[desktop release]; 
		
		desktopId++; 
	}
	[uuidArray release];
  
	// if we still have zero desktops handy, we will trigger creation of our default desktops 
	if ([_desktops count] == 0) {
		[self createDefaultDesktops];
  } else if ([PNDesktop activeDesktopIdentifier] >= desktopId) {
    PNWindowList *list = [[PNWindowPool sharedWindowPool] windowsOnDesktopId:[PNDesktop activeDesktopIdentifier]];
    [list setDesktopId:(desktopId - 1)];
    [list release];
    [PNDesktop setDesktopId:(desktopId - 1)];
  }
		
	// bind to active desktop 
	[[self activeDesktop] addObserver: self forKeyPath: @"desktopBackground" options: NSKeyValueObservingOptionNew context: NULL]; 
	
	// and apply settings of active desktop 
	mExpectingBackgroundChange = YES;
	[self applyDesktopBackground];
}

#pragma mark -
- (void) applyDecorationPrototype: (BOOL) overwrite {
	// we walk through all desktops and attach the decoration primitives from our 
	// prototype if if is not included yet... 
	NSEnumerator*	desktopIter		= [_desktops objectEnumerator]; 
	VTDesktop*		desktop       = nil; 
	
	while (desktop = [desktopIter nextObject]) {
		[self applyDecorationPrototypeForDesktop: desktop overwrite: overwrite]; 
	}
}

#pragma mark -
#pragma mark Notification sinks

- (void) onDesktopBackgroundChanged: (NSNotification*) notification {
	// ignore if we expected it because we triggered the change 
	if ( (mExpectingBackgroundChange == YES) || ([[self activeDesktop] showsBackground] == YES) || ([mDefaultDesktopBackgroundPath isEqualToString: [[VTDesktopBackgroundHelper sharedInstance] background]] == YES)) {
		mExpectingBackgroundChange = NO;
		return; 
	}		
		
	// otherwise get the background picture and set it as the default
	ZEN_ASSIGN(mDefaultDesktopBackgroundPath, [[VTDesktopBackgroundHelper sharedInstance] background]);
	[[VTDesktopBackgroundHelper sharedInstance] setDefaultBackground: mDefaultDesktopBackgroundPath];
	
	
	// Propagate 
	[[self desktops] makeObjectsPerformSelector: @selector(setDefaultDesktopBackgroundIfNeeded:) withObject: mDefaultDesktopBackgroundPath];
}

- (void) onUpdateDesktops: (NSTimer*) timer {
	[[self desktops] makeObjectsPerformSelector: @selector(updateDesktop)]; 
	[NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(onUpdateDesktops:) userInfo: nil repeats: NO]; 
}

// Added 2006-05-25 Moritz Angermann - for the Apple Motion Sensor triggered DesktopSwitching 
- (void) onNextEastDesktopRequest: (NSNotification*) notification { 
	[self activateDesktopInDirection: kVtDirectionEast]; 
} 

// Added 2006-05-25 Moritz Angermann - for the Apple Motion Sensor triggered DesktopSwitching 
- (void) onNextWestDesktopRequest: (NSNotification*) notification { 
	[self activateDesktopInDirection: kVtDirectionWest]; 
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
	
	
	// Ensure object consistency.
	if ([[self activeDesktop] showsBackground] == NO) {
		[[VTDesktopBackgroundHelper sharedInstance] setDefaultBackground: [[VTDesktopBackgroundHelper sharedInstance] background]];
	}
  
	// unbind desktop 
	[desktop removeObserver: self forKeyPath: @"desktopBackground"];
}

- (void) onDesktopDidChange: (NSNotification*) notification {
	// bind desktop 
	[[self activeDesktop] addObserver: self forKeyPath: @"desktopBackground" options: NSKeyValueObservingOptionNew context: NULL];
	[self applyDesktopBackground]; 		
	[self didChangeValueForKey: @"activeDesktop"];
}


#pragma mark -
#pragma mark KVO Sink 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString: @"showsBackground"] || [keyPath isEqualToString: @"desktopBackground"]) {
		[self applyDesktopBackground];
	}
}

@end 

#pragma mark -
@implementation VTDesktopController (Private) 

- (void) createDefaultDesktops {
	NSString* defaultDesktopsPath = [[NSBundle bundleForClass: [VTDesktopController class]] pathForResource: @"DefaultDesktops" ofType: @"plist"];
  
  NSArray* defaultDesktops = [NSArray arrayWithContentsOfFile: defaultDesktopsPath];
  
  if ([defaultDesktops count] < 1)
    defaultDesktops = [NSArray arrayWithObjects: @"One.", @"Two.", @"Three.", nil];
  
	
	// now iterate and create desktops 
	NSEnumerator*	desktopNameIter	= [defaultDesktops objectEnumerator]; 
	NSString*			desktopName			= nil; 
	int						desktopId				=	[PNDesktop firstDesktopIdentifier]; 
	
	while (desktopName = [desktopNameIter nextObject]) {
		// create a nice desktop
		VTDesktop* desktop = [VTDesktop desktopWithName: desktopName identifier: desktopId];  
		// add it 
		[self insertObject: desktop inDesktopsAtIndex: [_desktops count]];
		
		// next id
		desktopId++; 
	}
	
	[self serializeDesktops];
}

#pragma mark -
- (VTDesktop*) desktopForId: (int) identifier {
	NSEnumerator*	desktopIter	= [_desktops objectEnumerator]; 
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

[self doActivateDesktop: desktop 
        usingTransition: type 
            withOptions: option 
            andDuration: duration];
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
	NSMethodSignature*	signature   = [NSMethodSignature methodSignatureWithReturnAndArgumentTypes: @encode(void), @encode(VTDesktop*), nil];
	NSInvocation*       invocation	= [NSInvocation invocationWithMethodSignature: signature];
	
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
	
	NSEnumerator*						deskPrimitiveIter			= [[[desktop decoration] decorationPrimitives] objectEnumerator]; 
	VTDecorationPrimitive*	deskPrimitive					= nil; 
	NSMutableArray*					deskPrimitiveTypes		= [[NSMutableArray alloc] init]; 
	
	while (deskPrimitive = [deskPrimitiveIter nextObject]) {
		if ([deskPrimitiveTypes containsObject: NSStringFromClass([deskPrimitive class])] == NO)
			[deskPrimitiveTypes addObject: NSStringFromClass([deskPrimitive class])]; 
	}
	
	NSEnumerator*           primitiveIter	= [[mDecorationPrototype decorationPrimitives] objectEnumerator]; 
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
	mExpectingBackgroundChange = YES;
	[[self activeDesktop] applyDesktopBackground]; 
}

- (NSString*) applicationSupportFolder {
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

@end 
