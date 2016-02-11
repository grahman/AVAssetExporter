//
//  AppDelegate.h
//  AVAssets2
//
//  Created by Graham Barab on 6/20/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GMBAVAssetParser.h"
#import "GMBAUGraph.h"
#import "GMBMixer.h"
#import "GMBDelegate.h"
#import "CAUtilityFunctions.h"
#import "GMBChannelStrip.h"
#import "MixerWindow.h"
#import "GMBAVExporter.h"
#import "GMBMovieWindow.h"


@interface AppDelegate : NSWindowController <NSApplicationDelegate>
{
	BOOL						_mediaReady;
	BOOL						_wasPlayingBeforeChangingSeek;
	dispatch_queue_t			backgroundQueue;
	dispatch_queue_t			backgroundQueueSerial;
	NSMutableArray*			 channelStripArray;

	GMBBackgroundTimer*		 bgTimer;
	NSTimer*					_bgTimerBasic;
	GMBBackgroundTimer*		 _seekPosTimer;
	BOOL						_seekPosMouseUp;
	BOOL						_seekPosMouseDown;
}

@property GMBAVAssetParser*				 assetParser;
@property GMBAVExporter*					exporter;
@property GMBMixer*						 mixer;
//@property AudioConverterRef*				audioConverter;
@property GMBAudioStreamBasicDescription*   asbd;
@property AudioStreamBasicDescription*	  streamDscrptn;
@property GMBAudioStreamBasicDescription*   dspASBD;
@property GMBDelegate*					  del;
@property GMBDelegate*					  stopPlayingDelegate;
@property GMBDelegate*					  needsNewBufferDelegate;
@property NSMutableArray*				   channelStripArray;
@property MixerWindow*					  myMixerWindow;
@property GMBMovieWindow*				   movieWindow;
@property NSString*						 openFileName;
@property BOOL							  playing;
@property BOOL							  initialized;
@property (weak) IBOutlet NSButton		  *resetButton;
@property CGPoint						   upperLeftCornerOfScreen;
@property BOOL							  movieWindowCreated;




- (IBAction)OpenButtonClicked:(id)sender;
- (IBAction)PlayAudioButtonClicked:(id)sender;
- (IBAction)AddTrackButtonClicked:(id)sender;
- (IBAction)RegisterCallbackButtonClicked:(id)sender;
- (IBAction)CAShowButtonClicked:(id)sender;
- (IBAction)StopAudioButtonClicked:(id)sender;
- (IBAction)MixerButtonClicked:(id)sender;
- (IBAction)ResetButtonClicked:(id)sender;
- (IBAction)PlayPauseButtonClicked:(id)sender;
- (IBAction)ViewMovieButtonClicked:(id)sender;
- (IBAction)ControllerMenuItemClicked:(id)sender;



- (IBAction)ExportMenuItemClicked:(id)sender;


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
@end



