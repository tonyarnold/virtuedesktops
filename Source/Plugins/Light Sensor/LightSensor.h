//
//  LightSensor.h
//  VirtueDesktops
//
//  Created by Tony Arnold on 12/09/06.
//  Copyright 2006 boomBalada! Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>
#import <Virtue/VTPlugin.h>

@interface LightSensor : NSObject {
	NSTimer   *sensorReadTimer;
	double        updateInterval;
	io_connect_t  dataPort;
	
	BOOL          enabled;
	BOOL          canEnable;
	
	int           sensitivity;
	int           stable;
	int           left_sum, right_sum;
	int           count;
	double        left_average, right_average;
	float         sensor_speed;
}

+ (LightSensor*) sharedInstance;

- (void) startTimer;
- (void) stopTimer;
- (void) readFromSensor: (NSNotification*) notification;

- (BOOL) hasALSHardware;

// Getters and setters
- (BOOL) isEnabled;
- (void) setIsEnabled: (BOOL) enableValue;
- (int) sensorSensitivity;
- (void) setSensorSensitivity: (int) sensitivityValue;


@end
