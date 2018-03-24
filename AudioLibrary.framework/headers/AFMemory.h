//
//  AFMemory.h
//  Diversity
//
//  Created by Kok Chen on 8/9/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AFTypes.h"

@interface AFMemory : NSObject {
	AFRingBuffer *ringBuffers[AF_MAXCHANNELS] ;				//  double-ring buffers (malloc only on a needed basis)
	ExtendedBufferList ringBufferList ;						//  Dynamic AudioBufferList that points to current producer index
	AFRenderBuffer *resampledBuffers[AF_MAXCHANNELS] ;		//  simple buffers to use for resampled data
	ExtendedBufferList resampledBufferList ;				//  AudioBufferList for resampledBuffers
	AFRenderBuffer *resamplingBuffers[AF_MAXCHANNELS] ;		//  simple buffers to use for resampling
	ExtendedBufferList resamplingBufferList ;				//  AudioBufferList for resamplingBuffers
	
	//	number of channels that has been previously allocated in AFRingBuufer and AFRenderBuffer
	int allocatedChannels ;
	int bufferLength ;
	
	//  ring buffer producer and consumer pointers
	AFPointerSize producer ;								//  -1 for EOF
	AFPointerSize consumer ;
}
- (void)setChannels:(int)channels bufferLength:(int)length ;
- (int)channels ;

//	ring buffer operations
- (void)wrapAroundRingBuffer:(int)samples ;
- (void)extendRingBuffer:(int)channel samples:(int)samples ;
- (AFPointerSize)advanceProducer:(int)samples ;
- (AFPointerSize)advanceConsumer:(int)samples ;
- (int)available ;
- (void)resetRing ;
- (void)setEOF ;
- (Boolean)eof ;

//  accessors
- (float*)ringBufferProducerPtr:(int)channel ;
- (float*)ringBufferConsumerPtr:(int)channel ;
- (float*)ringBufferConsumerPtr:(int)channel samples:(int)length ;
- (float*)resampledBuffer:(int)channel ;
- (float*)resamplingBuffer:(int)channel ;
- (AudioBufferList*)ringBufferList ;
- (AudioBufferList*)resampledBufferList ;
- (AudioBufferList*)resamplingBufferList ;
- (AFPointerSize)producer ;
- (AFPointerSize)consumer ;

@end
