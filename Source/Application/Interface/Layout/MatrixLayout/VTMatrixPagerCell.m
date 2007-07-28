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

#import "VTMatrixPagerCell.h"
#import "VTMatrixPagerAppletCell.h" 
#import "NSScreenOverallScreen.h"
#import "NSBezierPathPlate.h"
#import <Zen/Zen.h> 

enum
{
	kDefaultCellWidth			= 160, 
	kDesktopAppletSize		= 16,
	kDesktopInset					= 16,
	kDesktopNameSpacer		= 4,
	kDesktopAppletSpacer	= 4, 
}; 


@interface VTMatrixPagerCell(Private) 
- (void) createAppletCells; 

- (NSRect) frameAvailableForDesktopInFrame: (NSRect) aFrame;
- (NSRect) screenFrameToCellFrame: (NSRect) screenFrame ourFrame: (NSRect) frame;

- (NSColor*) borderColorFor: (NSColor*) color highIntensity: (BOOL) flag; 
@end 

#pragma mark -
@implementation VTMatrixPagerCell

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	return [self initWithDesktop: nil]; 
}

- (id) initWithDesktop: (VTDesktop*) desktop {
	if (self = [super init]) {
		// attributes 
		[self setDesktop: desktop]; 
		[self setDisplaysColorLabels: YES];
		[self setDisplaysApplicationIcons: YES]; 
		[self setDrawsWithoutDesktop: YES]; 
		
		// Desktop name text attributes 
		NSShadow* textShadow = [[[NSShadow alloc] init] autorelease];
		[textShadow setShadowColor: [NSColor blackColor]];
		[textShadow setShadowBlurRadius: 1.0];
		[textShadow setShadowOffset: NSMakeSize(1,-1)];
		
		mDesktopNameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSColor whiteColor], 
			NSForegroundColorAttributeName,
			[NSFont systemFontOfSize: 11], 
			NSFontAttributeName,
			nil] retain];

		// Subcell array 
		mAppletCells = [[NSMutableArray alloc] init]; 
		
		
		// @TODO: Check if this is where the green background colour is coming from in our prefs (and then set it to something more like the system highlight color.
		// Set our default colours
		[self setBackgroundColor: 
			[NSColor colorWithCalibratedRed: 0.00 
																green: 0.00 
																 blue: 0.00 
																alpha: 0.85]]; 
		
		[self setBackgroundHighlightColor: 
			[NSColor colorWithCalibratedRed: 0.22
																green: 0.46 
																 blue: 0.84
																alpha: 0.38]]; 
		
		[self setWindowColor: 
			[NSColor colorWithCalibratedRed: 0.7 
																green: 0.7 
																 blue: 0.7 
																alpha: 0.3]]; 
		
		[self setWindowHighlightColor: 
			[NSColor colorWithCalibratedRed: 0.7 
																green: 0.7 
																 blue: 0.7 
																alpha: 0.3]]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// bindings 
	[self unbind: @"title"]; 
	if (mDesktop)
		[mDesktop removeObserver: self forKeyPath: @"applications"]; 
	
	// attributes 
	ZEN_RELEASE(mDesktop); 
	ZEN_RELEASE(mDesktopNameAttributes); 
	ZEN_RELEASE(mAppletCells); 
	// colors 
	ZEN_RELEASE(mDesktopBackgroundColor); 
	ZEN_RELEASE(mDesktopBackgroundHighlightColor); 
	ZEN_RELEASE(mBackgroundColor); 
	ZEN_RELEASE(mBackgroundHighlightColor); 
	ZEN_RELEASE(mWindowColor); 
	ZEN_RELEASE(mWindowBorderColor); 
	ZEN_RELEASE(mWindowHighlightColor); 
	ZEN_RELEASE(mWindowBorderHighlightColor); 
	ZEN_RELEASE(mBorderColor); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop {
	// undind desktop 
	[self unbind: @"title"]; 
	if (mDesktop)
		[mDesktop removeObserver: self forKeyPath: @"applications"]; 
	
	// assign desktop 
	ZEN_ASSIGN(mDesktop, desktop); 

	[self createAppletCells]; 

	// bind our title to the desktop name 
	if (mDesktop) {
		[self bind: @"title" toObject: mDesktop withKeyPath: @"name" options: nil]; 
		[mDesktop addObserver: self forKeyPath: @"applications" options: NSKeyValueObservingOptionNew context: NULL]; 
	}
}

