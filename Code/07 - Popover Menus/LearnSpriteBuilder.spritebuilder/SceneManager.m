//
//  SceneManager.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 23/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "SceneManager.h"

@implementation SceneManager

+(void) presentMainMenu
{
	id s = [CCBReader loadAsScene:@"MainScene"];
	id t = [CCTransition transitionMoveInWithDirection:CCTransitionDirectionLeft
											  duration:1.0];
	[[CCDirector sharedDirector] presentScene:s withTransition:t];
}

+(void) presentGameScene
{
	id s = [CCBReader loadAsScene:@"GameScene"];
	id t = [CCTransition transitionMoveInWithDirection:CCTransitionDirectionRight
											  duration:1.0];
	[[CCDirector sharedDirector] presentScene:s withTransition:t];
}

+(void) presentGameSceneNoTransition
{
	[[CCDirector sharedDirector] presentScene:[CCBReader loadAsScene:@"GameScene"]];
}

@end
