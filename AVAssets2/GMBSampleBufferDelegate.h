//
//  GMBSampleBufferDelegate.h
//  AVAssets2
//
//  Created by Graham Barab on 6/25/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonHeaders.h"
#import "GMBDelegate.h"



//This struct will be used to send as inRefCon to AURenderCallback
typedef struct GMBAURenderCallbackUserData
{
	TPCircularBuffer*				cb;
	int							 nFramesToRead;
	AudioStreamBasicDescription	 streamFormat;
	bool*							bufferIsReady;
} GMBAURenderCallbackUserData;

@interface GMBSampleBufferDelegate : NSObject
{
	double						  _sr;
	int							 sizeOfCurrentBuffer;
	int							 posInCurrentBuffer;
	int							 elementsLeftToReadOnThisPass;
	int							 dspBufferSize;
	int							 dspBufferRefTimePerMilliSecond;
	GMBAURenderCallbackUserData*	callbackUserData;
	BOOL							_needsNewBuffer;
	BOOL							_bufferProviderHasNoMoreBuffers;
}
@property TPCircularBuffer*			  circularBuffer;
@property AudioStreamBasicDescription   asbd;
@property double					   sampleRate;
@property BOOL						  needsNewBuffer;
@property (readonly) BOOL			   bufferProviderHasNoMoreBuffers;
@property BOOL						  doneReading;
@property GMBQueue*					 bufferQueue;		//Will hold AudioBufferLists
@property GMBAURenderCallbackUserData*  callbackDataStruct;

-(id) initWithSize: (NSUInteger)bufferSizeInBytes;
-(id) initWithASBD: (AudioStreamBasicDescription)asbd_
					usingBufferSize:(NSUInteger)size;
-(void) readDataFromCMSampleBufferRef: (CMSampleBufferRef)bufferRef;
-(void) readDataFromQueue;
-(void) stopReading;
-(void) enqueueSampleBuffer: (NSValue*)buffer;  //This should encapsulate an AudioBufferList
-(void) printContents;
-(void) dealloc;

@end