- (VTDesktop*) desktop {
	return mDesktop; 
}

#pragma mark -
- (void) setDraggingTarget: (BOOL) flag {
	mDraggingTarget = flag; 
}

- (BOOL) isDraggingTarget {
	return mDraggingTarget; 
}

#pragma mark -
- (void) setDisplaysApplicationIcons: (BOOL) flag {
	mDrawsApplets = flag; 
}

- (BOOL) displaysApplicationIcons {
	return mDrawsApplets; 
}

#pragma mark -
- (void) setDisplaysColorLabels: (BOOL) flag {
	mDrawsColorLabels = flag; 
}

- (BOOL) displaysColorLabels {
	return mDrawsColorLabels; 
}

#pragma mark -
- (void) setDrawsWithoutDesktop: (BOOL) flag {
	mDrawsWithoutDesktop = flag; 
}

- (BOOL) drawsWithoutDesktop {
	return mDrawsWithoutDesktop; 
}


#pragma mark -

- (void) setTextColor: (NSColor*) color {
	[mDesktopNameAttributes setObject: color forKey: NSForegroundColorAttributeName]; 
}

- (void) setBackgroundColor: (NSColor*) color {
	ZEN_RELEASE(mBackgroundColor);
	ZEN_RELEASE(mBorderColor); 
	ZEN_RELEASE(mDesktopBackgroundColor);
	
	// we are taking over the passed color and adjust a bit 
	mBackgroundColor	= [[self borderColorFor: color highIntensity: NO] retain];
	mBorderColor      = [[self borderColorFor: color highIntensity: YES] retain]; 
	
	// also adjust the desktop background color 
	mDesktopBackgroundColor = [[self borderColorFor: mBackgroundColor highIntensity: NO] retain]; 
}

- (void) setBackgroundHighlightColor: (NSColor*) color {
  ZEN_RELEASE(mBackgroundHighlightColor);
  mBackgroundHighlightColor = [color copy];
  ZEN_RELEASE(mDesktopBackgroundHighlightColor);
	mDesktopBackgroundHighlightColor	= [[self borderColorFor: mBackgroundHighlightColor highIntensity: NO] retain];
}

- (void) setWindowColor: (NSColor*) color {	
  ZEN_RELEASE(mWindowColor);
  mWindowColor = [color copy];
  ZEN_RELEASE(mWindowBorderColor);
	mWindowBorderColor = [[[color shadowWithLevel: 0.4] colorWithAlphaComponent: 0.5] retain]; 
}

- (void) setWindowHighlightColor: (NSColor*) color {	
  ZEN_RELEASE(mWindowHighlightColor);
  mWindowHighlightColor = [color copy];
	ZEN_RELEASE(mWindowBorderHighlightColor);
	mWindowBorderHighlightColor = [[[color shadowWithLevel: 0.4] colorWithAlphaComponent: 0.5] retain]; 
}


#pragma mark -
#pragma mark NSCell 

- (BOOL) isOpaque {
	return NO;
}

#pragma mark -

/**
 * @brief	Calculates the size needed to display the cell
 *
 * @todo	We have to introduce constants for those hard coded values and/or 
 *			use real values taken from the text and icon size...
 *
 */ 
- (NSSize) cellSize {
	NSSize neededSize; 
	NSSize screenSize	= [NSScreen overallFrame].size; 
	NSSize textSize		= [@"Doesn't really matter" sizeWithAttributes: mDesktopNameAttributes]; 
	
	neededSize.width = kDefaultCellWidth; 
	
	// the size depends on what we want to draw, but is generally dependant on the aspect 
	// ratio of the overall screen and the decorations we draw 
	float scaleHeight	= screenSize.height / screenSize.width;
	float neededHeight	= (neededSize.width - 2 * kDesktopInset) * scaleHeight; 
	
	neededHeight += kDesktopNameSpacer * 2 + textSize.height; 
	neededHeight += kDesktopAppletSpacer * 2 + kDesktopAppletSize; 
	
	// and set 
	neededSize.height = neededHeight; 
	
	return neededSize; 
}

