/******************************************************************************
 *
 * VirtueDesktops framework
 *
 * Copyright 2004, Thomas Staller playback@users.sourceforge.net
 * Copyright 2007, Tony Arnold tony@tonyarnold.com
 *
 * See COPYING for licensing details
 *
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import <Peony/Peony.h>

#import "VTCoding.h"
#import "VTDesktopDecoration.h"

@interface VTDesktop:PNDesktop<NSCoding, VTCoding> {
  // attributes
  NSString*             mDesktopBackgroundImagePath;
  NSColor*              mColorLabel;
  // decoration
  VTDesktopDecoration*  mDecoration;
  // unique identifier
  NSString*             mUUID;
  BOOL                  mShowsBackground;
}

#pragma mark Lifetime
+ (id) desktopWithIdentifier: (int) identifier;
+ (id) desktopWithName: (NSString*) name identifier: (int) identifier;

#pragma mark -
- (id) initWithName: (NSString*) name identifier: (int) identifier;

#pragma mark -
#pragma mark Attributes

- (void) setDesktopBackground: (NSString*) path;
- (NSString*) desktopBackground;

#pragma mark -
- (void) setShowsBackground: (BOOL) showsBackground;
- (BOOL) showsBackground;

#pragma mark -
- (void) setColorLabel: (NSColor*) color;
- (NSColor*) colorLabel;

#pragma mark -
- (VTDesktopDecoration*) decoration;

#pragma mark -
- (void) setName: (NSString*) name;

#pragma mark -
- (NSString*) uuid;

#pragma mark -
#pragma mark Desktop background

- (void) applyDesktopBackground;
@end
