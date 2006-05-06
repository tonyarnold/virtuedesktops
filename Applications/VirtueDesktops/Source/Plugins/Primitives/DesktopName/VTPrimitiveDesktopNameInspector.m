/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTPrimitiveDesktopNameInspector.h"
#import "VTDesktopNamePrimitive.h"
#import <Zen/Zen.h> 

@implementation VTPrimitiveDesktopNameInspector

- (id) init {
	if (self = [super init]) {
		[NSBundle loadNibNamed: @"PrimitiveDesktopNameInspector" owner: self]; 
		// and assign main view 
		mMainView = [[mWindow contentView] retain]; 
		mPreviousResponder = nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mMainView); 
	ZEN_RELEASE(mPreviousResponder); 
	
	[super dealloc]; 
}

- (void) awakeFromNib {
}

- (IBAction) showFontPanel: (id) sender {
	if ([[[NSFontManager sharedFontManager] fontPanel: YES] isVisible]) 
		return; 
	
	// set the selected font 
	[[NSFontManager sharedFontManager] setSelectedFont: [(VTDesktopNamePrimitive*)mInspectedObject font] isMultiple: NO]; 
	[[NSFontManager sharedFontManager] setDelegate: self]; 
	
	mPreviousResponder = [[[mMainView window] firstResponder] retain]; 
	[[mMainView window] makeFirstResponder: self]; 
	
	// and show the panel 
	[[NSFontManager sharedFontManager] orderFrontFontPanel: sender]; 
}

- (void) changeFont: (id) sender {
	NSFont* oldFont = [(VTDesktopNamePrimitive*)mInspectedObject font]; 
	NSFont* newFont = [sender convertFont: oldFont]; 
	
	// and set it in our object 
	[(VTDesktopNamePrimitive*)mInspectedObject setFont: newFont]; 
}

- (void) windowWillClose: (NSNotification*) aNotification {
	// reset the first responder 
	[[mMainView window] makeFirstResponder: mPreviousResponder]; 
	ZEN_RELEASE(mPreviousResponder); 
}

@end