#pragma mark -
- (void) drawWithFrame: (NSRect) frame inView: (NSView*) controlView {
	if ((mDesktop == nil) && (mDrawsWithoutDesktop == NO) && (mDraggingTarget == NO))
		return; 
	
	// shrink frame by one pixel, so we do not get clipped by the frame 
	if (mDraggingTarget) {
		frame.origin.x		+= 2; 
		frame.origin.y		+= 2; 
		frame.size.width	-= 4; 
		frame.size.height	-= 4; 		
	}
	else {
		frame.origin.x		+= 1; 
		frame.origin.y		+= 1; 
		frame.size.width	-= 1; 
		frame.size.height	-= 1; 
	}
	
	// we draw our frame around the passed in frame and delegate to 
	// the super class 
	NSBezierPath*	borderPath	= [NSBezierPath bezierPathForRoundedRect: frame withRadius: 8]; 

	// only fill if there is a desktop 
	if (mDesktop && (mDraggingTarget == NO)) {
		// DRAW COMPONENT: background fill 
		if ([self isHighlighted])
			[mBackgroundHighlightColor set]; 
		else
			[mBackgroundColor set]; 
		// fill the path 
		[borderPath fill]; 
	}
	
	// DRAW COMPONENT: cell border frame 
	[mBorderColor set]; 
	if (mDraggingTarget) 
		[borderPath setLineWidth: 1];
	else
		[borderPath setLineWidth: 3]; 
	[borderPath stroke]; 
	
	// and continue for super 
	[super drawWithFrame: frame inView: controlView]; 
}

