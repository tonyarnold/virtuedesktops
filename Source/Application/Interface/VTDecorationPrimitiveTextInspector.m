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

#import "VTDecorationPrimitiveTextInspector.h"
#import "VTDecorationPrimitiveText.h"
#import <Zen/Zen.h> 

@implementation VTDecorationPrimitiveTextInspector

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
	
	[super dealloc]; 
}

- (void) awakeFromNib { 
  // Ensure this field is modifiable
  [mTextField setEditable: YES];
  [mTextField setEnabled: YES];
}

- (IBAction) showFontPanel: (id) sender {
  NSFontManager *fontManager  = [NSFontManager sharedFontManager];
  NSFontPanel   *fontPane     = [fontManager fontPanel: YES];
	if ([fontPane isVisible]) 
		return;
  
	[fontManager setSelectedFont: [(VTDecorationPrimitiveText*)mInspectedObject font] isMultiple: NO];
  [fontManager setSelectedAttributes: [(VTDecorationPrimitiveText*)mInspectedObject fontAttributes] isMultiple: NO];
	[fontManager setDelegate: self];
  
	mPreviousResponder = [[[mMainView window] firstResponder] retain]; 
	[[mMainView window] makeFirstResponder: self];
	
	// Éand show the panel
	[fontManager orderFrontFontPanel: self];
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
	NSFont* oldFont = [(VTDecorationPrimitiveText*)mInspectedObject font]; 
	NSFont* newFont = [sender convertFont: oldFont];
	[(VTDecorationPrimitiveText*)mInspectedObject setFont: newFont]; 
}

- (void) changeAttributes: (id) sender {
  NSDictionary* oldAttributes = [(VTDecorationPrimitiveText*)mInspectedObject fontAttributes];
  NSDictionary* newAttributes = [sender convertAttributes: oldAttributes]; 
  NSShadow *textShadow = [newAttributes objectForKey:@"NSShadow"];
  if (nil != textShadow)
    [(VTDecorationPrimitiveText*)mInspectedObject setFontShadow: textShadow];
}

- (void) windowWillClose: (NSNotification*) aNotification {
	// Reset the first responder 
	[[mMainView window] makeFirstResponder: mPreviousResponder]; 
	ZEN_RELEASE(mPreviousResponder); 
}

@end
