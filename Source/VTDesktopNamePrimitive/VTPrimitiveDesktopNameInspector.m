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

#import "VTPrimitiveDesktopNameInspector.h"
#import "VTDesktopNamePrimitive.h"
#import <Zen/Zen.h> 

@implementation VTPrimitiveDesktopNameInspector

- (id) init {
	if (self = [super init]) {
		[NSBundle loadNibNamed: @"PrimitiveTextInspector" owner: self]; 
		
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
  // Desktop name is auto-populated, and should not be modifiable from here
  [mTextField setEditable: NO];
  [mTextField setEnabled: NO];
}

- (IBAction) showFontPanel: (id) sender {
  NSFontManager *fontManager  = [NSFontManager sharedFontManager];
  NSFontPanel   *fontPanel    = [fontManager fontPanel: YES];
  
	if ([fontPanel isVisible]) 
		return;
  
	[fontManager setSelectedFont: [(VTDesktopNamePrimitive*)mInspectedObject font] isMultiple: NO];
  [fontManager setSelectedAttributes: [(VTDesktopNamePrimitive*)mInspectedObject fontAttributes] isMultiple: NO];
  [fontManager setDelegate: self];
  
	
	mPreviousResponder = [[[mMainView window] firstResponder] retain]; 
	[[mMainView window] makeFirstResponder: self]; 
	
	// …and show the panel
	[fontManager orderFrontFontPanel: sender];
}

- (unsigned int) validModesForFontPanel: (NSFontPanel *) fontPanel {
  unsigned int  ret = NSFontPanelStandardModesMask;
  ret ^= NSFontPanelUnderlineEffectModeMask;
  ret ^= NSFontPanelStrikethroughEffectModeMask;
  ret ^= NSFontPanelTextColorEffectModeMask;
  ret ^= NSFontPanelDocumentColorEffectModeMask;
  return ret;
} 

- (void) changeFont: (id) sender {
	NSFont* oldFont = [(VTDesktopNamePrimitive*)mInspectedObject font]; 
	NSFont* newFont = [sender convertFont: oldFont]; 
	[(VTDesktopNamePrimitive*)mInspectedObject setFont: newFont]; 
}

- (void) changeAttributes: (id) sender {
  NSDictionary* oldAttributes = [(VTDesktopNamePrimitive*)mInspectedObject fontAttributes];
  NSDictionary* newAttributes = [sender convertAttributes: oldAttributes]; 
  NSShadow* textShadow = [newAttributes objectForKey:@"NSShadow"];
  if (nil != textShadow)
    [(VTDesktopNamePrimitive*)mInspectedObject setFontShadow: textShadow];
}

- (void) windowWillClose: (NSNotification*) aNotification {
	// reset the first responder 
	[[mMainView window] makeFirstResponder: mPreviousResponder]; 
	ZEN_RELEASE(mPreviousResponder); 
}

@end
