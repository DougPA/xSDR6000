//
//  AFStreamDescription.h
//  PlayFile
//
//  Created by Kok Chen on 9/27/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <CoreAudio/CoreAudioTypes.h>

void setLPCMDescription( AudioStreamBasicDescription *asbd, Float64 samplingRate, UInt32 channelsPerFrame, UInt32 bitsPerChannel, bool isFloat, bool isBigEndian, bool isInterleaved ) ;
Boolean setStreamBasicDescription( AudioStreamBasicDescription *asbd, UInt32 audioFileType, float rate, int channels ) ;

char *af_streamExtension( UInt32 audioFileType ) ;