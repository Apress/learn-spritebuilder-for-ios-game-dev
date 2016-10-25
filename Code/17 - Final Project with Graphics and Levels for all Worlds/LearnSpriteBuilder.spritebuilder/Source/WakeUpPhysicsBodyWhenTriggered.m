//
//  WakeUpPhysicsBodyWhenTriggered.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 16/10/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "WakeUpPhysicsBodyWhenTriggered.h"

@implementation WakeUpPhysicsBodyWhenTriggered

-(void) didLoadFromCCB
{
	// sleep physics body (this only works as long as the body doesn't generate collisions)
	[self setSleeping:YES node:self];
}

-(void) didTriggerWithNode:(CCNode*)activator
{
	NSLog(@"%@ triggered by '%@'", NSStringFromClass([self class]), activator.name);
	
	// wake up
	[self setSleeping:NO node:self];
}

// recursively change the sleeping flag of physicsBody
-(void) setSleeping:(BOOL)sleeping node:(CCNode*)node
{
	node.paused = sleeping;
	
	CCPhysicsBody* body = node.physicsBody;
	body.sleeping = sleeping; // sleeping currently has no effect: https://github.com/cocos2d/cocos2d-swift/issues/738
	if (body.type == CCPhysicsBodyTypeDynamic)
	{
		body.affectedByGravity = !sleeping;
		
		if (!sleeping)
		{
			// give the body a slight nudge to force it to "wake up": https://github.com/cocos2d/cocos2d-swift/issues/1030
			[body applyImpulse:CGPointMake(0.000001, -0.000001)];
		}
	}
	
	// recurse into children
	for (CCNode* child in node.children)
	{
		[self setSleeping:sleeping node:child];
	}
}

@end
