//
//  GMBSeekPosLayer.m
//  MySpecialView
//
//  Created by Graham Barab on 8/7/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBSeekPosLayer.h"
#import <Cocoa/Cocoa.h>

@implementation GMBSeekPosLayer

-(id) init
{
	self = [super init];

	return self;
}

-(void)drawInContext:(CGContextRef)ctx
{

	CGContextSaveGState(ctx);
	CGMutablePathRef seekPosPathRef = CGPathCreateMutable();
	CGPathMoveToPoint(seekPosPathRef, NULL, 0, 0);
	CGPathAddRect(seekPosPathRef, NULL, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
	CGPathCloseSubpath(seekPosPathRef);



	CGContextAddPath(ctx, seekPosPathRef);
	CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
//	CGContextStrokePath(ctx);
//	CGContextAddPath(ctx, playBtnPathRef);
	CGContextFillPath(ctx);
	CGPathRelease(seekPosPathRef);
}

@end

