//
//  PlayTimelineWhenTriggered.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 16/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PlayTimelineWhenTriggered.h"

@implementation PlayTimelineWhenTriggered

-(void) didLoadFromCCB
{
	// if the custom property wasn't set use the "Default Timeline" by default
	if (_timelineName.length == 0)
	{
		_timelineName = @"Default Timeline";
	}
}

-(void) didTriggerWithNode:(CCNode*)activator
{
	NSLog(@"%@ triggered by '%@'", NSStringFromClass([self class]), activator.name);
	
	// start the animation, wrapped in a block to delay execution until after the collision event
	[self scheduleBlock:^(CCTimer *timer) {
		[self.animationManager runAnimationsForSequenceNamed:_timelineName];
	} delay:0.0];
}

@end
