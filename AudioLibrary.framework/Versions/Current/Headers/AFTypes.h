/*
 *  AFTypes.h
 *  Audio Library (derived from cocoaFilter and HD Radio)
 *
 *  Created by Kok Chen on 9/30/10.
 *  Copyright 2011 Kok Chen, W7AY. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

#define AF_RINGBUFFERSIZE		8192
#define	AF_MAXSAMPLES			4096
#define	AF_MAXCHANNELS			64

//	Ring buffer has sufficient allocation to allow wrapped around data to run past the end.
typedef	float AFRingBuffer[AF_RINGBUFFERSIZE+AF_MAXSAMPLES] ;
typedef float AFRenderBuffer[AF_MAXSAMPLES] ;
typedef SInt64 AFPointerSize ;

//	AudioBufferList that includes up to AF_MAXCHANNELS of AudioBuffers
typedef struct {
	AudioBufferList list ;
	AudioBuffer mExtendedBuffers[AF_MAXCHANNELS-1] ;
} ExtendedBufferList ;

typedef struct {
	AUNode node ;
	AudioUnit audioUnit ;
	AudioDeviceID deviceID ;
	AudioStreamBasicDescription outputUnitASBD ;
	AudioTimeStamp timeStamp ;						//  most recent time stamp
	UInt32 framesPerBuffer ;
} AFUnitInfo ;

typedef struct {
	__unsafe_unretained NSSlider *slider ;
	Float32 value ;
} AFVolumeControl ;

//  channel masks
#define	kAFLeftChannelMask	0x1
#define	kAFRightChannelMask	0x2
#define	kAFStereoMask		( kAFLeftChannelMask | kAFRightChannelMask )
