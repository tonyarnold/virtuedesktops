//
//  ColorLabelInspector.m
//  ColorLabel
//
//  Created by Tony on 1/10/06.
//  Copyright boomBalada! Productions 2006.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import "ColorLabelInspector.h"

@implementation ColorLabelInspector

- (id)init
{
    self = [super init];
    [NSBundle loadNibNamed:@"ColorLabelInspector" owner:self];
    return self;
}

- (void)ok:(id)sender
{
	/* Your code Here */
    [super ok:sender];
}

- (void)revert:(id)sender
{
	/* Your code Here */
    [super revert:sender];
}

@end
