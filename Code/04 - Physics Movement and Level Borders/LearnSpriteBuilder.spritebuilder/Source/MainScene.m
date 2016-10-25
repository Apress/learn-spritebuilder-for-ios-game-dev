//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"

@implementation MainScene

-(void) playButtonPressed
{
	CCScene* scene = [CCBReader loadAsScene:@"GameScene"];
	CCTransition* transition = [CCTransition transitionMoveInWithDirection:CCTransitionDirectionLeft duration:1.0];
	[[CCDirector sharedDirector] presentScene:scene withTransition:transition];
}

@end
