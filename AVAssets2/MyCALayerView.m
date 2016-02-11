//
//  MyCALayerView.m
//  MySpecialView
//
//  Created by Graham Barab on 8/2/14.
//  Copyright (c) 2014 Graham Barab. All rights reserved.
//

#import "MyCALayerView.h"

@interface MyCALayerView ()

@end

@implementation MyCALayerView

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {



	}
	return self;
}

-(id) init
{
	self = [super init];
	NSRect frame = {0};

	self.view = [[GMBEventHandlerView alloc] initWithFrame:frame];
	return self;
}

@end

