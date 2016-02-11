//
//  AppDelegate.m
//  AVAssets2
//
//  Created by Graham Barab on 6/20/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "AppDelegate.h"

#pragma mark CONTEXT_DECLARATIONS
static void* mixerPlayPauseContext = &mixerPlayPauseContext;
static void* mixerResetButtonContext = &mixerResetButtonContext;
static void* movieWindowSpacebarPressedContext = &movieWindowSpacebarPressedContext;
static void* normalizeCheckboxChangedContext = &normalizeCheckboxChangedContext;
static void* assetReaderDeallocContext = &assetReaderDeallocContext;
static void* transportHUDSeekPosChangedContext = &transportHUDSeekPosChangedContext;
static void* transportHUDSeekPosChangedMouseUpContext = &transportHUDSeekPosChangedMouseUpContext;
static void* transportHUDSeekPosChangedMouseDownContext = &transportHUDSeekPosChangedMouseDownContext;

/*****Debug******/


/***End Debug***/


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;


@end

@implementation AppDelegate

@synthesize assetParser;
@synthesize mixer;
//@synthesize audioConverter;
@synthesize asbd;
@synthesize dspASBD;
@synthesize streamDscrptn;
@synthesize del;
@synthesize stopPlayingDelegate;
@synthesize needsNewBufferDelegate;
@synthesize myMixerWindow;
@synthesize exporter;
@synthesize openFileName;
@synthesize playing;
@synthesize movieWindow;
@synthesize initialized;
@synthesize upperLeftCornerOfScreen;
@synthesize movieWindowCreated;




