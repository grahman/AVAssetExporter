//
//  GMBAUMiniGraph.h
//  AVAssets2
//
//  Created by Graham Barab on 7/17/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import "CAUtilityFunctions.h"

@interface GMBAUMiniGraph : NSObject
{
	AUGraph							 _graph;
}

@property AUGraph					   graph;
@property AURenderCallbackStruct*	   callbacks;

-(id) init;
-(id) initWithOutputBusArray: (GMBOutputBus*)inBus_
			numberOfBusses: (UInt32)numBusses_
				callbacks: (AURenderCallbackStruct*)callbacks_;

@end


