//
//  AFDevice.h
//  Audio Library (derived from cocoaFilter and HD Radio)
//
//  Created by Kok Chen on 9/29/10.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/AudioHardware.h>
#import "AFFormat.h"


@interface AFDevice : NSObject {
	NSString *name ;
	NSString *uniqueName ;
	NSString *locationID ;
	AudioDeviceID deviceID ;
	NSMenu *sourceMenu ;
	AudioObjectPropertyScope scope ;
	AudioStreamBasicDescription streamFormat ;
	AudioStreamBasicDescription physicalFormat ;
	NSMutableArray *formats ;						//  array of AFFormat objects
	NSMutableArray *samplingRateCache ;				//  array of NSNumbers of sampling rate for (ch;bits) in current physical format
	int samplingRateCacheKey ;						//  channels + bits*32 used to cache samplingRates
} 

- (id)initWithDeviceID:(AudioDeviceID)devID isInput:(Boolean)isInput ;

//  Properties
- (AudioStreamBasicDescription*)streamFormat ;
- (AudioStreamBasicDescription*)physicalFormat ;
- (AudioDeviceID)deviceID ;
- (Boolean)isInput ;
- (NSString*)name ;
- (NSString*)uniqueName ;
- (NSString*)locationID ;

//	data parameters
- (NSString*)source ;
- (NSMenu*)sourceMenu ;
- (Boolean)selectSource:(NSString*)sourcename ;
- (AFFormat*)format ;
- (NSArray*)formats ;
- (Boolean)selectFormat:(AFFormat*)format ;
- (float)samplingRate ;
- (NSArray*)samplingRates ;
- (Boolean)selectSamplingRate:(float)samplingRate ;

@end
