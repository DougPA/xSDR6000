//
//  AFInputSoundcard.h
//  Audio Library (derived from cocoaFilter and HD Radio)
//
//  Created by Kok Chen on 9/30/10.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "AFSoundcard.h"


@interface AFInputSoundcard : AFSoundcard {
	AudioUnit nextAudioUnit ;
	AFMemory *memory ;
	Boolean started ;
}

@end


