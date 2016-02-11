//
//  GMBEventHandlerView.h
//  MySpecialView
//
//  Created by Graham Barab on 8/3/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GMBPlayBtnCALayer.h"
#import "GMBSeekBarLayer.h"
#import "GMBSeekPosLayer.h"
#import <AVFoundation/AVFoundation.h>

static void* rootLayerTrackingContext = &rootLayerTrackingContext;
static void* seekBarTrackingContext = &seekBarTrackingContext;
static void* seekPosTrackingContext = &seekPosTrackingContext;
static void* playBtnTrackingContext = &playBtnTrackingContext;

@interface GMBEventHandlerView : NSView
{
	BOOL _setupDone;

	BOOL _alreadyVisible;
	BOOL _hoveringOverPlay;
	BOOL _hoveringOverSeekBar;
	BOOL _hoveringOverSeekPos;
	BOOL _draggingSeekPos;
	NSDictionary*   _playButtonTrackingAreaUserData;
	NSDictionary*   _seekBarTrackingAreaUserData;
	NSDictionary*   _seekPosTrackingAreaUserData;

	dispatch_queue_t _bgDispatchQueueSerial;
	NSNumber*	   _percentRead;
	NSNumber*	   _userChangedSeek;
	double		  _cursorOffset;

	AVPlayerLayer*  _playerLayer;
	AVPlayerLayer*  _playerLayerUnmodified;

	NSMutableDictionary*   _kvoRegistrations;

	BOOL			_mouseUp;
	BOOL			_mouseDown;
}

@property NSTrackingRectTag trackingRectTag;
@property NSTrackingRectTag seekTrackingRectTag;
@property NSTrackingRectTag playButtonTrackingRectTag;
@property NSTrackingArea*   playButtonTrackingArea;
@property NSTrackingArea*   seekBarTrackingArea;
@property NSTrackingArea*   seekPosTrackingArea;
@property (strong) AVPlayerLayer*		   playerLayer;
@property CALayer*						  rootLayer;
@property CAShapeLayer*					 maskLayer;
@property GMBPlayBtnCALayer*				playButtonLayer;
@property GMBSeekBarLayer*				  seekLayer;
@property GMBSeekPosLayer*				  seekPosLayer;
@property NSNumber*						 percentRead;
@property NSNumber*						 userChangedSeek;
@property NSRect							origFrame;

@property BOOL							  mouseUp;
@property BOOL							  mouseDown;

//@property double percentRead;

@end