#pragma mark DID_FINISH_LAUNCHING
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	_seekPosMouseUp = YES;
	initialized = NO;
	movieWindowCreated = NO;
	_wasPlayingBeforeChangingSeek = NO;
	//Deal with window positioning

	/*********DEBUG AREA*****************/

	NSLog(@"\n-----------\n%p:\tMediaStatusContext\n%p:\tneedsNewBufferContext\n%p:\tmediaIsReadyContext\n%p:\tmixerNodeChangedContext\n%p:\tmixerPlayPauseContext\n%p:\tmixerResetButtonContext\n%p:\tmovieWindowSpacebarPressedContext\n%p:\tnormalizeCheckboxChangedContext\n%p:\tassetReaderDeallocContext\n--------------------", mediaStatusContext, needsNewBufferContext, mediaIsReadyContext, mixerNodeChangedContext);

	/********END DEBUG AREA**************/

	NSScreen* primaryDisplay = [NSScreen mainScreen];
	NSRect visibleFrame = primaryDisplay.visibleFrame;
	CGPoint upperLeftOfMainScreen = {0};


	NSRect originRect = {0};
	originRect.origin.x = 0;
	originRect.origin.y = visibleFrame.size.height;
	originRect.size = [[self window] frame].size;


	[[self window] cascadeTopLeftFromPoint:originRect.origin];
	[[self window] setFrame:originRect display:YES];
	if (!mixer)
	{
		mixer = [[GMBMixer alloc] init];
	}

	if (!assetParser)
		assetParser = [[GMBAVAssetParser alloc] init];
	backgroundQueue = dispatch_queue_create("backgroundQueue", DISPATCH_QUEUE_CONCURRENT);
	backgroundQueueSerial = dispatch_queue_create("backgroundQueueSerial", DISPATCH_QUEUE_SERIAL);

	_mediaReady = NO;
	__weak typeof(self) weakSelf = self;
	weakSelf.del.callback = ^
	{
		_mediaReady = YES;
	};
	playing = NO;
	[[self window] setDefaultButtonCell:nil];


	[assetParser addObserver:self forKeyPath:NSStringFromSelector(@selector(mediaIsReady)) options:NSKeyValueObservingOptionNew context:mediaIsReadyContext];

	//If the the  app was opened by dragging a movie to the dock tile, go ahead and open the file.
	if (openFileName)
	{
			if (assetParser.asset)
			{

			}
			else
			{
				assetParser = [assetParser initWithFileURL:openFileName];
			}


			[assetParser.assetReader startReading];
			asbd = assetParser.assetASBD;
//			[assetParser.assetReader addObserver:self forKeyPath:@"mediaIsReady" options:NSKeyValueObservingOptionNew context:(void*)&mediaStatusContext];
			[assetParser addObserver:self forKeyPath:NSStringFromSelector(@selector(assetReader)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:assetReaderDeallocContext];


			//Open the mixer window.
			NSScreen* primaryDisplay = [NSScreen mainScreen];
			NSRect visibleFrame = primaryDisplay.visibleFrame;
			NSRect originRect = {0};
			originRect.origin.x = visibleFrame.size.width / 7;
			originRect.origin.y = visibleFrame.size.height;
			NSPoint startPoint = [[movieWindow window] cascadeTopLeftFromPoint:originRect.origin];
			//		[movieWindow showWindow:self];
			[[movieWindow window] makeFirstResponder:nil];
			[[movieWindow window] makeFirstResponder:[self window]];

			NSSize frameOffsetRect = [[self window] frame].size;
			startPoint.x += frameOffsetRect.width;
			[[myMixerWindow window]cascadeTopLeftFromPoint:startPoint];


//			[movieWindow showWindow:self];
//			[myMixerWindow showWindow:self];

	}
	initialized = YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (void)aWindowBecameMain : (NSNotification*)theNotification
{


}

- (IBAction)OpenButtonClicked:(id)sender {

	/**
	The following code snippet was obtained from http://stackoverflow.com/questions/1640419/open-file-dialog-box
	**/



	// Create the File Open Dialog class.
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];

	// Enable the selection of files in the dialog.
	[openDlg setCanChooseFiles:YES];

	// Multiple files not allowed
	[openDlg setAllowsMultipleSelection:NO];

	// Can't select a directory
	[openDlg setCanChooseDirectories:NO];

	// Display the dialog. If the OK button was pressed,
	// process the files.
	if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
	{
		//Now that user has chosen a new file, stop current playback if necessary and dealloc the old userDataStructs and graph
		Boolean isRunning = false;
		Boolean isInitialized = false;
		if (mixer.graph.graph)
		{
			CheckError(AUGraphIsRunning(mixer.graph.graph, &isRunning), "Error checking if graph is running before stopping it");
			if (isRunning)
			{
				CheckError(AUGraphStop(mixer.graph.graph), "Error stopping graph");
			}
			CheckError(AUGraphIsInitialized(mixer.graph.graph, &isInitialized), "Error checking if graph is initalized");
			if (isInitialized)
			{
				CheckError(AUGraphUninitialize(mixer.graph.graph), "Error uninitializing graph");
			}
			CheckError(AUGraphClose(mixer.graph.graph), "Error closing graph");
			CheckError(DisposeAUGraph(mixer.graph.graph), "Error disposing of graph");
			[channelStripArray removeAllObjects];

		}

		// Get an array containing the full filenames of all
		// files and directories selected.
		NSArray* files = [openDlg filenames];
		openFileName = [files firstObject];

		if (assetParser.asset)
		{
			[assetParser removeObserver:del forKeyPath:@"assetReader.status"];
			[assetParser.assetReader removeObserver:self forKeyPath:@"status"];
			assetParser = [[GMBAVAssetParser alloc] initWithFileURL:openFileName];
		}
		else
		{
			assetParser = [[GMBAVAssetParser alloc] initWithFileURL:openFileName];
		}
		openDlg = nil;
		[self applicationDidFinishLaunching:nil];

	}
}


- (IBAction)PlayAudioButtonClicked:(id)sender {
	_wasPlayingBeforeChangingSeek = YES;
	dispatch_async(backgroundQueue, ^{
		while (!assetParser.audioBufferedAndReady);
		BOOL success = YES;
		if (success)
		{
			[mixer startGraph];
			if (movieWindow)
			{
				[movieWindow.player play];
			}
		}
	});
	playing = YES;
	if (assetParser)
	{
		//Without bgtimer...
		dispatch_async(backgroundQueueSerial, ^
					{
						do
						{
							[assetParser copyNextBuffers];
							sleep(1);
						} while (playing);
						NSLog(@"AppDelegate: Exiting copyNextBuffersLoop");
					});

	}


	if (movieWindow.player)
	{
		[movieWindow.player play];
	}
	[self resetSeekPosTimer];

}


- (IBAction)RegisterCallbackButtonClicked:(id)sender {
	[mixer registerCallbacks];
}

- (IBAction)CAShowButtonClicked:(id)sender {
	CAShow(mixer.graph.graph);
}

- (IBAction)StopAudioButtonClicked:(id)sender
{
//	[mixer.sampleBufferDelegate stopReading];
	_wasPlayingBeforeChangingSeek = NO;
	[mixer stopGraph];
	playing = NO;
	if (movieWindow)
	{
		[movieWindow.player pause];
	}
}



