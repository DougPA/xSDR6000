//
//  AFOutputSoundcard.h
//  Audio Library (derived from cocoaFilter and HD Radio)
//
//  Created by Kok Chen on 11/11/10.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "AFSoundcard.h"

typedef struct {
	int channels ;
	//	AudioBufferList
	float *mdata[AF_MAXCHANNELS] ;
	int coffset ;
	int cleftover ;
	//	Local buffer
	float *bdata[AF_MAXCHANNELS] ;
	int boffset ;
	int bleftover ;
	// pushed buffers
	float *pdata[AF_MAXCHANNELS] ;
	long pproducer ;
	long pconsumer ;
	int pchannels ;
} RenderBuffers ;

@interface AFOutputSoundcard : AFSoundcard {
	AUGraph graph ;
	AFUnitInfo varispeedUnit ;
	RenderBuffers render ;
	int bufferedSamples ;
	Float64 trackedRateScalar ;
}

@end
