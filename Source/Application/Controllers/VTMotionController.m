//
//  VTMotionController.m
//  VirtueDesktops
//
//  Created by Tony on 12/06/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//
//  This class interfaces with the "UniMotion" library ( Version 0.3 - http://members.optusnet.com.au/lbramsay/programs/unimotion.html ) to allow motion-based switching between active desktops.
//  Notes:
//    - There needs to be a delay after each positive switch based on motion, as the sensor does encounter recoil and will trigger a switch if it is still active when this recoil occurs

#import "VTPreferences.h"
#import "VTMotionController.h"

#pragma mark Coding keys 
#define kVtCodingMotionSensorEnabled			@"isEnabled"
#define kVtCodingMotionSensorSensitivity	@"sensorSensitivity"

@implementation VTMotionController

+ (VTMotionController*) sharedInstance 
{
	static VTMotionController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[VTMotionController alloc] init]; 
	return ms_INSTANCE; 
}

- (id) init 
{
  if (self = [super init]) 
  {
    enabled = NO;
    sensor_speed = 0.1;
    activation_speed = 10;
    sensor_type = detect_sms();
    cooldown = 0;
		
    return self;
  }
  
  return nil;
}

#pragma mark Coding

- (id) initWithCoder: (NSCoder*) coder 
{
	if (self = [super init]) 
  {
		enabled           = [coder decodeBoolForKey: kVtCodingMotionSensorEnabled]; 
    activation_speed  = [coder decodeFloatForKey: kVtCodingMotionSensorSensitivity];
		return self; 
	}
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder 
{
  [coder encodeBool: enabled forKey: kVtCodingMotionSensorEnabled];
  [coder encodeFloat: activation_speed forKey: kVtCodingMotionSensorSensitivity];
}

#pragma mark Getters and setters

- (BOOL) isEnabled 
{ 
  return enabled; 
}

- (void) setIsEnabled: (BOOL) enableValue 
{
  enabled = enableValue;
  
  if (enabled) 
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
  return activation_speed; 
}

- (void) setSensorSensitivity: (float) sensitivityValue 
{
  if (sensitivityValue == nil)
    return;
  
  activation_speed = sensitivityValue;
}


#pragma mark -
- (void) startTimer 
{  
  read_sms(sensor_type, &x_speed, &y_speed, &z_speed);
  sensorReadTimer = [[NSTimer scheduledTimerWithTimeInterval: sensor_speed 
                                                      target: self 
                                                    selector: @selector(readFromSensor:) 
                                                    userInfo: nil 
                                                     repeats: YES] retain];
}

- (void) stopTimer 
{
  [sensorReadTimer invalidate];
  [sensorReadTimer release];
}

- (void) readFromSensor: (NSNotification*) notification 
{
  read_sms(sensor_type, &next_x_speed, &y_speed, &z_speed);
  
  if (cooldown == 0) 
  {
    int difference = next_x_speed - x_speed;
    if ( abs(difference) > activation_speed ) 
    {
      if (difference > 0) 
      {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"SwitchToPrevWorkspace" object: nil]; 
      } 
      else 
      {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"SwitchToNextWorkspace" object: nil]; 
      }
      // This prevents recoil when the sensor gets a positive hit (cooldown * sensor_speed is what you'll get in real time -- seconds)
      cooldown = 8; 
      
    }
  } 
  else 
  {
    // To prevent recoil
    cooldown -= 1;
  }
  x_speed = next_x_speed;
}

@end
