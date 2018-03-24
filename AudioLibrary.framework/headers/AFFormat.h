//
//  AFFormat.h
//  Sound Library
//
//  Created by Kok Chen on 1/5/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface AFFormat : NSObject {
	AudioStreamBasicDescription streamDescription ;
	@public
	int channels ;
	int bits ;
}

@property (assign, readwrite) int channels ;
@property (assign, readwrite) int bits ;

+ (id)formatForDescription:(AudioStreamBasicDescription*)asbd ;

- (id)initWithDescription:(AudioStreamBasicDescription*)asbd ;
- (AudioStreamBasicDescription*)streamDescription ;

@end