/**
 @abstract This function is the same as StopAudioButtonClicked but without changing the _wasPlayingBeforeChangingSeek variable
 **/
-(void) stopAudioQuietly
{
	[mixer stopGraph];
	playing = NO;
	if (movieWindow)
	{
		[movieWindow.player pause];
	}

}




- (IBAction)MixerButtonClicked:(id)sender
{
	if (myMixerWindow)
	{
		//Get the frame for opening the window


//		NSPoint* origin = [[self window] cascadeTopLeftFromPoint:<#(NSPoint)#>]

		NSRect frameRelativeToWindow = [[self window]frame];
		NSPoint origin = frameRelativeToWindow.origin;
		origin.x += frameRelativeToWindow.size.width;
//		NSPoint pointRelativeToScreen = [[self window]
//										 convertRectToScreen:frameRelativeToWindow
//										 ].origin;
		[[myMixerWindow window] cascadeTopLeftFromPoint:origin];
		[myMixerWindow showWindow:self];
	}

}

- (IBAction)ResetButtonClicked:(id)sender
{
	if (!mixer.graph.userDataStructs)
		return;
	for (int i=0; i < assetParser.audioTracks.count; ++i)
	{
		mixer.graph.userDataStructs[i].bytePos = 0;
		mixer.graph.userDataStructs[i].isDone = false;
	}

	//Reset the viewer also...
	if (movieWindow)
	{
		[self seekToTime:kCMTimeZero];

	}
}

- (IBAction)PlayPauseButtonClicked:(id)sender
{
	if (myMixerWindow)
	{
		if (playing)
		{
			[self StopAudioButtonClicked:self];
		} else
		{
			[self PlayAudioButtonClicked:self];
		}

	}
}

- (IBAction)ViewMovieButtonClicked:(id)sender
{
	[movieWindow showWindow:self];
	[[movieWindow window] makeFirstResponder:nil];
	[[movieWindow window] makeFirstResponder:[self window]];
}

- (IBAction)ControllerMenuItemClicked:(id)sender
{

}

- (IBAction)ExportMenuItemClicked:(id)sender
{

	//Set up the NSSavePanel
	NSSavePanel* savePanel = [NSSavePanel savePanel];

	NSString* suffix = @"_out.";
	NSArray* substrings = [openFileName componentsSeparatedByString:@"/"];
	NSString* relativeFileName = [substrings lastObject];
	NSArray* relSubStrings = [relativeFileName componentsSeparatedByString:@"."];
	NSString* relativeFileNameWithoutExtension = [relSubStrings firstObject];
	NSString* saveFileName = [[relativeFileNameWithoutExtension stringByAppendingString:suffix] stringByAppendingString:[relSubStrings lastObject]];
	[savePanel setNameFieldStringValue:saveFileName];
	int result = [savePanel runModal];
	if (result == NSOKButton)
	{
		NSString *selectedFile = [savePanel filename];
		NSURL* outputURL = [NSURL fileURLWithPath:selectedFile];
		[self StopAudioButtonClicked:sender];
		unsigned long long* origBytePos = malloc(sizeof(unsigned long long) * [mixer.graph.nSourceTracks intValue]);
		for (int i=0; i < [mixer.graph.nSourceTracks intValue]; ++i)
		{
			origBytePos[i] = mixer.graph.userDataStructs[i].bytePos;
			mixer.graph.userDataStructs[i].bytePos = 0;
		}

		AudioStreamBasicDescription* userRequestedOutputBusASBDs = malloc(sizeof(AudioStreamBasicDescription) * [mixer.nOutputBusses intValue]);
		memset(userRequestedOutputBusASBDs, 0, sizeof(AudioStreamBasicDescription) * [mixer.nOutputBusses intValue]);	   //Zero out the descriptions
		NSMutableArray* copyChannelStrips = [[NSMutableArray alloc] initWithArray:channelStripArray copyItems:YES];
		bool* convertedBusNumbersArray = malloc(sizeof(bool) * [mixer.nOutputBusses intValue]);
		for (int i=0; i < [mixer.nOutputBusses intValue]; ++i)
		{
			UInt32 propertySize = sizeof(AudioStreamBasicDescription);
			CheckError(AudioUnitGetProperty(mixer.graph.outputBusArray[i].splitter,
											kAudioUnitProperty_StreamFormat,
											kAudioUnitScope_Output,
											1,
											&userRequestedOutputBusASBDs[i],
											&propertySize), "Error getting userRequestedASBD from splitter out");
			GMBChannelStrip* chanStrip = [copyChannelStrips objectAtIndex:i];
			if ([chanStrip monoOrStereo] == 0)
			{
				[[[myMixerWindow channelStripArray] objectAtIndex:i] setMonoOrStereo:1];
				convertedBusNumbersArray[i] = true;
			}
			else
			{
				convertedBusNumbersArray[i] = false;
			}
		}

//		if (myMixerWindow)
//		{
//			[myMixerWindow monoToStereoPreservePanning];
//		}



		exporter = [[GMBAVExporter alloc] init];
		exporter.normalize = myMixerWindow.normalizeChecked;
		exporter.convertedBusNumbersArray = convertedBusNumbersArray;
		exporter = [exporter initWithGraph:mixer.graph
									withUserDataStructs:mixer.graph.userDataStructs
										numberOfStructs:(UInt32)[mixer.nOutputBusses unsignedIntegerValue]
										withAssetParser:assetParser
									withDestinationURL:outputURL];

		[exporter setUserRequestedASBDs:userRequestedOutputBusASBDs];
		[exporter setConvertedBusNumbersArray:convertedBusNumbersArray];


		[exporter normalizationPass];
		[exporter startExport];

		for (int i=0; i < [mixer.graph.nSourceTracks intValue]; ++i)
		{
//			mixer.graph.userDataStructs[i].bytePos = origBytePos[i];
//			[mixer.graph convertBusOutputStreamFormat:i withStreamType:userRequestedOutputBusASBDs[i]];

			//Now replace the correct channelStrips into the mixer. Hopefully no one notices...
			if (convertedBusNumbersArray)
			{
				if (convertedBusNumbersArray[i])
				{
					GMBChannelStrip* realStrip = [[myMixerWindow channelStripArray] objectAtIndex:i];
					GMBChannelStrip* copyStrip = [copyChannelStrips objectAtIndex:i];
					[[[myMixerWindow channelStripArray] objectAtIndex:i] setMonoOrStereo:0];
					[realStrip setPan:[copyStrip pan]];
				}
			}
		}


		free(userRequestedOutputBusASBDs);
		free(convertedBusNumbersArray);
		exporter = nil;

	}


}

