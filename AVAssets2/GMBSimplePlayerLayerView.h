//
//  GMBSimplePlayerLayerView.h
//  AVAssets2
//
//  Created by Graham Barab on 8/11/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface GMBSimplePlayerLayerView : NSView
{
	AVPlayerLayer*  _playerLayer;
}

@property AVPlayerLayer*	playerLayer;

@end


