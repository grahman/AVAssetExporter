//
//  GMBEventHandlerView.m
//  MySpecialView
//
//  Created by Graham Barab on 8/3/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBEventHandlerView.h"

@implementation GMBEventHandlerView
@synthesize trackingRectTag;
@synthesize seekTrackingRectTag;
@synthesize playButtonTrackingRectTag;
@synthesize playButtonLayer;
@synthesize seekLayer;
@synthesize seekPosLayer;
@synthesize maskLayer;
@synthesize playButtonTrackingArea;
@synthesize seekBarTrackingArea;
@synthesize seekPosTrackingArea;
@synthesize rootLayer;
@synthesize origFrame;
@synthesize userChangedSeek;
@synthesize mouseUp = _mouseUp;
@synthesize mouseDown = _mouseDown;




- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code here.
//		if (!_playerLayer)
//		{
//			assert(false);
//		}
		origFrame = frame;
		_cursorOffset = 0;
		_setupDone = NO;
		_bgDispatchQueueSerial = dispatch_queue_create("GMBEventHandlerViewBackgroundQueue", DISPATCH_QUEUE_SERIAL);
		_percentRead = [NSNumber numberWithDouble:0];
		_hoveringOverSeekBar = NO;
		_hoveringOverSeekPos = NO;
		_hoveringOverPlay = NO;
		_draggingSeekPos = NO;
		_kvoRegistrations = [[NSMutableDictionary alloc]init];
		[self setUserChangedSeek:[NSNumber numberWithInt:0]];

	}
	return self;
}

-(AVPlayerLayer*)playerLayer
{
	return _playerLayer;
}

-(void)setPlayerLayer:(AVPlayerLayer *)playerLayer_
{
	_playerLayer = nil;
	_playerLayer = playerLayer_;
	_playerLayerUnmodified = [AVPlayerLayer playerLayerWithPlayer:_playerLayer.player];

//	_playerLayer.zPosition = 0;
	_cursorOffset = 0;
	_setupDone = NO;
//	_bgDispatchQueueSerial = dispatch_queue_create("GMBEventHandlerViewBackgroundQueue", DISPATCH_QUEUE_SERIAL);
	_percentRead = [NSNumber numberWithDouble:0];
	_hoveringOverSeekBar = NO;
	_hoveringOverSeekPos = NO;
	_hoveringOverPlay = NO;
	_draggingSeekPos = NO;
	trackingRectTag = [self addTrackingRect:self.frame owner:self userData:rootLayerTrackingContext assumeInside:NO];
	playButtonTrackingRectTag = 0;

	NSRect quarterFrame = origFrame;
	quarterFrame.size.height /= 3;

	_playerLayer.frame = origFrame;
	[self setLayer:_playerLayer];

	CALayer* playBtnLayer = [GMBPlayBtnCALayer layer];

	CALayer* layer = [CALayer layer];
	rootLayer = layer;
	[layer setFrame:quarterFrame];
	layer.backgroundColor = [[NSColor darkGrayColor] colorWithAlphaComponent:0.75].CGColor;
	//Set up the background blur filter seen when the transport HUD appears (during mouse over bottom 3rd of window
	CIFilter* blur = [CIFilter filterWithName:@"CIGaussianBlur"];
	[blur setDefaults];
	[self setLayerUsesCoreImageFilters:YES];
	rootLayer.backgroundFilters = [NSArray arrayWithObject:blur];

//	[layer setCornerRadius:20];
	[self setWantsLayer:YES];
	[self setAlphaValue:1.0];
	[self setNeedsDisplay:YES];
	[_playerLayer addSublayer:rootLayer];

	//Now that we have root layer setup, copy it's shape to the layer mask.
	maskLayer = [CAShapeLayer layer];
	maskLayer.frame = rootLayer.frame;
//	maskLayer.path = CGPathCreateWithRect(CGRectMake(0, 0, rootLayer.frame.size.width, rootLayer.frame.size.height), NULL);
	maskLayer.path = CGPathCreateWithRoundedRect(CGRectMake(0, 0, rootLayer.frame.size.width, rootLayer.frame.size.height), 20, 30, NULL);
//	[maskLayer setCornerRadius:20];

	maskLayer.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:1.0].CGColor;
	_playerLayer.mask = maskLayer;
	[_playerLayer setNeedsDisplay];

	playBtnLayer.frame = CGRectMake((self.frame.size.width / 2) - 10,			 //Origin x-coordinate
									(self.frame.size.height / 2) - 10,			 //Origin y-coordinate
									20,
									20);

	[playBtnLayer setPosition:self.frame.origin];


	[rootLayer addSublayer:playBtnLayer];
	[playBtnLayer setNeedsDisplay];
	playButtonLayer = (GMBPlayBtnCALayer*)playBtnLayer;

	//Now create the seek button layer.
	seekLayer = [[GMBSeekBarLayer alloc]init];
	[rootLayer addSublayer:seekLayer];

	NSRect seekLayerFrame = [self frame];
	seekLayerFrame.size.height = 10;
	seekLayerFrame.origin.y = 0;
	seekTrackingRectTag = [self addTrackingRect:seekLayerFrame owner:self userData:seekBarTrackingContext assumeInside:NO];
