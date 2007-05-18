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

#import "VTPreferencesViewController.h"
#import "VTPreferences.h"
#import "NSUserDefaultsColor.h"
#import "VTTriggerController.h"
#import <Zen/Zen.h> 
#import "CGSPrivate.h"

#define		VTPreferencePaneName					@"VTPreferencePaneName"
#define		VTPreferencePaneHelpText			@"VTPreferencePaneHelpText"
#define		VTPreferencePaneImage					@"VTPreferencePaneImage"
#define		VTPreferencePaneBundle				@"VTPreferencePaneBundle"
#define		VTPreferencePaneLoaded				@"VTPreferencePaneLoaded"
#define		VTPreferencePaneInstance			@"VTPreferencePaneInstance"
#define		VTPreferencePaneRankingOrder	@"VTPreferencePaneRankingOrder"

@interface VTPreferencesViewController (Private)
- (void) showPreferencePane: (NSPreferencePane*) pane andAnimate: (BOOL) animate; 
- (NSString*) labelForBundle: (NSBundle*) bundle; 
- (NSString*) iconForBundle: (NSBundle*) bundle; 
- (NSString*) identifierForBundle: (NSBundle*) bundle; 
@end

#pragma mark -
@interface VTPreferencesViewController (Setup) 
- (void) setupPreferencePanes; 
- (void) setupPreferencePane: (NSMutableDictionary*) preferencePane; 
@end 

#pragma mark -
@interface VTPreferencesViewController (Visibility) 
- (void) showPreferencePane: (NSMutableDictionary*) preferencePane; 
- (NSMutableDictionary*) selectedPreferencePane; 
@end 

#pragma mark -
@interface NSSortDescriptor (Sorting)
+ (NSArray *) ascendingDescriptorsForKeys: (NSString *)firstKey,...;
@end

#pragma mark -
@implementation VTPreferencesViewController

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super initWithWindowNibName: @"VTPreferences"]) {
		// preference panes array 
		mAvailablePreferencePanes	= [[NSMutableArray alloc] init]; 
		mCurrentPane              = nil; 
		
		return self; 
	}

	return nil; 
}

- (void) dealloc {
	[[self window] setDelegate: nil]; 
	ZEN_RELEASE(mCurrentPane); 
	ZEN_RELEASE(mAvailablePreferencePanes); 

	[super dealloc]; 
}

#pragma mark -
#pragma mark NSWindowController delegate  

- (void) windowDidLoad {
	// set up array of preference panes we have to show
	[self setupPreferencePanes];
	// set content of our controller
	[mPreferencePanesController setContent: mAvailablePreferencePanes];
}

- (void) windowWillClose: (NSNotification*) notification {
	// send unselect notification 
	[mCurrentPane willUnselect]; 
	
	// write hotkeys 
	[[VTTriggerController sharedInstance] synchronize]; 
	// and write out preferences to be sure 
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[mCurrentPane didUnselect]; 
}

- (IBAction) showWindow: (id) sender {
	if (mCurrentPane) 
		[mCurrentPane willSelect]; 
	
	[super showWindow: sender];

	if (mCurrentPane)
		[mCurrentPane didSelect];
}

#pragma mark -
#pragma mark NSTableView delegate 
- (void) tableViewSelectionWillChange: (NSNotification*) aNotification { }

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification {
	[self showPreferencePane: [self selectedPreferencePane]]; 
}


@end 

#pragma mark -
@implementation VTPreferencesViewController(Private)

