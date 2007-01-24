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

#import "VTNotificationBezelView.h"
#import "NSBezierPathPlate.h"
#import <Zen/ZNMemoryManagementMacros.h>

#define kDefaultText @"VirtueDesktops"

enum {
	kRoundedRadius = 25,		//!< Used for our rounded rectangle background, 25 pixel radius is what apple likes here 
}; 

@implementation VTNotificationBezelView

#pragma mark -
#pragma mark Lifetime 

- (id) initWithFrame: (NSRect) frame {
	if (self = [super initWithFrame: frame]) {
		// attributes 
		mText			= nil; 
		mDesktop		= nil; 
		mDrawApplets	= NO; 
		
		NSShadow* textShadow = [[[NSShadow alloc] init] autorelease];
		[textShadow setShadowColor: [NSColor blackColor]];
		[textShadow setShadowOffset: NSMakeSize(0, -1)];
		[textShadow setShadowBlurRadius: 3];
    
    ZEN_ASSIGN_COPY(mShadow, textShadow);
		
		// desktop name attributes 
		mTextAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys: 
			[NSColor whiteColor], NSForegroundColorAttributeName,
			[NSFont boldSystemFontOfSize: 18], NSFontAttributeName,
			textShadow, NSShadowAttributeName,  
			nil] retain]; 
		
		return self;
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mShadow);
	ZEN_RELEASE(mTextAttributes); 
	ZEN_RELEASE(mText); 
	ZEN_RELEASE(mDesktop); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 

- (void) setText: (NSString*) text {
	ZEN_RELEASE(mText); 
	
	if (text == nil)
		mText = kDefaultText; 
	else
		ZEN_ASSIGN_COPY(mText, text); 

	[self setNeedsDisplay: YES]; 
}

- (void) setDesktop: (PNDesktop*) desktop {
	ZEN_ASSIGN(mDesktop, desktop); 
	
	[self setNeedsDisplay: YES]; 
}


#pragma mark -

- (BOOL) drawsApplets {
	return mDrawApplets; 
}

- (void) setDrawsApplets: (BOOL) flag {
	if (mDrawApplets == flag)
		return; 
	
	mDrawApplets = flag; 
	[self setNeedsDisplay: YES]; 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawRect: (NSRect) aRect {
	NSBezierPath* backgroundPath = [NSBezierPath bezierPathForRoundedRect: aRect withRadius: kRoundedRadius]; 
    
	// create the background color, we are oriented on Apples choice of color and 
	// alpha value settings 
    NSColor* backgroundColor = [NSColor colorWithCalibratedWhite: 0.2 alpha: 0.36];
	
	// ready to draw 
    [backgroundColor set];
    [backgroundPath fill];	
	
	[mShadow set]; 
	
    // draw icon image
    NSImage*	backgroundImage = [NSImage imageNamed: @"imageNotification"];
    NSPoint		backgroundImagePosition;
	// the image will be draw centered horizontally and shifted upwards from the center vertically 
    backgroundImagePosition.x = (aRect.size.width - [backgroundImage size].width) / 2.0;
    backgroundImagePosition.y = 0.6 * aRect.size.height - [backgroundImage size].height / 2.0;
    [backgroundImage compositeToPoint: backgroundImagePosition operation: NSCompositeSourceOver];
    
    // draw desktop name    
    NSSize	textSize = [mText sizeWithAttributes: mTextAttributes];
    NSPoint	textPosition; 
	// the text will be centered horizontally and vertically below the image 
  textPosition.x = 0.5 * (aRect.size.width - textSize.width);
  textPosition.y = 0.5 * (backgroundImagePosition.y - textSize.height);
  [mText drawAtPoint: textPosition withAttributes: mTextAttributes];
	
	// draw application icons if we should do that 
	if (mDrawApplets == NO || mDesktop == nil)
		return; 
	
	NSEnumerator*	applicationIter	= [[mDesktop applications] objectEnumerator];
	PNApplication*	application		= nil; 
	int				count			= 0; 
	
	while (application = [applicationIter nextObject]) {
		if ([application isHidden]) 
			continue; 
		
		count++; 
	}
	
	NSSize	iconSize = NSMakeSize(16, 16); 
	NSPoint	currentPosition; 
	currentPosition.x	= 0.5 * (aRect.size.width - (count * iconSize.width + (count - 1) * 4));  
	currentPosition.y	= 4; 
	
	applicationIter	= [[mDesktop applications] objectEnumerator];
	
	while (application = [applicationIter nextObject]) {
		// skip hidden applications 
		if ([application isHidden]) 
			continue; 
		
		NSImage* icon = [application icon]; 
		[icon setSize: iconSize]; 
		[icon dissolveToPoint: currentPosition fraction: 0.8]; 
		
		currentPosition.x += 20; 
	}
}

@end
