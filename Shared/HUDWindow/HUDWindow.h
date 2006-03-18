//
//  HUDWindow.h
//  HUDWindow
//
//  Created by Matt Gemmell on 12/02/2006.
//  Copyright 2006 Magic Aubergine. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HUDWindow : NSPanel {
    BOOL forceDisplay;
}

- (NSColor *)sizedHUDBackground;

@end
