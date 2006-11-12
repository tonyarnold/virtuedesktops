//
//  ColorLabelPalette.m
//  ColorLabel
//
//  Created by Tony on 1/10/06.
//  Copyright boomBalada! Productions 2006.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import "ColorLabelPalette.h"

@implementation ColorLabelPalette

- (void) finishInstantiate
{ 
  NSArray* colors = [NSArray arrayWithObjects: 
		[NSColor redColor], 
		[NSColor orangeColor],
		[NSColor yellowColor],
		[NSColor greenColor], 
		[NSColor blueColor],
		[NSColor magentaColor],
		[NSColor grayColor],
		nil];
	[colorLabelButton setDisplaysClearButton: YES]; 
	[colorLabelButton setColorLabels: colors];
  
  [super finishInstantiate];
}

@end
