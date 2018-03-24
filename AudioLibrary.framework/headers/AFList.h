//
//  AFList.h
//  Audio Library (derived from cocoaFilter)
//
//  Created by Kok Chen on 11/8/10.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AFDevice.h"


@interface AFList : NSObject {
	Boolean isInput ;
	NSMutableArray *devices ;		//  array of AFDevice objects
	NSMenu *menu ;
}

- (id)initAsInput:(Boolean)inInput ;
- (AFDevice*)deviceWithID:(AudioDeviceID)deviceID ;
- (AFDevice*)deviceWithName:(NSString*)name ;
- (AFDevice*)defaultDevice ;

- (void)refreshDeviceList ;

- (NSMenu*)menu ;
- (NSMenu*)menuCopy ;		//  v0.09
- (NSArray*)devices ;
- (Boolean)isInput ;

@end
