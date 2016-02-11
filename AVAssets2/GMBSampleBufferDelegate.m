//
//  GMBSampleBufferDelegate.m
//  AVAssets2
//
//  Created by Graham Barab on 6/25/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBSampleBufferDelegate.h"


@implementation GMBSampleBufferDelegate
@synthesize circularBuffer;
@synthesize bufferQueue;
//@synthesize needsNewBuffer;
@synthesize doneReading;
@synthesize callbackDataStruct = callbackUserData;

-(id) initWithSize:(NSUInteger)bufferSizeInBytes
{
	self = [super init];
	bufferQueue = [[GMBQueue alloc] init];

	circularBuffer = malloc(sizeof(TPCircularBuffer));
	TPCircularBufferInit(circularBuffer, (int)bufferSizeInBytes);
	callbackUserData = malloc(sizeof(GMBAURenderCallbackUserData));

	callbackUserData->bufferIsReady = malloc(sizeof(bool));
	*callbackUserData->bufferIsReady = false;
	callbackUserData->cb = circularBuffer;

	dspBufferSize = (int)bufferSizeInBytes;
	dspBufferRefTimePerMilliSecond = dspBufferSize * 1000 / 44100.0;
	return self;
}

-(id) initWithASBD:(AudioStreamBasicDescription)asbd_
					usingBufferSize:(NSUInteger)size
{
	self = [super init];
	int nChannels = asbd_.mChannelsPerFrame;
	circularBuffer = malloc(sizeof(TPCircularBuffer));
	TPCircularBufferInit(circularBuffer, sizeof(Float32) * (int)size * nChannels);
	return self;
}

-(double)sampleRate
{
	return _sr;
}

-(void)setSampleRate:(double)sampleRate_
{
	_sr = sampleRate_;
	dspBufferRefTimePerMilliSecond = dspBufferSize * 1000 / 44100.0;
}

-(BOOL)needsNewBuffer
{
	return _needsNewBuffer;
}

-(void)setNeedsNewBuffer:(BOOL)needsNewBuffer_
{
	if (_needsNewBuffer == needsNewBuffer_)
		return;
	_needsNewBuffer = needsNewBuffer_;
	[self didChangeValueForKey:@"needsNewBuffer"];
}

-(BOOL)bufferProviderHasNoMoreBuffers
{
	return _bufferProviderHasNoMoreBuffers;
}

-(void) readDataFromCMSampleBufferRef:(CMSampleBufferRef)bufferRef
{

	AudioBufferList* bufferList = malloc(sizeof(AudioBufferList));
	CMBlockBufferRef blockBufferRef;
	bool success = false;

	CheckError(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(bufferRef,
															NULL,
															bufferList,
															sizeof(AudioBufferList),
															kCFAllocatorDefault,
															kCFAllocatorDefault,
															kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBufferRef), "Get Audio Buffer List for Circular Buffer");
//	
//	int nBuffers = bufferList->mNumberBuffers;
//	int nSamples = CMSampleBufferGetNumSamples(bufferRef);
//	int nChannels = bufferList->mBuffers->mNumberChannels;
	int byteSize = bufferList->mBuffers->mDataByteSize;

	success = TPCircularBufferProduceBytes(circularBuffer, bufferList->mBuffers->mData, 1024 * sizeof(Float32));
	Float32* answer = (Float32*)bufferList->mBuffers->mData;
	for (int i=0; i < byteSize / 4; ++i)
	{
		printf("%i: %f\n", i, *(answer + i));
	}
	CFRelease(blockBufferRef);

}

