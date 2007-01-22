//
//  VTLightSensorController.m
//  VirtueDesktops
//
//  Created by Tony on 23/08/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//
//  
//  Based on lmutracker code by Amit Singh
//  http://osxbook.com/book/bonus/chapter10/light/
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

#import "VTLightSensorController.h"
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>

enum 
{
  kGetSensorReadingID   = 0,  // getSensorReading(int *, int *)
  kGetLEDBrightnessID   = 1,  // getLEDBrightness(int, int *)
  kSetLEDBrightnessID   = 2,  // setLEDBrightness(int, int, int *)
  kSetLEDFadeID         = 3,  // setLEDFade(int, int, int, int *)
};

#pragma mark Coding keys 
#define kVtCodingLightSensorEnabled			@"isEnabled"
#define kVtCodingLightSensorSensitivity	@"sensorSensitivity"


@implementation VTLightSensorController

+ (VTLightSensorController*) sharedInstance 
{
	static VTLightSensorController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[VTLightSensorController alloc] init]; 
	return ms_INSTANCE; 
}

- (id) init 
{
  if (self = [super init]) 
  {
    enabled = NO;
    sensitivity = 25;
    stable = 8;  // stable * sensor speed == seconds to wait before re-enabling sensor
    left_sum = 0;
    right_sum = 0;
    count = 0;
    left_average = 0;
    right_average = 0;
    sensor_speed = 0.1;
    dataPort = 0;
    canEnable = NO;
      
   	kern_return_t kr;
    io_service_t serviceObject;
    
    // Look up a registered IOService object whose class is AppleLMUController  
    serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault,  IOServiceMatching("AppleLMUController"));
    if (serviceObject) 
    {  
      canEnable = YES;
      // Create a connection to the IOService object  
      kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &dataPort);
      IOObjectRelease(serviceObject);
      
      if (kr != KERN_SUCCESS) 
      {  
        mach_error("IOServiceOpen:", kr);
        exit(kr);
      }  
      
      setbuf(stdout, NULL);
    }
    return self;
  }
  
  return nil;
}

#pragma mark Coding

- (id) initWithCoder: (NSCoder*) coder 
{
	if (self = [super init]) 
  {
		enabled      = [coder decodeBoolForKey: kVtCodingLightSensorEnabled]; 
    sensitivity  = [coder decodeFloatForKey: kVtCodingLightSensorSensitivity];
		return self; 
	}
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder 
{
  [coder encodeBool: enabled forKey: kVtCodingLightSensorEnabled];
  [coder encodeFloat: sensitivity forKey: kVtCodingLightSensorSensitivity];
}

- (BOOL) hasALSHardware 
{
  return canEnable;
}

#pragma mark Getters and setters

- (BOOL) isEnabled 
{ 
  return enabled && canEnable; 
}

- (void) setIsEnabled: (BOOL) enableValue 
{
  enabled = enableValue;
  
  if (enabled && canEnable) 
  {
    [self startTimer];
  } 
  else 
  {
    [self stopTimer];
  }
}

- (float) sensorSensitivity 
{ 
  return sensitivity; 
}

- (void) setSensorSensitivity: (float) sensitivityValue 
{
  if (sensitivityValue > 0)
    sensitivity = sensitivityValue;
}


#pragma mark -
- (void) startTimer 
{  
  sensorReadTimer = [[NSTimer scheduledTimerWithTimeInterval: sensor_speed target: self selector: @selector(readFromSensor:) userInfo: nil repeats: YES] retain];
}

- (void) stopTimer 
{
  [sensorReadTimer invalidate];
  [sensorReadTimer release];
}

- (void) readFromSensor: (NSNotification*) notification 
{
  kern_return_t kr;
  IOItemCount scalarInputCount = 0;
  IOItemCount scalarOutputCount = 2;
  SInt32 left = 0, right = 0;
  
  kr = IOConnectMethodScalarIScalarO(dataPort, kGetSensorReadingID, scalarInputCount, scalarOutputCount, &left, &right);
  
	if (kr == KERN_SUCCESS) 
  {
		left_sum = left_sum + left;
    right_sum = right_sum + right;
    
		// Update averages
    if ( count % stable == 0 ) 
    {
			left_average  = left_sum / stable;
      right_average = right_sum / stable;
      left_sum  = 0;
			right_sum = 0;
		}
    
    if (count > stable) 
    {
      float left_difference   = left_average  * ( sensitivity / 100 );
      float right_difference  = right_average * ( sensitivity / 100 );

      // We're now stable. Whenever we fire, reset the count
      if ( left < left_difference ) 
      {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"SwitchToPrevWorkspace" object: nil];
        count = -1;
      } 
      else if ( right < right_difference) 
      {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"SwitchToNextWorkspace" object: nil];
        count = -1;
      }
    }
		count++;
    return;
  }
    
	if (kr == kIOReturnBusy)
	  return;
  
  mach_error("I/O Kit error:", kr);
}


@end
