//
//  AFSoundcard.h
//  Audio Library (derived from cocoaFilter)
//
//  Created by Kok Chen on 11/11/10.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "AFResampling.h"
#import "AFList.h"
#import "AFMemory.h"
#import "AFManager.h"

#define	MAXSAMPLINGRATES	64

//	--  delegate methods
@protocol AFSoundcardDelegate <NSObject>
@optional

- (void)soundcard:(AFSoundcard*)card hardwareChanged:(AudioObjectPropertySelector)selector ;	// kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultInputDevice, kAudioHardwarePropertyDefaultOutputDevice
- (void)soundcard:(AFSoundcard*)card selectedSoundcardRemoved:(AudioDeviceID)devID ;
- (void)soundcard:(AFSoundcard*)card samplingRateChangedTo:(float)samplingRate ;
- (void)soundcard:(AFSoundcard*)card deviceChangedTo:(AFDevice*)device ;						//  v0.06
- (void)soundcard:(AFSoundcard*)card formatChangedToChannels:(int)channels bits:(int)bits ;
- (void)soundcard:(AFSoundcard*)card soundSourceChangedTo:(NSString*)source ;
- (void)soundcard:(AFSoundcard*)card volumeChangedTo:(float)value channel:(int)ch ;
- (void)inputReceivedFromSoundcard:(AFSoundcard*)card buffers:(float**)buffers numberOfBuffers:(int)n samples:(int)samples ;
- (Boolean)outputNeededBySoundcard:(AFSoundcard*)card buffers:(float**)buffers numberOfBuffers:(int)n samples:(int)samples ;

@end

enum PipeLockCondition {
	kNoSoundcardData,
	kHasSoundcardData
} ;

@interface AFSoundcard : AFResampling {
	//  device management
	AFList *deviceList ;
	AudioDeviceID defaultDeviceID ; 
	int defaultDeviceSelector ;
	AudioObjectPropertyScope scope ;
	Boolean useDefaultDevice ;
	
	id delegate ;
	
	//  current state
	AFDevice *selectedDevice ;
	AudioStreamBasicDescription selectedPhysicalFormat, selectedStreamFormat ;
	
	//	audio buffers
	int bufferLength ;
	AFUnitInfo audioHALUnit ;
		
	//  data sampling
	float samplingRateArray[MAXSAMPLINGRATES] ;
	AudioDeviceID listenerID ;
	Boolean needNewAudioUnit ;
	NSConditionLock *samplingLock ;
	Boolean justStarted ;
	
	//	v0.10 managed menu name cache
	NSMutableString *currentDeviceName ;
	
	//  managed controls
	NSPopUpButton *managedDevicePopUp ;
	AFVolumeControl volumeControl[AF_MAXCHANNELS+1] ;	//  master + each channel
	NSPopUpButton *managedFormatPopUp ;
	NSPopUpButton *managedSamplingRatePopUp ;
	NSPopUpButton *managedSourcePopUp ;
	
	//	callbacks
	NSLock *callbackLock ;
	Boolean delegateRespondsToVolumeChange ;
	Boolean delegateRespondsToFormatChange ;
	Boolean delegateRespondsToDeviceChange ;
	Boolean delegateRespondsToSourceChange ;
	Boolean delegateRespondsToSamplingRateChange ;
	Boolean delegateRespondsToHardwareChange ;
	Boolean delegateRespondsToDeviceRemoval ;
	Boolean delegateRespondsToInputReceived ;
	Boolean delegateRespondsToOutputNeeded ;
}

- (id)initWithDeviceList:(AFList*)list ;

- (void)setDelegate:(id <AFSoundcardDelegate>)client ;
- (id <AFSoundcardDelegate>)delegate ;

//	-- device selection
- (NSArray*)devices ;
- (AFDevice*)selectedDevice ;
- (AFDevice*)selectDevice:(AFDevice*)device ;
- (AFDevice*)selectDeviceName:(NSString*)name ;
- (void)setManagedDeviceMenu:(NSPopUpButton*)menu ;

//	-- volume (channel == 0 indicates master channel)
- (Boolean)deviceHasVolumeControl:(int)channel ;
- (float)volumeForChannel:(int)channel ;
- (Boolean)setVolume:(float)value channel:(int)channel ;
- (void)setManagedVolumeSlider:(NSSlider*)slider channel:(int)channel ;

//	buffers
- (int)bufferLength ;
- (void)setBufferLength:(int)size ;

//	-- sampling rate
- (float)samplingRate ;
- (void)setSamplingRate:(float)rate ;
- (void)setManagedSamplingRateMenu:(NSPopUpButton*)menu ;

//  -- format
- (AFFormat*)format ;
- (void)setFormat:(AFFormat*)format ;
- (void)setManagedFormatMenu:(NSPopUpButton*)menu ;

//	--  source/destination
- (NSString*)source ;
- (void)setSource:(NSString*)source ;
- (void)setManagedSourceMenu:(NSPopUpButton*)menu ;

//	-- sampling states
- (Boolean)start ;
- (Boolean)startAfterPause:(float)duration ;
- (void)stop ;
- (void)stopWithPause:(float)duration ;
- (Boolean)isRunning ;

//  accessors
- (AFList*)deviceList ;

//	-- device properties
- (AudioDeviceID)deviceID ;
- (Boolean)isInput ;

//	data (pushed output only)
- (void)pushBuffers:(float**)buffers numberOfBuffers:(int)n samples:(int)samples rateScalar:(Float64)rateScalar ;

//	--  clock source
- (Float64)rateScalar ;

@end

	

	