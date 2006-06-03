/******************************************************************************
 *
 * Virtue framework
 *
 * Copyright 2004, Thomas Staller playback@users.sourceforge.net
 * Copyright 2006, Tony Arnold tony@tonyarnold.com
 *
 * See COPYING for licensing details
 *
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import <Peony/Peony.h>

#import "VTCoding.h"
#import "VTDesktopDecoration.h"

@interface VTDesktop : PNDesktop<NSCoding, VTCoding> {
  // attributes
  NSString*             mDesktopBackgroundImagePath;
  NSString*             mDefaultDesktopBackgroundImagePath;
  NSColor*              mColorLabel;
  // decoration
  VTDesktopDecoration*  mDecoration;
  // unique identifier
  NSString*             mUUID;
  BOOL                  mIsUsingDefaultDesktopImage;
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
- (void) setDefaultDesktopBackgroundPath: (NSString*) path;
- (NSString*) defaultDesktopBackgroundPath;
- (BOOL) showsBackground;
- (void) setShowsDefaultBackground: (BOOL) defaultBackground;
- (BOOL) showsDefaultBackground;

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
- (void) applyDefaultDesktopBackground;

#pragma mark -
#pragma mark Class method

+ (NSString*) currentDesktopBackground;

@end
