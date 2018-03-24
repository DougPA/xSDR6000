//
//  AFManager.h
//  Sound Library
//
//  Created by Kok Chen on 5/10/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudioTypes.h>

@class AFSoundcard ;
@class AFSoundfile ;
@class AFList ;

@interface AFManager : NSObject {
	AFList *inputList ;
	AFList *outputList ;
}

- (AFSoundcard*)newInputSoundcard ;
- (AFSoundcard*)newOutputSoundcard ;
- (AFSoundfile*)newInputSoundfile ;

- (AudioTimeStamp)presentAudioTimeStamp ;

@end