//	[seekLayer setNeedsDisplay];

	seekPosLayer = [[GMBSeekPosLayer alloc] init];
	[seekLayer addSublayer:seekPosLayer];
	[seekPosLayer setNeedsDisplay];
	[self setAlphaValue:0.0];
}



- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

	// Drawing code here.
}

-(void) mouseEntered:(NSEvent *)theEvent
{
	if ([theEvent userData] == rootLayerTrackingContext)
	{
		if (!_alreadyVisible)
		{
			[self setAlphaValue:1.0];
			_alreadyVisible = YES;
		}
	}

	if ([theEvent userData] == seekBarTrackingContext)
	{

	}

	if ( [[[theEvent trackingArea] userInfo] objectForKey:@"shouldPlay"])
	{
		_hoveringOverPlay = YES;
//		NSLog(@"Hovering over \"shouldPlay\"");
	}

	if ([[[theEvent trackingArea]userInfo]objectForKey:@"seekBarMouseOver"])
	{
		_hoveringOverSeekBar = YES;
	}

	if ([[[theEvent trackingArea]userInfo]objectForKey:@"seekPosMouseOver"])
	{
		_hoveringOverSeekPos = YES;
	}
}

-(void) mouseExited:(NSEvent *)theEvent
{

	if ([theEvent userData] == rootLayerTrackingContext)
	{
		if(_alreadyVisible && !_draggingSeekPos )
		{
			[self setAlphaValue:0.0];
			_alreadyVisible = NO;
		}
	}
	if ([[[theEvent trackingArea] userInfo] objectForKey:@"shouldPlay"])
	{
		_hoveringOverPlay = NO;
	}

	if ([[[theEvent trackingArea]userInfo]objectForKey:@"seekBarMouseOver"])
	{
		_hoveringOverSeekBar = NO;
	}

	if ([[[theEvent trackingArea]userInfo]objectForKey:@"seekPosMouseOver"])
	{
		if (!_draggingSeekPos)
			_hoveringOverSeekPos = NO;
	}

}

