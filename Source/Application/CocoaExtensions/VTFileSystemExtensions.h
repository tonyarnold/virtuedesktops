//
//  VTFileSystemExtensions.h
//  VirtueDesktops
//
//  Created by Tony on 2/09/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VTFileSystemExtensions : NSObject {}
+ (NSString *)preferencesFolder;
+ (NSString *)applicationSupportFolder;
+ (NSString *)globalApplicationSupportFolder;
@end