- (void) drawInteriorWithFrame: (NSRect) frame inView: (NSView*) controlView {
	// do not do anything if we got no desktop associated 
	if (mDesktop == nil)
		return; 
	
	// DRAWING COMPONENT: Desktop Name 
	// if this is the active desktop, we draw the name in bold 
	NSMutableDictionary* textAttributes = [[mDesktopNameAttributes mutableCopy] autorelease];
	if ([mDesktop visible]) {
		[textAttributes setObject: [NSFont boldSystemFontOfSize: 11] forKey: NSFontAttributeName];
	}
	
	NSSize  textSize	= [[mDesktop name] sizeWithAttributes: textAttributes]; 
	// calculate where to draw the text, so it will be nicely centered
	NSPoint textPosition; 
	textPosition.x		= frame.origin.x + (frame.size.width - textSize.width) * 0.5; 
	textPosition.y		= frame.origin.y + kDesktopNameSpacer; 
	
	// create and draw the color label background 
	if ((mDrawsColorLabels == YES) && ([mDesktop colorLabel])) {
		// TODO: Move this part of code to its own class / category for reuse 
		NSRect			plateRect	= NSMakeRect(0, 0, textSize.width+20, textSize.height); 
		NSBezierPath*	labelPath	= [NSBezierPath bezierPathWithPlateInRect: plateRect]; 
		
		NSImage*		specularImage = [NSImage imageNamed: @"imageColorLabelMaskBar.png"]; 
		NSImage*		receiver	= [[[NSImage alloc] initWithSize: plateRect.size] autorelease]; 
		NSShadow*		shadower	= [[[NSShadow alloc] init] autorelease];
		
		[shadower setShadowColor: [NSColor darkGrayColor]];
		[shadower setShadowBlurRadius: 0];
		[shadower setShadowOffset: NSMakeSize(0, -1)];
		
		[specularImage setScalesWhenResized: YES]; 
		[specularImage setSize: plateRect.size]; 
		
		// drawing 
		[receiver lockFocus];
		[NSGraphicsContext saveGraphicsState]; 
		//[shadow set]; 
		[[[mDesktop colorLabel] colorWithAlphaComponent: 0.7] set]; 
		[labelPath fill]; 
		[NSGraphicsContext restoreGraphicsState]; 
		[specularImage compositeToPoint: NSZeroPoint operation: NSCompositeSourceAtop fraction: 0.5]; 
		[receiver unlockFocus]; 
		
		// now draw the receiver 
		NSPoint destinationPoint = NSMakePoint(textPosition.x - 10, textPosition.y + [receiver size].height); 
		[receiver compositeToPoint: destinationPoint operation: NSCompositeSourceOver fraction: 1.0]; 
	}
	
	[[mDesktop name] drawAtPoint: textPosition withAttributes: textAttributes];
	
	// DRAWING COMPONENT: Desktop background 
	NSRect desktopFrameRect		= [self frameAvailableForDesktopInFrame: frame]; 
	desktopFrameRect.origin.x	= frame.origin.x - 0.5; 
	desktopFrameRect.origin.y	= desktopFrameRect.origin.y	- 0.5; 
	desktopFrameRect.size.width = frame.size.width; 
	
	NSBezierPath* desktopPath = [NSBezierPath bezierPathWithRect: desktopFrameRect]; 
	
	if ([self isHighlighted]) {
		[mDesktopBackgroundHighlightColor set]; 
		[desktopPath fill]; 
	}
	
	// DRAWING COMPONENT: Desktop Windows 
	[NSGraphicsContext saveGraphicsState]; 
	NSRectClip(desktopFrameRect);
	
	NSEnumerator*   windowIter  = [[mDesktop windows] reverseObjectEnumerator]; 
	PNWindow*       window      = nil; 
	
	while (window = [windowIter nextObject]) {    
		// check if the application is hidden and skip this window if it is. We should also skip drawing the window if the individual window is hidden or not visible.
		PNApplication* windowApplication = [mDesktop applicationForPid: [window ownerPid]]; 
		if ((windowApplication) && ([windowApplication isHidden] || [windowApplication isMe]))
			continue; 
		
		// get the window rect
		NSRect scaledWindowRect	= [self screenFrameToCellFrame: [window screenRectangle] ourFrame: frame]; 
		scaledWindowRect.origin.x -= 0.5; 
		scaledWindowRect.origin.y -= 0.5; 
		
		NSBezierPath* windowPath = [NSBezierPath bezierPathWithRect: scaledWindowRect]; 
		
		// draw the window 
		if ([self isHighlighted])
			[mWindowHighlightColor set]; 
		else
			[mWindowColor set]; 
		
		[windowPath fill]; 
		
		if ([self isHighlighted])
			[mWindowBorderHighlightColor set]; 
		else
			[mWindowBorderColor set]; 
		
		[windowPath setLineWidth: 1]; 
		[windowPath stroke]; 
	} 
	
	[NSGraphicsContext restoreGraphicsState]; 
	
	// DRAWING COMPONENT: Desktop Applications  
	if (mDrawsApplets) {
		NSEnumerator*	applicationIter = [mAppletCells objectEnumerator]; 
		NSImageCell*	applicationCell = nil; 
		
		NSPoint			currentPosition; 
		currentPosition.x	= frame.origin.x + 0.5 * (frame.size.width - ([mAppletCells count] * 16 + ([mAppletCells count] - 1) * kDesktopAppletSpacer)); 
		currentPosition.y	= frame.origin.y + (frame.size.height - kDesktopAppletSpacer - 16); 
		NSRect			currentRect; 
		
		while (applicationCell = [applicationIter nextObject]) {
			currentRect.origin = currentPosition; 
			currentRect.size   = NSMakeSize(16, 16); 
			
			[applicationCell drawWithFrame: currentRect inView: controlView]; 
			
			currentPosition.x += kDesktopAppletSize + kDesktopAppletSpacer;		
		}
	}
}

