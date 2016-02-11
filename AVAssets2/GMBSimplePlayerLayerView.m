//
//  GMBSimplePlayerLayerView.m
//  AVAssets2
//
//  Created by Graham Barab on 8/11/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBSimplePlayerLayerView.h"

@implementation GMBSimplePlayerLayerView

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code here.
		self.frame = frame;
	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

	// Drawing code here.
	[CATransaction begin];
	[CATransaction setAnimationDuration:0];
	_playerLayer.frame = dirtyRect;
	[CATransaction commit];
	[self setNeedsDisplay:YES];
}

-(AVPlayerLayer*)playerLayer
{
	return _playerLayer;
}

-(void)setPlayerLayer:(AVPlayerLayer *)playerLayer_
{
	_playerLayer = playerLayer_;
	_playerLayer.frame = self.frame;
	self.layer = _playerLayer;
	[self setWantsLayer:YES];
	[self setNeedsDisplay:YES];

}

-(void)setFrame:(NSRect)frame
{
	[CATransaction begin];
	[CATransaction setAnimationDuration:0];
	_playerLayer.frame = frame;
	[CATransaction commit];
	[self setNeedsDisplay:YES];
}

@end