-(void)readDataFromQueue
{
	if (bufferQueue.count == 0)
	{
		NSLog(@"readDataFromQueue: Cannot start reading with no buffers in the queue\n");
	}
	doneReading = NO;
	//Get the AudioBufferList from the front of the stack
	NSValue* bufListWrapper = (NSValue*)bufferQueue.front;
	AudioBufferList bufList;
	[bufListWrapper getValue:&bufList];

	while (!doneReading && bufferQueue.count > 0)
	{
		*callbackUserData->bufferIsReady = false;
		//Get the new AudioBufferList
		bufListWrapper = (NSValue*)bufferQueue.front;
		[bufListWrapper getValue:&bufList];

		//Find out where we can start writing to the circular buffer
		int availableBytes;
		sizeOfCurrentBuffer = bufList.mBuffers->mDataByteSize / 4;
		Float32* writeHead = TPCircularBufferHead(circularBuffer, &availableBytes);
		if (availableBytes < 4)
		{
			break;
		}

		//Is the dspBufferSize smaller than the remaining samples?
		if (dspBufferSize <= (sizeOfCurrentBuffer - posInCurrentBuffer))
		{
			Float32* readPos = bufList.mBuffers[0].mData;
			readPos += posInCurrentBuffer;				  //Fast forward to where we left off.

			//Figure out how many times we can loop
			int loopTime = least((availableBytes / 4), (dspBufferSize));

			//Read those samples
			for (int i=0; i < loopTime / 2; ++i)
			{
				*(writeHead + i) = *readPos;
			}
			TPCircularBufferProduce(circularBuffer, (loopTime / 2) * 4);
			*callbackUserData->bufferIsReady = true;
			//Now that buffer is half filled, sleep for half of the dspBufferPeriod
			posInCurrentBuffer+= loopTime / 2;
			usleep((10667));
			continue;
		} else			  //Dsp buffer size is grater than what remains of AudioBufferList
		{
			//Read what remains, then pop the queue, read the rest and sleep.
			Float32* readPos = bufList.mBuffers->mData;
			readPos += posInCurrentBuffer;				  //Fast forward to where we left off.

			//Figure out how many times we can loop
			int loopTime = least((availableBytes / 4), (sizeOfCurrentBuffer - posInCurrentBuffer));

			//Read those samples
			for (int i=0; i < loopTime; ++i)
			{
				*(writeHead + i) = *readPos;
			}
			elementsLeftToReadOnThisPass -= loopTime;
			writeHead += loopTime;
			[bufferQueue pop];
			[self setNeedsNewBuffer:YES];
			posInCurrentBuffer = 0;
			bufListWrapper = (NSValue*)bufferQueue.front;
			[bufListWrapper getValue:&bufList];
			sizeOfCurrentBuffer = bufList.mBuffers->mDataByteSize / 4;

			loopTime = elementsLeftToReadOnThisPass;
			readPos = bufList.mBuffers->mData;
			for (int i=0; i < loopTime; ++i)
			{
				*(writeHead + i) = *readPos;
			}
			posInCurrentBuffer += loopTime;
			*callbackUserData->bufferIsReady = true;
			usleep(10667);
		}
	}
}

-(void)stopReading
{
	doneReading = YES;
}

-(void) printContents
{
	UInt32 length = circularBuffer->length / sizeof(Float32);
	Float32 answer;
	int32_t space;
	Float32* begin = (Float32*)TPCircularBufferTail(circularBuffer, &space);
	for (int i = 0; i < length; ++i)
	{
		answer = (Float32)(*(begin +  i));
		printf("%i: %f\n", i, answer);
	}
}

-(void)enqueueSampleBuffer:(NSValue*)buffer
{
	if (buffer == nil)
	{

		if (_bufferProviderHasNoMoreBuffers == NO)
		{
			_bufferProviderHasNoMoreBuffers = YES;
			[self didChangeValueForKey:@"bufferProviderHasNoMoreBuffers"];
		}

		return;
	}
	if (_bufferProviderHasNoMoreBuffers == NO)
	{
		_bufferProviderHasNoMoreBuffers = NO;
		[self didChangeValueForKey:@"bufferProviderHasNoMoreBuffers"];
	}
	[bufferQueue push:buffer];
}

-(void)dealloc
{
	free(circularBuffer);
}

@end

