//
//  GMBSeekBarLayer.m
//  MySpecialView
//
//  Created by Graham Barab on 8/6/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "GMBSeekBarLayer.h"

@implementation GMBSeekBarLayer
@synthesize percentRead;

-(id) init
{
	self = [super init];
	percentRead = 0;
	[self setDelegate:self];
	return self;
}


-(void) drawInContext:(CGContextRef)ctx
{
	CGContextSaveGState(ctx);
	CGMutablePathRef outerBarPathRef = CGPathCreateMutable();
	CGPathMoveToPoint(outerBarPathRef, NULL, 0, 0);
	CGPathAddRect(outerBarPathRef, NULL, CGRectMake(0, 0, self.frame.size.width, 10));
//	CGPathAddEllipseInRect(outerBarPathRef, NULL, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
	CGPathCloseSubpath(outerBarPathRef);

	CGContextAddPath(ctx, outerBarPathRef);
	CGContextSetStrokeColorWithColor(ctx, [NSColor whiteColor].CGColor);
	CGContextStrokePath(ctx);
}


@end

