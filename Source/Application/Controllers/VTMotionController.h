//
//  VTMotionController.h
//  VirtueDesktops
//
//  Created by Tony on 12/06/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../../Shared/UniMotion/unimotion.h"

@interface VTMotionController : NSObject {
  NSTimer   *sensorReadTimer;
  int       sensor_type;
  BOOL   enabled;
  float  activation_speed;
  float  sensor_speed;
  int    x_speed;
  int    y_speed;
  int    z_speed;
  int    next_x_speed;
  int    cooldown;
}

+ (VTMotionController*) sharedInstance;

- (void) startTimer;
- (void) stopTimer;
- (void) readFromSensor: (NSNotification*) notification;

// Getters and setters
- (BOOL) isEnabled;
- (void) setIsEnabled: (BOOL) enableValue;
- (float) sensorSensitivity;
- (void) setSensorSensitivity: (float) sensitivityValue;

@end