-(void) mouseDown:(NSEvent *)theEvent
{
	if (_hoveringOverPlay)
	{
		NSRect origFrame = playButtonLayer.frame;
		dispatch_async(dispatch_queue_create("GMBEventHandlerViewBackgroundQueue2", DISPATCH_QUEUE_SERIAL), ^
					{
						[CATransaction begin];
						[CATransaction setAnimationDuration:0];
						NSRect newFrame = playButtonLayer.frame;
						newFrame.size.width *= 1.5;
						newFrame.size.height *= 1.5;
						[playButtonLayer setFrame:newFrame];
						[CATransaction commit];
					});
		dispatch_async(dispatch_queue_create("GMBEventHandlerViewBackgroundQueue3", DISPATCH_QUEUE_SERIAL), ^
					{
						[CATransaction begin];
						[CATransaction setAnimationDuration:0];
						usleep(50000);
						[playButtonLayer setFrame:origFrame];
						[CATransaction commit];
					});
	}
	dispatch_async(_bgDispatchQueueSerial, ^
	{
		if (_hoveringOverSeekPos)
		{
			[self willChangeValueForKey:NSStringFromSelector(@selector(mouseDown))];
			[self setMouseDown:YES];
			[self didChangeValueForKey:NSStringFromSelector(@selector(mouseDown))];
			NSPoint seekPosOriginRelativeToSeekBarOrigin = [self convertPoint:seekPosLayer.frame.origin fromView:self];
			double pr = seekPosOriginRelativeToSeekBarOrigin.x / seekLayer.frame.size.width;
			//		_percentRead = [NSNumber numberWithDouble: pr];
			_cursorOffset = seekPosLayer.frame.size.width / 2.0;
			[self setUserChangedSeek:[NSNumber numberWithDouble: pr]];
			_draggingSeekPos = YES;
			NSPoint eventOrigin = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			NSPoint seekPosOrigin = seekPosLayer.frame.origin;
			seekPosOrigin.x += seekLayer.frame.origin.x;
			_cursorOffset = eventOrigin.x - seekPosOrigin.x;
		}
	});

	if (_hoveringOverSeekBar && !_hoveringOverSeekPos)
	{
		[self willChangeValueForKey:NSStringFromSelector(@selector(mouseDown))];
		[self setMouseDown:YES];
		[self didChangeValueForKey:NSStringFromSelector(@selector(mouseDown))];
		NSPoint eventOrigin = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		eventOrigin.x -= seekLayer.frame.origin.x;
		NSRect newFrame = seekPosLayer.frame;
		newFrame.origin.x = eventOrigin.x - (seekPosLayer.frame.size.width / 2.0);
		[CATransaction begin];
		[CATransaction setAnimationDuration:0];
		seekPosLayer.frame = newFrame;
		[CATransaction commit];

		NSPoint seekPosOriginRelativeToSeekBarOrigin = [self convertPoint:seekPosLayer.frame.origin fromView:self];
		double pr = seekPosOriginRelativeToSeekBarOrigin.x / seekLayer.frame.size.width;
		//		_percentRead = [NSNumber numberWithDouble: pr];
		_cursorOffset = seekPosLayer.frame.size.width / 2.0;
		[self setUserChangedSeek:[NSNumber numberWithDouble: pr]];

		[self removeTrackingArea:seekPosTrackingArea];
		newFrame.origin.x += seekLayer.frame.origin.x;
		newFrame.origin.y += seekLayer.frame.origin.y;
		seekPosTrackingArea = nil;
		seekPosTrackingArea = [[NSTrackingArea alloc] initWithRect:newFrame
														options:NSTrackingMouseEnteredAndExited |NSTrackingMouseMoved| NSTrackingActiveAlways
															owner:self
														userInfo:_seekPosTrackingAreaUserData];
		[self addTrackingArea:seekPosTrackingArea];
		_draggingSeekPos = YES;


	}

}

-(void) mouseMoved:(NSEvent *)theEvent
{

}

-(void) mouseDragged:(NSEvent *)theEvent
{
	NSPoint eventOrigin = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	eventOrigin.x -= seekLayer.frame.origin.x;

	if (_draggingSeekPos == YES)
	{
		NSRect newFrame = seekPosLayer.frame;
		newFrame.origin.x = eventOrigin.x - _cursorOffset;
		if (newFrame.origin.x + seekPosLayer.frame.size.width > seekLayer.frame.size.width)
		{
			newFrame.origin.x = seekLayer.frame.size.width - seekPosLayer.frame.size.width;
		}
		if (newFrame.origin.x < 0)
		{
			newFrame.origin.x = 0;
		}
		[CATransaction begin];
		[CATransaction setAnimationDuration:0];
		seekPosLayer.frame = newFrame;
		[CATransaction commit];

		[self removeTrackingArea:seekPosTrackingArea];
		newFrame.origin.x += seekLayer.frame.origin.x;
		newFrame.origin.y += seekLayer.frame.origin.y;
		seekPosTrackingArea = nil;
		seekPosTrackingArea = [[NSTrackingArea alloc] initWithRect:newFrame
														options:NSTrackingMouseEnteredAndExited |NSTrackingMouseMoved| NSTrackingActiveAlways
															owner:self
														userInfo:_seekPosTrackingAreaUserData];

		[self addTrackingArea:seekPosTrackingArea];

		NSPoint seekPosOriginRelativeToSeekBarOrigin = [self convertPoint:seekPosLayer.frame.origin fromView:self];
		double pr = seekPosOriginRelativeToSeekBarOrigin.x / seekLayer.frame.size.width;
//		_percentRead = [NSNumber numberWithDouble: pr];
		[self setPercentRead:[NSNumber numberWithDouble:pr]];

	} else
	{
		//Maybe do something else here later.

	}

}

