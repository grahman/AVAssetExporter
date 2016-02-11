//
//  GMBMovieWindow.h
//  AVAssets2
//
//  Created by Graham Barab on 7/21/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "MyCALayerView.h"
#import "GMBEventHandlerView.h"
#import "GMBSimplePlayerLayerView.h"


@interface GMBMovieWindow : NSWindowController <NSWindowDelegate>
{
	BOOL								_isPlaying;
}

@property AVPlayerItem*				 playerItem;
@property AVPlayer*					 player;
@property (weak) IBOutlet AVPlayerView  *movieView;
@property MyCALayerView*				movieRootView;
@property (strong) IBOutlet NSWindow	*window;
@property BOOL						  spacebarPressed;
@property BOOL						  isPlaying;

-(id) init;

@end