- (void)keyDown:(NSEvent *)theEvent
{
	if (theEvent.keyCode == 36)			 //Enter key
	{
		[self ResetButtonClicked:nil];
	}
}

-(void)insertObject:(GMBChannelStrip *)object inChannelStripArrayAtIndex:(NSUInteger)index
{
	if (channelStripArray.count > index)
		[channelStripArray insertObject:object atIndex:index];
}

-(void)removeObjectFromChannelStripArrayAtIndex:(NSUInteger)index
{
	if (channelStripArray.count > index)
		[channelStripArray removeObjectAtIndex:index];
}

-(void)setChannelStripArray:(NSMutableArray *)channelStripArray_
{
	channelStripArray = channelStripArray_;
}

-(NSMutableArray*)channelStripArray
{
	return channelStripArray;
}

#pragma mark SEEK_POS_TIMER_UPDATING
-(void)resetSeekPosTimer
{

#pragma mark ADDING_TRANSPORT_HUD_OBSERVERS

	GMBEventHandlerView* transportHUD = (GMBEventHandlerView*)movieWindow.movieRootView.view;
	[transportHUD addObserver:self forKeyPath:NSStringFromSelector(@selector(mouseUp)) options:NSKeyValueObservingOptionNew context:transportHUDSeekPosChangedMouseUpContext];
	[transportHUD addObserver:self forKeyPath:NSStringFromSelector(@selector(mouseDown)) options:NSKeyValueObservingOptionNew context:transportHUDSeekPosChangedMouseDownContext];
	dispatch_async(backgroundQueue, ^
				{
					do
					{
						usleep(5000);
						if (!movieWindow)
						{
							break;
						}
						CMTime currentTime = movieWindow.player.currentItem.currentTime;
						double currentTimeInSeconds = currentTime.value / currentTime.timescale;
						double durationInSeconds = assetParser.duration.value / assetParser.duration.timescale;
						double pr = currentTimeInSeconds / durationInSeconds;		//"Percent Read"
						[transportHUD setPercentRead:[NSNumber numberWithDouble:pr]];
					} while (playing);
				});

};