-(void) mouseUp:(NSEvent *)theEvent
{
	NSPoint eventOrigin = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	eventOrigin.x -= seekLayer.frame.origin.x;
	_draggingSeekPos = NO;
	if (_hoveringOverSeekPos)
	{
		double seekPosOrigin = seekPosLayer.frame.origin.x;
		double pr = seekPosOrigin / seekLayer.frame.size.width;
		[self setUserChangedSeek:[NSNumber numberWithDouble:pr]];
		dispatch_async(_bgDispatchQueueSerial, ^
					{
						[self willChangeValueForKey:NSStringFromSelector(@selector(mouseUp))];
						[self setMouseUp:YES];
						[self didChangeValueForKey:NSStringFromSelector(@selector(mouseUp))];
					});

	} else
	if (!NSPointInRect(eventOrigin, seekPosTrackingArea.rect) || _hoveringOverSeekPos)
	{

		dispatch_async(_bgDispatchQueueSerial, ^
					{
						[self willChangeValueForKey:NSStringFromSelector(@selector(mouseUp))];
						[self setMouseUp:YES];
						[self didChangeValueForKey:NSStringFromSelector(@selector(mouseUp))];
					});

	}


	_cursorOffset = 0;
}

-(void)viewDidEndLiveResize
{

}

-(void) awakeFromNib
{

}

-(void) setFrame:(NSRect)frame
{
	//First set the main layer's frame.
	NSRect lowerFourthFrame = frame;
	lowerFourthFrame.size.height /= 3;

	[super setFrame:frame];
	[_playerLayer setFrame:frame];
	[self removeTrackingRect:trackingRectTag];
	[self removeTrackingRect:seekTrackingRectTag];
	[self removeTrackingRect:playButtonTrackingRectTag];

	[[self.layer.sublayers objectAtIndex:0] setFrame:frame];
	NSRect replacementFrame = lowerFourthFrame;
	replacementFrame.origin.x = (lowerFourthFrame.size.width / 2) - 5;
	replacementFrame.origin.y = (lowerFourthFrame.size.height / 2);
	replacementFrame.size.height = 20;
	replacementFrame.size.width = 20;

	[CATransaction begin];
	[CATransaction setAnimationDuration:0];
	[playButtonLayer setFrame:replacementFrame];
	[CATransaction commit];

	//Now set up tracking areas
	NSTrackingAreaOptions playButtonTrackingOptions = NSTrackingMouseEnteredAndExited;
	if (playButtonTrackingArea)
	{
		[self removeTrackingArea:playButtonTrackingArea];
	}
	if (!_playButtonTrackingAreaUserData)
	{
		_playButtonTrackingAreaUserData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],
										@"shouldPlay",
											nil];
	}
	playButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:playButtonLayer.frame
																				options:playButtonTrackingOptions | NSTrackingActiveAlways
																				owner:self
																			userInfo:_playButtonTrackingAreaUserData];
	[self addTrackingArea:playButtonTrackingArea];

	[CATransaction begin];
	[CATransaction setAnimationDuration:0];
	[rootLayer setFrame:lowerFourthFrame];
//	[rootLayer setBounds:lowerFourthFrame];
	maskLayer.frame = rootLayer.frame;
	[CATransaction commit];
	trackingRectTag = [self addTrackingRect:lowerFourthFrame owner:self userData:rootLayerTrackingContext assumeInside:NO];
	playButtonTrackingRectTag = [self addTrackingRect:replacementFrame owner:self userData:playBtnTrackingContext assumeInside:NO];

