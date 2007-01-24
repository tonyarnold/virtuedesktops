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

#import "VTDecorationPrimitiveViewController.h"
#import "VTDecorationPrimitiveBindings.h" 
#import "VTDecorationPrimitivePositionMarkers.h" 
#import <Zen/Zen.h> 

@interface VTDecorationPrimitiveViewController (PositionView)
- (void) setupPositionView; 
- (void) cleanPositionView; 
- (void) updateEnabled; 
@end 

#pragma mark -
@implementation VTDecorationPrimitiveViewController

- (id) init {
	if (self = [super initWithWindowNibName: @"VTDecorationPrimitiveInspector"]) {
		mInspector = nil; 
		mPrimitive = nil; 
		
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark NSWindowController delegate 
- (void) windowDidLoad {
	// position view 
	[mPositionGrid setTarget: self]; 
	[mPositionGrid setAction: @selector(onPositionSelected:)]; 
}

#pragma mark -
#pragma mark Actions 
- (void) onPositionSelected: (id) sender {
	[mPrimitive setMarkerPosition: [mPositionGrid selectedMarker]];  
}

#pragma mark -
#pragma mark Actions 
- (void) startSheetForPrimitive: (VTDecorationPrimitive*) primitive inspector: (VTInspector*) inspector window: (NSWindow*) window delegate: (id) delegate didEndSelector: (SEL) selector {
	ZEN_ASSIGN(mPrimitive, primitive); 
	ZEN_ASSIGN(mInspector, inspector); 
	
	// prepare our view by setting the inspector view 
	[mInspectorContainer setContentView: [mInspector mainView]];
	// and prepare the controller 
	[mPrimitiveController setContent: mPrimitive]; 
	
	// notify inspector 
	[mInspector didSelect]; 
	
	[self setupPositionView]; 
	
	[[NSApplication sharedApplication] beginSheet: [self window]
								   modalForWindow: window
									modalDelegate: delegate
								   didEndSelector: selector
									  contextInfo: NULL];
}

- (IBAction) endSheet: (id) sender {
	[self cleanPositionView]; 
	
	[mPrimitiveController setContent: nil]; 
	[mInspectorContainer setContentView: nil]; 
	
	// notify inspector 
	[mInspector didUnselect]; 
	
	ZEN_RELEASE(mPrimitive); 
	ZEN_RELEASE(mInspector); 
	
	// close the window 
	[self close]; 
	// and end our modal session 
	[[NSApplication sharedApplication] endSheet: [self window]]; 
}

- (IBAction) positionSelectionChanged: (id) sender {
	[self updateEnabled]; 
}

@end

#pragma mark -
@implementation VTDecorationPrimitiveViewController (PositionView)
- (void) setupPositionView {	
	[mPositionGrid setMarkers: [mPrimitive supportedMarkers]]; 
	[mPositionGrid setSelectedMarker: [mPrimitive markerPosition]]; 
	
	[self updateEnabled]; 
}

- (void) cleanPositionView {
}

- (void) updateEnabled {
	if ([mRelativePositionButton state] == NSOnState) {
		[mPositionGrid setEnabled: YES]; 
	}
	else {
		[mPositionGrid setEnabled: NO];	
	}
}

@end 