- (void)setupMyMixerWindow
{
	myMixerWindow = [[MixerWindow alloc] init];
	[myMixerWindow setChannelStripArray:channelStripArray];
	[myMixerWindow addObserver:self forKeyPath:NSStringFromSelector(@selector(reset)) options:NSKeyValueObservingOptionNew context:mixerResetButtonContext];
	[myMixerWindow addObserver:self
					forKeyPath:NSStringFromSelector(@selector(playing))
					options:NSKeyValueObservingOptionNew
					context:mixerPlayPauseContext];
	NSScreen* primaryDisplay = [NSScreen mainScreen];
	NSRect visibleFrame = primaryDisplay.visibleFrame;
	NSRect originRect = {0};
	originRect.origin.x = visibleFrame.size.width / 7;
	originRect.origin.y = visibleFrame.size.height;
	NSPoint startPoint = [[movieWindow window] cascadeTopLeftFromPoint:originRect.origin];
	//		[movieWindow showWindow:self];
	[[movieWindow window] makeFirstResponder:nil];
	[[movieWindow window] makeFirstResponder:[self window]];

	NSSize frameOffsetRect = [[self window] frame].size;
	startPoint.x += frameOffsetRect.width;
	[[myMixerWindow window]cascadeTopLeftFromPoint:startPoint];

}

- (void)deallocMyMixerWindow
{
	for (int i=0; i < assetParser.audioTracks.count; ++i)
	{
		[self removeObjectFromChannelStripArrayAtIndex:0];
	}
//	[myMixerWindow removeObserver:self forKeyPath:NSStringFromSelector(@selector(reset))];
//	[myMixerWindow removeObserver:self forKeyPath:NSStringFromSelector(@selector(playing))];
//	myMixerWindow = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{

	if (context == &mediaStatusContext) {
		NSLog(@"Calling media status observer\n");
		NSLog(@"AssetReader status is %@\n", [change valueForKey:NSKeyValueChangeNewKey]);
	}
	if (context == &needsNewBufferContext)
	{

	}
#pragma mark MEDIA_READY
	if (context == &mediaIsReadyContext)
	{
		if ([change valueForKey:NSKeyValueChangeNewKey] == [NSNumber numberWithBool:YES])
		{
			if ([assetParser.mediaIsReady intValue] == [[NSNumber numberWithBool:YES]intValue])
			{

				mixer.userDataStructs = assetParser.userDataStructs;
				mixer.nSourceTracks = [[NSNumber alloc] initWithInt:(int)assetParser.audioTracks.count];
				mixer.graph = [mixer.graph initGraphWithUserDataStruct:assetParser.userDataStructs numberOfStructs:[NSNumber numberWithInteger:assetParser.audioTracks.count]];

				[mixer registerCallbacks];

				//Now set up the mixer window
				if (!channelStripArray)
				{
//					channelStripArray = [NSMutableArray alloc];
					channelStripArray = [[NSMutableArray alloc] init];
				}
//				channelStripArray = [channelStripArray init];
				for (int i=0; i < assetParser.audioTracks.count; ++i)
				{

					if (i + 1 > channelStripArray.count)
					{
						GMBChannelStrip* chanStrip = [[GMBChannelStrip alloc] initWithChannelNum:[NSNumber numberWithInt:i]
																			withUserDataStruct:&mixer.userDataStructs[i]
																			withOutputBusArray:&mixer.graph.outputBusArray[i]
																					withGraph:mixer.graph];
						[channelStripArray addObject:chanStrip];

					}
				}

				if (!myMixerWindow)
				{
					[self setupMyMixerWindow];
//					[myMixerWindow showWindow:self];
				}

				[myMixerWindow setChannelStripArray:channelStripArray];





//				NSLog(@"userDataStructs have been linked from assetParser to mixer\n");

				if (!movieWindowCreated)
				{
					movieWindow = [[GMBMovieWindow alloc] init];
					movieWindow.player = assetParser.player;
					movieWindowCreated = YES;
					//Now display the movie window
					[movieWindow showWindow:self];
					//Now that window is showing, player layer must be set.
					[(GMBEventHandlerView*)movieWindow.movieRootView.view addObserver:self forKeyPath:NSStringFromSelector(@selector(userChangedSeek)) options:NSKeyValueObservingOptionNew context:transportHUDSeekPosChangedContext];
				}






				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(StopAudioButtonClicked:)
															name:@"AVPlayerItemDidPlayToEndTimeNotification"
														object:movieWindow.player.currentItem];
				[movieWindow.window makeFirstResponder:nil];
				if (_wasPlayingBeforeChangingSeek && _seekPosMouseUp)
				{
					[self PlayAudioButtonClicked:nil];
				}
			}

		}
	}
	if (context == mixerPlayPauseContext)
	{
//		[self PlayPauseButtonClicked:nil];
	}
	if (context == mixerResetButtonContext)
	{
		[self ResetButtonClicked:nil];
	}
	if (context == movieWindowSpacebarPressedContext)
	{
		BOOL newStatus = [[change objectForKey:NSKeyValueChangeNewKey]boolValue];
		if (newStatus == NO)
		{
			[self StopAudioButtonClicked:nil];
		}
		else
		{
			[self PlayAudioButtonClicked:nil];
		}
	}

	if (context == transportHUDSeekPosChangedMouseUpContext)
	{
		_seekPosMouseUp = YES;
		_seekPosMouseDown = NO;
		if (_wasPlayingBeforeChangingSeek && !playing)
		{
			if (assetParser.mediaIsReady)
			{
				[self PlayAudioButtonClicked:nil];
			}
		}

	}

	if (context == transportHUDSeekPosChangedMouseDownContext)
	{
		_seekPosMouseDown = YES;
		_seekPosMouseUp = NO;
		if (playing)
		{
			_wasPlayingBeforeChangingSeek = YES;
			[self stopAudioQuietly];
		}
		[self deallocMyMixerWindow];

	}
	if (context == assetReaderDeallocContext)
	{
		if ([change valueForKey:NSKeyValueChangeOldKey] == assetParser.assetReader)
		{
			[assetParser removeObserver:self forKeyPath:NSStringFromSelector(@selector(assetReader))];
			[assetParser.assetReader removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
			if (del)
			{
				[assetParser removeObserver:del forKeyPath:NSStringFromSelector(@selector(status))];
			}

		}
		if ([change valueForKey:NSKeyValueChangeNewKey])
		{

		}
	}



#pragma mark TRANSPORT_HUD_CHANGED
	if (context == transportHUDSeekPosChangedContext)
	{
		if (playing)
			[self stopAudioQuietly];


		double duration = assetParser.duration.value / assetParser.duration.timescale;
		double seekToTime = duration * [[(GMBEventHandlerView*)movieWindow.movieRootView.view percentRead] doubleValue];
		CMTime seekToTimeAsCMTime = CMTimeMake(seekToTime * assetParser.duration.timescale, assetParser.duration.timescale);
		[self seekToTime:seekToTimeAsCMTime];


		//Now do the same for the audio.
		[assetParser seekToTime:seekToTimeAsCMTime];
		[movieWindow.window makeFirstResponder:nil];
		[movieWindow.window makeFirstResponder:self.window];

//		[self deallocMyMixerWindow];
	}
}