//	//Also reset the maskLayer
//	[CATransaction begin];
//	[CATransaction setAnimationDuration:0];



	//Now set the seek layer.
	NSRect seekLayerFrame = lowerFourthFrame;
	seekLayerFrame.size.height = 10;
	seekLayerFrame.size.width *= 0.80;
	seekLayerFrame.origin.y = replacementFrame.origin.y - 15;
	seekLayerFrame.origin.x += (lowerFourthFrame.size.width - seekLayerFrame.size.width) / 2;

	[CATransaction begin];
	[CATransaction setAnimationDuration:0];
	seekLayer.frame = seekLayerFrame;
	[CATransaction commit];

	seekTrackingRectTag = [self addTrackingRect:seekLayerFrame owner:self userData:seekBarTrackingContext assumeInside:NO];
	[seekLayer setNeedsDisplay];

	[self removeTrackingArea:seekBarTrackingArea];
	_seekBarTrackingAreaUserData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"seekBarMouseOver", nil];
	seekBarTrackingArea = [[NSTrackingArea alloc] initWithRect:seekLayerFrame
														options:playButtonTrackingOptions | NSTrackingActiveAlways
															owner:self
														userInfo:_seekBarTrackingAreaUserData];
	[self addTrackingArea:seekBarTrackingArea];


	//Now set the seek pos layer (the square that is draggable)
	NSRect seekPosRect = {0};
	seekPosRect.size.height = seekLayer.frame.size.height;
	seekPosRect.size.width = seekPosRect.size.height;
	seekPosRect.origin.x = seekLayer.frame.size.width * [self.percentRead doubleValue];

	//Now apply the new frame rectangle to the seekPosLayer
	[CATransaction begin];
	[CATransaction setAnimationDuration:0];
	seekPosLayer.frame = seekPosRect;
	[CATransaction commit];

	//Now reset the origin of seekPosRect so that the tracking area is properly represented (Remember: it is a sublayer of the seekbar layer, so the origin is relative to that layer.
	seekPosRect.origin.x += seekLayer.frame.origin.x;
	seekPosRect.origin.y += seekLayer.frame.origin.y;
	[self removeTrackingArea:seekPosTrackingArea];
	_seekPosTrackingAreaUserData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"seekPosMouseOver", nil];
	seekPosTrackingArea = [[NSTrackingArea alloc] initWithRect:seekPosRect
													options:playButtonTrackingOptions | NSTrackingMouseMoved | NSTrackingActiveAlways
														owner:self
													userInfo:_seekPosTrackingAreaUserData];
	[self addTrackingArea:seekPosTrackingArea];

}

-(NSNumber*)percentRead
{
	return _percentRead;
}

-(void) setPercentRead:(NSNumber *)percentRead_
{
	[self willChangeValueForKey:NSStringFromSelector(@selector(percentRead))];
	_percentRead = percentRead_;
	[self didChangeValueForKey:NSStringFromSelector(@selector(percentRead))];
	//Also update the graphics
	NSRect newFrame = seekPosLayer.frame;
	newFrame.origin.x = [_percentRead doubleValue] * seekLayer.frame.size.width;

	[CATransaction begin];
	[CATransaction setAnimationDuration:0];
	seekPosLayer.frame = newFrame;
	[CATransaction commit];

	[self removeTrackingArea:seekPosTrackingArea];
	newFrame.origin.x += seekLayer.frame.origin.x;
	newFrame.origin.y += seekLayer.frame.origin.y;
	seekPosTrackingArea = nil;
	seekPosTrackingArea = [[NSTrackingArea alloc] initWithRect:newFrame
													options:NSTrackingMouseEnteredAndExited |NSTrackingMouseMoved| NSTrackingActiveAlways
														owner:self
													userInfo:_seekPosTrackingAreaUserData];

	[self addTrackingArea:seekPosTrackingArea];

	NSPoint seekPosOriginRelativeToSeekBarOrigin = [self convertPoint:seekPosLayer.frame.origin fromView:self];
	double pr = seekPosOriginRelativeToSeekBarOrigin.x / seekLayer.frame.size.width;
	_percentRead = [NSNumber numberWithDouble: pr];
}

-(void)setUserChangedSeek:(NSNumber *)userChangedSeek_
{
	[self willChangeValueForKey:NSStringFromSelector(@selector(userChangedSeek))];
	_userChangedSeek = userChangedSeek_;
	[self setPercentRead:userChangedSeek_];
	[self didChangeValueForKey:NSStringFromSelector(@selector(userChangedSeek))];
}


-(NSNumber*)userChangedSeek
{
	return _userChangedSeek;
}

-(void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
	[super addObserver:observer forKeyPath:keyPath options:options context:context];
	if ([_kvoRegistrations valueForKey:keyPath])
	{
		[(NSCountedSet*)[_kvoRegistrations valueForKey:keyPath] addObject:observer];
	} else
	{
		NSCountedSet* registeredObjectsCountedSet = [[NSCountedSet alloc] initWithArray:nil];
		[registeredObjectsCountedSet addObject:observer];
		[_kvoRegistrations addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:registeredObjectsCountedSet, keyPath, nil]];
	}

	NSLog(@"GMBEventHandlerView::Total observers for keypath %@: %lu", keyPath, (unsigned long)[[(NSCountedSet*)_kvoRegistrations valueForKey:keyPath] count]);
}

-(void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
	[super removeObserver:observer forKeyPath:keyPath];
	if ([_kvoRegistrations valueForKey:keyPath])
	{
		[(NSCountedSet*)[_kvoRegistrations valueForKey:keyPath] removeObject:observer];
	} else
	{

	}
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	return NO;
}

@end

