//
//  AFSoundfile.h
//  Audio Library
//
//  Created by Kok Chen on 9/24/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "AFResampling.h"

#define	EXTAUDIOBUFFERSIZE	512
//#define	EXTAUDIOBUFFERSIZE	1024

@interface AFSoundfile : AFResampling {
	//  instances
	Boolean isInput ;
	//  file properties
	NSURL *url ;
	ExtAudioFileRef audioFileRef ;
	AudioStreamBasicDescription fileDescriptor ;
	AudioStreamBasicDescription clientSideDescriptor ;
	int bufferLength ;
	SInt64 duration ;
	float zeros[AF_MAXSAMPLES] ;	//  output: array of zeros for zero filling unassigned output channels, input: garbage buffer
	//	InputSoundfile
	SInt64 packetNumber ;
	ExtendedBufferList resampledBufferList ;
	//	OutputSoundfile
	float samplingRate ;
	int channels ;
	AudioFileTypeID fileType ;
}

//	Creating instances
- (id)initAsInput ;
- (id)initAsOutput ;

//	Common file properties
- (NSURL*)url ;
- (float)samplingRate ;
- (void)setSamplingRate:(float)rate ;
- (int)channels ;
- (void)setChannels:(int)inChannels ;
#pragma mark -
#pragma mark DL3LSM
- (int)bufferLength ;
- (void)setBufferLength:(int)size ;
#pragma mark -

//	Common file operations
- (void)close ;

//	frame positions
- (void)cueTo:(float)seconds ;
- (float)elapsed ;
- (float)duration ;

//	File input
- (OSStatus)open ;
- (OSStatus)openURL:(NSURL*)url ;
- (OSStatus)getBuffers:(float**)buffers numberOfBuffers:(int)n samples:(int)samples ;

//	File output
- (OSStatus)createWithFileType:(AudioFileTypeID)type descriptor:(const AudioStreamBasicDescription*)descriptor ;
- (OSStatus)createWithFileType:(AudioFileTypeID)type samplingRate:(float)rate channels:(int)chnls ;
- (OSStatus)createURL:(const NSURL*)uurl type:(AudioFileTypeID)type descriptor:(const AudioStreamBasicDescription*)descriptor overWrite:(Boolean)overWrite ;
- (OSStatus)createURL:(const NSURL*)uurl type:(AudioFileTypeID)type samplingRate:(float)rate channels:(int)chnls overWrite:(Boolean)overWrite ;
- (OSStatus)putBuffers:(float**)buffers numberOfBuffers:(int)n samples:(int)samples ;

//	File creation short cuts (2 channels, overwrite)
- (OSStatus)createAIFFWithSamplingRate:(float)rate ;
- (OSStatus)createWAVWithSamplingRate:(float)rate ;
- (OSStatus)createAACWithSamplingRate:(float)rate ;
- (OSStatus)createCAFWithSamplingRate:(float)rate ;

@end

#define	kNotInputSoundfile		-400
#define	kNotOutputSoundfile		-401
#define	kOpenCancelledByUser	-402
#define	kCannotOpenFile			-403
#define	kFormatNotImplemented	-404
