//
//  VTMotionController.h
//  VirtueDesktops
//
//  Created by Tony on 12/06/06.
//  Copyright 2006 boomBalada! Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../UniMotion/unimotion.h"

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

- (void) startTimer;
- (void) stopTimer;
- (void) readFromSensor: (NSNotification*) notification;

// Getters and setters
- (BOOL) enabled;
- (void) setEnabled: (BOOL) enableValue;
- (float) sensitivity;
- (void) setSensitivity: (float) sensitivityValue;

@end