- (void) showPreferencePane: (NSPreferencePane*) pane andAnimate: (BOOL) animate {
	NSView* contentView = [[self window] contentView];
	NSView* oldView		= nil;
	
	if ([[contentView subviews] count]) 
		oldView = [[contentView subviews] objectAtIndex: 0];
	
	if (oldView == [pane mainView]) 
		return;
	
	NSRect newFrame = [[self window] frame];
	float newHeight = [[self window] frameRectForContentRect: [[pane mainView] frame]].size.height;
	newFrame.origin.y += newFrame.size.height - newHeight;
	newFrame.size.height = newHeight;
	
	// unselect old pane 
	if (mCurrentPane)
		[mCurrentPane willUnselect]; 
	
	if (oldView) 
		[oldView removeFromSuperview];
	
	if (mCurrentPane)
		[mCurrentPane didUnselect]; 
	
	[[self window] setFrame: newFrame display: YES animate: animate];
	
	ZEN_ASSIGN(mCurrentPane, pane); 
	
	if (mCurrentPane) {
		// select new pane 
		[mCurrentPane willSelect]; 
		[[[self window] toolbar] setSelectedItemIdentifier: [[mPreferencePanes allKeysForObject: mCurrentPane] objectAtIndex: 0]]; 
		[contentView addSubview: [pane mainView]];
		[[self window] setDelegate: pane]; 
		[mCurrentPane didSelect]; 
	}
	else {
		[[self window] setDelegate: self]; 
	}
}

#pragma mark -
- (NSString*) labelForBundle: (NSBundle*) bundle {
	NSString* iconLabel = [bundle objectForInfoDictionaryKey: @"NSPrefPaneIconLabel"];
	if (!iconLabel)
		iconLabel = [bundle objectForInfoDictionaryKey: @"CFBundleName"]; 
	if (!iconLabel) 
		iconLabel = @"None"; 
	
	return iconLabel;
}

- (NSString*) iconForBundle: (NSBundle*) bundle {
	NSString* iconFile = [bundle objectForInfoDictionaryKey: @"NSPrefPaneIconFile"];
  
	if (!iconFile)
		iconFile = [bundle objectForInfoDictionaryKey: @"CFBundleIconFile"];
  
  if (!iconFile)
    iconFile = @"";
	
	return [bundle pathForImageResource: iconFile];
}

- (NSString*) identifierForBundle: (NSBundle*) bundle {
	return [bundle bundleIdentifier]; 
}

@end

#pragma mark -
@implementation VTPreferencesViewController (Visibility) 

- (void) showPreferencePane: (NSMutableDictionary*) preferencePane {
	// make sure we have the pane loaded, and if we need to load, show the loading
	// pane until we are finished 
	if ([[preferencePane objectForKey: VTPreferencePaneLoaded] boolValue] == NO) {
		// show the loading pane... 
		[mPreferencePaneContainer setContentView: mPreferencePaneLoading]; 
		
		// load our pane 
		[self setupPreferencePane: preferencePane];
	}
	
	// and show the pane 
	NSPreferencePane* pane = [preferencePane objectForKey: VTPreferencePaneInstance];

	[pane willSelect]; 
	[mCurrentPane willUnselect]; 
	
	[mPreferencePaneContainer setContentView: [pane mainView]]; 
	
	[mCurrentPane didUnselect]; 
	[pane didSelect]; 
	
	ZEN_ASSIGN(mCurrentPane, pane); 
}

- (NSMutableDictionary*) selectedPreferencePane {
	int selectionIndex = [mPreferencePanesController selectionIndex]; 
	
	// no selection, no primitive  
	if (selectionIndex == NSNotFound)
		return nil; 
	
	return [mAvailablePreferencePanes objectAtIndex: selectionIndex]; 
}

@end 

#pragma mark -
@implementation VTPreferencesViewController (Setup) 

- (void) setupPreferencePane: (NSMutableDictionary*) preferencePane {
	// load the pane 
	if ([[preferencePane objectForKey: VTPreferencePaneLoaded] boolValue] == YES)
		return; 
	
	NSBundle*			preferencePaneBundle	= [preferencePane objectForKey: VTPreferencePaneBundle]; 
	Class				preferencePaneClass		= [preferencePaneBundle principalClass]; 
	NSPreferencePane*	preferencePaneInstance	= [[preferencePaneClass alloc] initWithBundle: preferencePaneBundle];  
			
	// load the main view 
	[preferencePaneInstance loadMainView]; 
	
	// remove the keys we do not need any longer 
	[preferencePane removeObjectForKey: VTPreferencePaneBundle]; 
	// and add the instance 
	[preferencePane setObject: preferencePaneInstance forKey: VTPreferencePaneInstance]; 
	[preferencePane setObject: [NSNumber numberWithBool: YES] forKey: VTPreferencePaneLoaded]; 
}

