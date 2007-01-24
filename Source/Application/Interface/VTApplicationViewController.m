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

#import "VTApplicationViewController.h"
#import "VTApplicationRunningTransformer.h"
#import "VTApplicationRunningColorTransformer.h" 
#import "VTDesktopIdTransformer.h" 
#import "VTWindowStickyStateTransformer.h" 
#import "VTPreferenceKeys.h" 
#import "VTDesktopController.h"
#import "VTLayoutController.h"
#import "VTApplicationController.h"

@interface PNWindow (VTApplicationViewController)
- (void) setStickyObject: (NSNumber*) state; 
@end

@interface VTApplicationViewController (Persistency)
- (void) synchronize; 
@end 

#pragma mark -
@interface VTApplicationViewController (Selection) 
- (PNWindow*) selectedWindow;
- (VTApplicationWrapper*) selectedApplication; 
@end

#pragma mark -
@implementation VTApplicationViewController

+ (void) initialize {
	NSValueTransformer* transformer = nil; 
	
	transformer = [[[VTApplicationRunningTransformer alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTApplicationRunningString"]; 

	transformer = [[[VTApplicationRunningColorTransformer alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTApplicationRunningColor"]; 

	transformer = [[[VTDesktopIdTransformer alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTDesktopIdToInstance"]; 
	
	transformer = [[[VTWindowStickyStateImage alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTWindowStickyStateImage"]; 

	transformer = [[[VTWindowStickyStateWidgetImage alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTWindowStickyStateWidgetImage"]; 

	transformer = [[[VTWindowStickyStateWidgetAlternateImage alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTWindowStickyStateWidgetAlternateImage"]; 
	
}

- (id) init {
	if (self = [super initWithWindowNibName: @"VTApplicationInspector"]) {
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	[self synchronize]; 
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 

- (NSArray*) availableDesktops {
	return [[[VTLayoutController sharedInstance] activeLayout] orderedDesktops]; 
}

#pragma mark -
#pragma mark NSObject 
- (void) windowDidLoad {
	// prepare application controller 
	[mApplicationsController bind: @"contentArray" toObject: [VTApplicationController sharedInstance] withKeyPath: @"applications" options: nil];
	// register for changes to the desktops collection 
	[[[VTLayoutController sharedInstance] activeLayout] addObserver: self 
														 forKeyPath: @"orderedDesktops"
															options: NSKeyValueObservingOptionNew
															context: NULL]; 
	
	// set delegate to self 
	[[self window] setDelegate: self]; 
}

- (void) windowWillClose: (NSNotification*) notification {
	[self synchronize]; 
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context {
	if ([keyPath isEqualToString: @"orderedDesktops"]) {
		[self willChangeValueForKey: @"availableDesktops"]; 
		[self didChangeValueForKey: @"availableDesktops"]; 
	}
}

#pragma mark -
#pragma mark Actions 
- (IBAction) toggleSelectedWindowStickyState: (id) sender {
	PNWindow* window = [self selectedWindow]; 
	
	if (window == nil)
		return;
  
	// toggle window state 
	[window setSticky: ![window isSticky]]; 
}

- (IBAction) removeApplication: (id) sender {
	VTApplicationWrapper* application = [self selectedApplication]; 
	
	if (application == nil || [application canBeRemoved] == NO)
		return; 
	
	[[VTApplicationController sharedInstance] detachApplication: application]; 
}

@end

#pragma mark -
@implementation VTApplicationViewController (Selection) 

- (PNWindow*) selectedWindow {
	return [mWindowsController valueForKeyPath: @"selectedObject"]; 
}

- (VTApplicationWrapper*) selectedApplication {
	int selectionIndex = [mApplicationsController selectionIndex]; 
	
	if (selectionIndex == NSNotFound) 
		return nil; 
	
	return [[[VTApplicationController sharedInstance] applications] objectAtIndex: selectionIndex];
}

@end 

#pragma mark -
@implementation VTApplicationViewController (Persistency)

- (void) synchronize {
	// code preferences 
	NSMutableDictionary* applicationDict = [NSMutableDictionary dictionary]; 
	[[VTApplicationController sharedInstance] encodeToDictionary: applicationDict]; 
	
	// write to preferences 
	[[NSUserDefaults standardUserDefaults] setObject: applicationDict forKey: VTPreferencesApplicationsName]; 

	// and sync 
	[[NSUserDefaults standardUserDefaults] synchronize]; 	
}

@end 

@implementation PNWindow (VTApplicationViewController)
- (void) setStickyObject: (NSNumber*) state {
	[self setSticky: [state boolValue]];
}
@end