- (NSImage*) drawToImage { 
	NSImage*			image	= nil; 
	NSBitmapImageRep*	bits	= nil; 
	NSRect				frame; 
	
	frame.size		= [self cellSize]; 
	frame.origin	= NSZeroPoint; 
	
	image = [[NSImage alloc] initWithSize: frame.size]; 
	[image setBackgroundColor: [NSColor clearColor]]; 
	
	[image setFlipped: YES]; 
	[image lockFocus]; 
	[self drawWithFrame: frame inView: [NSView focusView]]; 
	[self drawInteriorWithFrame: frame inView: [NSView focusView]]; 
	bits = [[NSBitmapImageRep alloc] initWithFocusedViewRect: frame]; 
	[image unlockFocus]; 
	[bits release]; 
	
	return [image autorelease]; 
}

#pragma mark -
#pragma mark KVO Sink
- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context {
	if ([keyPath isEqualToString: @"applications"]) {
		[self createAppletCells]; 
	}
}

@end


#pragma mark -
@implementation VTMatrixPagerCell(Private) 

- (void) createAppletCells {
	[mAppletCells removeAllObjects]; 

	NSEnumerator*	appletIter	= [[mDesktop applications] objectEnumerator]; 
	PNApplication*	application	= nil; 
	
	while (application = [appletIter nextObject]) {
		// skip hidden applications from display
		if ([application isHidden] || [application isMe]) 
			continue; 
		
		VTMatrixPagerAppletCell* cell = [[VTMatrixPagerAppletCell alloc] initWithApplication: application]; 
		[mAppletCells addObject: cell]; 
		[cell release]; 
	}
}

#pragma mark -
- (void) resetTrackingRects {
}


	
- (NSRect) frameAvailableForDesktopInFrame: (NSRect) aFrame
{
	NSRect frameAvailable; 
	NSSize textSize = [[mDesktop name] sizeWithAttributes: mDesktopNameAttributes]; 
	
	// we do not restrict left orientation and the width except for spacers 
	frameAvailable.origin.x		= aFrame.origin.x + kDesktopInset; 
	frameAvailable.size.width	= aFrame.size.width - 2 * kDesktopInset; 
	// vertical orientation is restricted by the text size and spacers 
	frameAvailable.origin.y		= aFrame.origin.y + textSize.height + 2 * kDesktopNameSpacer;
	// hight is restricted also by icons 
	frameAvailable.size.height	= aFrame.size.height - textSize.height - 2 * kDesktopNameSpacer - kDesktopAppletSize - 2 * kDesktopAppletSpacer;
	
	return frameAvailable; 
}

- (NSRect) screenFrameToCellFrame: (NSRect) screenFrame ourFrame: (NSRect) frame
{
	NSSize screenSize		= [NSScreen overallFrame].size;
	NSRect frameAvailable	= [self frameAvailableForDesktopInFrame: frame]; 
	float  scaleWidth		= frameAvailable.size.width / screenSize.width; 
	
	// translate the passed screen frame to the scaled cell frame 	
	screenFrame.origin.x	= frameAvailable.origin.x + screenFrame.origin.x * scaleWidth;
	screenFrame.origin.y	= frameAvailable.origin.y + screenFrame.origin.y * scaleWidth;
	screenFrame.size.width  = screenFrame.size.width * scaleWidth;
	screenFrame.size.height = screenFrame.size.height * scaleWidth;
	
	return NSIntegralRect(screenFrame);
}

- (NSColor*) borderColorFor: (NSColor*) color highIntensity: (BOOL) flag
{
	NSColor* borderColor = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];  
	
	// darken color 
	if ([borderColor brightnessComponent] > 0.4)
	{
		float brightnessDiff = flag ? 0.3 : 0.2; 
		
		borderColor = [NSColor colorWithCalibratedHue:[borderColor hueComponent]
										   saturation:[borderColor saturationComponent]
										   brightness:[borderColor brightnessComponent] - brightnessDiff
												alpha:0.3];
	}
	// lighten color 
	else 
	{
		float brightnessDiff = flag ? 0.3 : 0.2; 
		
		borderColor = [NSColor colorWithCalibratedHue:[borderColor hueComponent]
										   saturation:[borderColor saturationComponent]
										   brightness:[borderColor brightnessComponent] + brightnessDiff
												alpha:0.3];
	}
	
	return borderColor; 
}


@end 
