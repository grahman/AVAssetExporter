//
//  GMBMovieWindow.m
//  AVAssets2
//
//  Created by Graham Barab on 7/21/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBMovieWindow.h"

@interface GMBMovieWindow ()

@end

@implementation GMBMovieWindow
@synthesize playerItem;
@synthesize player;
@synthesize movieView;
@synthesize movieRootView;

-(id) init
{
	self=[super initWithWindowNibName:@"GMBMovieWindow"];
//	[[self window] setIgnoresMouseEvents:YES];
//	[[self window] setContentAspectRatio:[self window].frame.size];
//	 NSLog(@"\n------------------------\nGMBMovieWindow finished init, address: %p\n------------------------------\n", &self);
	movieRootView = [[MyCALayerView alloc] initWithNibName:@"MyCALayerView" bundle:[NSBundle mainBundle]];
//	movieRootView = [[MyCALayerView alloc] init];

	return self;
}

- (instancetype)initWithWindow:(NSWindow *)window_
{
	self = [super initWithWindow:window_];
	if (self) {
		// Initialization code here.
//		[[self window] setContentAspectRatio:[self window].frame.size];
	}
	NSLog(@"\n------------------------\nGMBMovieWindow finished initWithWindow, address: %p\n------------------------------\n", &self);
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];

	// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

	if (player)
	{
//		[movieView setAlphaValue:1.0];
		AVPlayerLayer* playerLayerUnmodified = [AVPlayerLayer playerLayerWithPlayer:player];
		AVPlayerLayer* playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
		[(GMBEventHandlerView*)movieRootView.view setPlayerLayer:playerLayer];
		movieRootView.view.frame = [self.window.contentView bounds];
		[[self window] setContentAspectRatio:[self.window.contentView bounds].size];
		[(GMBEventHandlerView*)movieRootView.view setOrigFrame:[self.window.contentView bounds]];

		GMBSimplePlayerLayerView* unmodifiedPlayerView = [[GMBSimplePlayerLayerView alloc] initWithFrame:[self.window.contentView bounds]];
		unmodifiedPlayerView.playerLayer = playerLayerUnmodified;

		[self.window setContentView:unmodifiedPlayerView];



//		[self.window.contentView setBounds:bounds];
		[self.window.contentView addSubview:movieRootView.view];
		[self.window.contentView setNeedsDisplay:YES];



	}

}

- (void)keyDown:(NSEvent *)theEvent
{
	if (theEvent.keyCode == 49)
	{
//		isPlaying = !isPlaying;
		BOOL newVal = !_isPlaying;
		[self setValue:[NSNumber numberWithBool:newVal] forKey:NSStringFromSelector(@selector(isPlaying))];
	}
}

-(void)setIsPlaying:(BOOL)isPlaying_
{
	_isPlaying = isPlaying_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(isPlaying))];
}

-(BOOL)isPlaying
{
	return _isPlaying;
}

- (void)windowDidResize:(NSNotification *)notification
{
	[movieRootView.view setFrame:[self.window.contentView bounds]];
}

@end

