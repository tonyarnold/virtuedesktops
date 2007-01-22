//
//  VTLightSensorController.h
//  VirtueDesktops
//
//  Created by Tony on 23/08/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#include <Cocoa/Cocoa.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>

@interface VTLightSensorController : NSObject {
  NSTimer   *sensorReadTimer;
  double        updateInterval;
  io_connect_t  dataPort;
  
  BOOL          enabled;
  BOOL          canEnable;
  
  float           sensitivity;
  int           stable;
  int           left_sum, right_sum;
  int           count;
  double        left_average, right_average;
  float         sensor_speed;
}

+ (VTLightSensorController*) sharedInstance;

- (void) startTimer;
- (void) stopTimer;
- (void) readFromSensor: (NSNotification*) notification;

- (BOOL) hasALSHardware;

  // Getters and setters
- (BOOL) isEnabled;
- (void) setIsEnabled: (BOOL) enableValue;
- (float) sensorSensitivity;
- (void) setSensorSensitivity: (float) sensitivityValue;


@end
