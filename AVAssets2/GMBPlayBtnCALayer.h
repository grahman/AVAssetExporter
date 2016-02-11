//
//  GMBPlayBtnCALayer.h
//  MySpecialView
//
//  Created by Graham Barab on 8/4/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Cocoa/Cocoa.h>


@interface GMBPlayBtnCALayer : CALayer
{
	BOOL _hoveringOverPlayButton;
}

-(void)drawInContext:(CGContextRef)ctx;

@end


