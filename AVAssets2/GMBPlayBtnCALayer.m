//
//  GMBPlayBtnCALayer.m
//  MySpecialView
//
//  Created by Graham Barab on 8/4/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBPlayBtnCALayer.h"

@implementation GMBPlayBtnCALayer

-(id)init
{
	self = [super init];
	return self;
}

-(void)drawInContext:(CGContextRef)ctx
{
	double scaleFactor = 0;
	if (_hoveringOverPlayButton)
	{
		scaleFactor = 2;
	} else {
		scaleFactor = 1;
	}
	CGContextSaveGState(ctx);
	CGMutablePathRef playBtnPathRef = CGPathCreateMutable();
	CGPathMoveToPoint(playBtnPathRef, NULL, 0, 0);
	CGPathAddLineToPoint(playBtnPathRef, NULL, 0, 20 * scaleFactor);
	CGPathAddLineToPoint(playBtnPathRef, NULL, 20 * scaleFactor, 10 * scaleFactor);
	CGPathCloseSubpath(playBtnPathRef);



	CGContextAddPath(ctx, playBtnPathRef);
	CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
	CGContextStrokePath(ctx);
	CGContextAddPath(ctx, playBtnPathRef);
	CGContextFillPath(ctx);
	CGPathRelease(playBtnPathRef);
}


@end