- (void) setupPreferencePanes {
	// we will not immediately load the preference panes, but only find them and 
	// build up the array including all of our descriptors 
	NSEnumerator*		bundlePathIter;
	NSString*				currentBundlePath;
	
	// only load from our built-in plugins path 
	NSString* bundleSearchPath = [[NSBundle mainBundle] builtInPlugInsPath];
	bundlePathIter = [[[NSFileManager defaultManager] directoryContentsAtPath: bundleSearchPath] objectEnumerator];
	
	while (currentBundlePath = [bundlePathIter nextObject]) {
		if ([[currentBundlePath pathExtension] isEqualToString: @"prefPane"]) {
			// load the bundle 
			NSBundle* preferenceBundle = [NSBundle bundleWithPath: [bundleSearchPath stringByAppendingPathComponent: currentBundlePath]];
			// fetch the principle class and make some sanity check for the NSPreference class
			Class principalClass = [preferenceBundle principalClass];
			if ([principalClass isSubclassOfClass: [NSPreferencePane class]] == NO)
				continue; 
			
			// now read out the information we need 
			NSMutableDictionary*	preferencePaneDescriptor	= [NSMutableDictionary dictionary]; 
			NSString*							imagePath									= [[preferenceBundle resourcePath] stringByAppendingPathComponent: [preferenceBundle objectForInfoDictionaryKey: @"CFBundleIconFile"]];  
			
			[preferencePaneDescriptor setObject: preferenceBundle forKey: VTPreferencePaneBundle]; 
			[preferencePaneDescriptor setObject: imagePath forKey: VTPreferencePaneImage]; 
			[preferencePaneDescriptor setObject: [preferenceBundle objectForInfoDictionaryKey: @"NSPrefPaneIconLabel"] forKey: VTPreferencePaneName]; 
			[preferencePaneDescriptor setObject: [preferenceBundle objectForInfoDictionaryKey: VTPreferencePaneHelpText] forKey: VTPreferencePaneHelpText]; 
			[preferencePaneDescriptor setObject: [NSNumber numberWithBool: NO] forKey: VTPreferencePaneLoaded]; 
			[preferencePaneDescriptor setObject: [preferenceBundle objectForInfoDictionaryKey: VTPreferencePaneRankingOrder] forKey: VTPreferencePaneRankingOrder];

			// and add it to our array
			[mAvailablePreferencePanes addObject: preferencePaneDescriptor]; 
		}
	}	
	// Sort our array
	NSArray *descriptors = [NSSortDescriptor ascendingDescriptorsForKeys: VTPreferencePaneRankingOrder, VTPreferencePaneName, nil];
	[mAvailablePreferencePanes sortUsingDescriptors: descriptors];
}

@end 

#pragma mark -
@implementation  NSSortDescriptor (Sorting)

+ (NSArray *) ascendingDescriptorsForKeys: (NSString *)firstKey,...
{    
		id returnArray   = [[NSMutableArray arrayWithCapacity: 5] retain];
		va_list          keyList;
    
		NSString          * oneKey;
		NSSortDescriptor  * oneDescriptor;
		
		if (firstKey)
		{
				oneDescriptor = [[NSSortDescriptor alloc] initWithKey: firstKey
																										ascending: YES];
				[returnArray addObject: oneDescriptor];
				[oneDescriptor release];
				
				va_start (keyList, firstKey);
				
				while (oneKey = va_arg(keyList, NSString *))
				{
						oneDescriptor = [[NSSortDescriptor alloc] initWithKey: oneKey
																												ascending: YES];
						[returnArray addObject: oneDescriptor];
						[oneDescriptor release];
				}
				
				va_end (keyList);
		}
		
		return [returnArray autorelease];
		
}

@end