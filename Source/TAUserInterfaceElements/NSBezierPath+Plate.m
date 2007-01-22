//
//  NSBezierPathPlate.m
//  TAUserInterfaceElements.framework
//
//  Created by Tony on 2/10/06.
//  Copyright 2007 boomBalada! Productions..
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import "NSBezierPath+Plate.h"


@implementation NSBezierPath (TAUIPlate)

- (void) appendBezierPathWithPlateInRect: (NSRect)aRect
{
	if (aRect.size.height == 0)
		return; 
	if (aRect.size.width == 0)
		return; 
  
	float xOffset = aRect.origin.x;
	float yOffset = aRect.origin.y;
	
	float radius = aRect.size.height / 2.0;
	
	NSPoint point   = NSMakePoint(xOffset + radius, yOffset + aRect.size.height);
	NSPoint center1 = NSMakePoint(xOffset + radius, yOffset + radius);
	NSPoint center2 = NSMakePoint(xOffset + aRect.size.width - radius, yOffset +radius);
  
	[self moveToPoint:point];
	[self appendBezierPathWithArcWithCenter:center1 radius:radius startAngle:90.0 endAngle:270.0];
	[self appendBezierPathWithArcWithCenter:center2 radius:radius startAngle:270.0 endAngle:90.0];
	[self closePath];
}

- (void) appendBezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius
{
	// create the control points for our bezier path
  float minimumX	= NSMinX(aRect) - 0.5;
  float midX		= NSMidX(aRect) - 0.5;
  float maximumX	= NSMaxX(aRect) - 0.5;
  float minimumY	= NSMinY(aRect) - 0.5;
  float midY		= NSMidY(aRect) - 0.5;
  float maximumY	= NSMaxY(aRect) - 0.5;
	
	// bottom right curve and bottom edge 
  [self moveToPoint: NSMakePoint(midX, minimumY)];
  [self appendBezierPathWithArcFromPoint: NSMakePoint(maximumX, minimumY) toPoint: NSMakePoint(maximumX, midY) radius: radius];
  
	// top right curve and right edge 
  [self appendBezierPathWithArcFromPoint: NSMakePoint(maximumX, maximumY) toPoint: NSMakePoint(midX, maximumY) radius: radius];
  
	// top left curve and top edge
  [self appendBezierPathWithArcFromPoint: NSMakePoint(minimumX, maximumY) toPoint: NSMakePoint(minimumX, midY) radius: radius];
  
	// bottom left curve and left edge 
  [self appendBezierPathWithArcFromPoint: NSMakePoint(minimumX, minimumY) toPoint: NSMakePoint(midX, minimumY) radius: radius];
  [self closePath];
}

- (void) appendBezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius top: (BOOL) roundTop bottom: (BOOL) roundBottom
{
	// create the control points for our bezier path
  float minimumX	= NSMinX(aRect) - 0.5;
  float midX		= NSMidX(aRect) - 0.5;
  float maximumX	= NSMaxX(aRect) - 0.5;
  float minimumY	= NSMinY(aRect) - 0.5;
  float midY		= NSMidY(aRect) - 0.5;
  float maximumY	= NSMaxY(aRect) - 0.5;
	
	// bottom right curve and bottom edge 
  [self moveToPoint: NSMakePoint(midX, minimumY)];
	if (roundBottom)
		[self appendBezierPathWithArcFromPoint: NSMakePoint(maximumX, minimumY) toPoint: NSMakePoint(maximumX, midY) radius: radius];
  else
	{
		NSPoint points[2]; 
		points[0] = NSMakePoint(maximumX, minimumY); 
		points[1] = NSMakePoint(maximumX, midY); 
		
		[self appendBezierPathWithPoints: points count: 2]; 
	}
	
	if (roundTop)
		// top right curve and right edge 
		[self appendBezierPathWithArcFromPoint: NSMakePoint(maximumX, maximumY) toPoint: NSMakePoint(midX, maximumY) radius: radius];
	else
	{
		NSPoint points[2]; 
		points[0] = NSMakePoint(maximumX, maximumY); 
		points[1] = NSMakePoint(midX, maximumY); 
		
		[self appendBezierPathWithPoints: points count: 2]; 
	}
  
	if (roundTop)
		// top left curve and top edge
		[self appendBezierPathWithArcFromPoint: NSMakePoint(minimumX, maximumY) toPoint: NSMakePoint(minimumX, midY) radius: radius];
  else
	{
		NSPoint points[2]; 
		points[0] = NSMakePoint(minimumX, maximumY); 
		points[1] = NSMakePoint(minimumX, midY); 
    
		[self appendBezierPathWithPoints: points count: 2]; 
	}
	
	if (roundBottom)
		// bottom left curve and left edge 
		[self appendBezierPathWithArcFromPoint: NSMakePoint(minimumX, minimumY) toPoint: NSMakePoint(midX, minimumY) radius: radius];
	else
	{
		NSPoint points[2]; 
		points[0] = NSMakePoint(minimumX, minimumY); 
		points[1] = NSMakePoint(midX, minimumY); 
		
		[self appendBezierPathWithPoints: points count: 2]; 
	}
	
  [self closePath];
}


+ (NSBezierPath*) bezierPathWithPlateInRect: (NSRect)aRect
{
	NSBezierPath* plate = [[[NSBezierPath alloc] init] autorelease];
	[plate appendBezierPathWithPlateInRect: aRect];
	
	return plate;
}

+ (NSBezierPath*) bezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius
{
	NSBezierPath* rect = [[[NSBezierPath alloc] init] autorelease]; 
	[rect appendBezierPathForRoundedRect: aRect withRadius: radius]; 
	
	return rect; 
}

+ (NSBezierPath*) bezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius roundTop: (BOOL) roundingTop roundBottom: (BOOL) roundingBottom
{
	NSBezierPath* rect = [[[NSBezierPath alloc] init] autorelease]; 
	[rect appendBezierPathForRoundedRect: aRect withRadius: radius top: roundingTop bottom: roundingBottom]; 
  
	return rect; 
}

@end