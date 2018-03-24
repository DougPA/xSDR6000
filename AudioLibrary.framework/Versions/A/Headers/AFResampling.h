//
//  AFResampling.h
//  Audio Library
//
//  Created by Kok Chen on 9/25/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "AFTypes.h"


@interface AFResampling : NSObject {
	//	data resampling
	float resamplingRate ;
	int resamplingQuality ;
	AudioConverterRef rateConverter ;
	Boolean needNewRateConverter ;
	
	//	channel selection
	int channelMask ;
	int numberOfMappedChannels ;
	SInt32 channelMap[AF_MAXCHANNELS] ;
	int	inverseChannelMap[AF_MAXCHANNELS] ;
}

- (Boolean)isBigEndian ;

//	-- resampling rate (this is the rate that the client will receive data)
- (float)resamplingRate ;
- (void)setResamplingRate:(float)rate ;
- (int)resamplingQuality ;
- (void)setResamplingQuality:(int)q ;

- (void)setResamplingQualityIndex:(int)index ;

//  -- channel masks
- (void)makeChannelMapForMask:(int)mask deviceChannels:(int)deviceChannels ;
- (int)channelMask ;
- (void)setChannelMask:(int)mask ;				// channel mask 0 -> same number and order as device channels, else bit 0 = left, next bit = right, etc

@end
