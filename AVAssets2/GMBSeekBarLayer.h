//
//  GMBSeekBarLayer.h
//  MySpecialView
//
//  Created by Graham Barab on 8/6/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Cocoa/Cocoa.h>

@interface GMBSeekBarLayer : CALayer
@property double percentRead;

-(void)drawInContext:(CGContextRef)ctx;

@end