-(void)seekToTime:(CMTime)time
{
	if (movieWindow)
	{
		[movieWindow.player seekToTime:time];
	}
}

-(void)unregisterObserversForAssetParser
{

}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)path
{

	//See if app was already open...
	openFileName = path;
	channelStripArray = nil;

	if (playing)
	{
		[self StopAudioButtonClicked:nil];
	}
	if (myMixerWindow)
	{
		[myMixerWindow removeObserver:self forKeyPath:NSStringFromSelector(@selector(reset))];
		[myMixerWindow removeObserver:self forKeyPath:NSStringFromSelector(@selector(playing))];
		[myMixerWindow close];
		myMixerWindow = nil;
	}
	if (movieWindow)
	{
		[movieWindow close];
//		[movieWindow removeObserver:self forKeyPath:NSStringFromSelector(@selector(isPlaying))];
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		movieWindow = nil;
	}
	if (assetParser.mediaIsReady)		   //mediaIsReady shouldn't be allocated at this point if it's the first run.
	{
		[assetParser removeObserver:self forKeyPath:NSStringFromSelector(@selector(mediaIsReady))];

	}

	if (!initialized)
	{
		return YES;			 //Not initialized, so no objects to send messages to.
	}

	else
	{
		if (assetParser)
		{
			[assetParser removeObserver:self forKeyPath:@"mediaIsReady"];
			assetParser = nil;
		}
		else
		{
			[assetParser addObserver:self forKeyPath:@"mediaIsReady" options:NSKeyValueObservingOptionNew context:mediaIsReadyContext];
		}

		[self applicationDidFinishLaunching:nil];
	}


	return YES;
}

-(void)AddTrackButtonClicked:(id)sender
{

}


@end

