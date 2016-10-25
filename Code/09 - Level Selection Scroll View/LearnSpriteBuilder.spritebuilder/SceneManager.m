//
//  SceneManager.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 23/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "SceneManager.h"
#import "GameScene.h"
#import "GameState.h"

@implementation SceneManager

+(void) presentMainMenu
{
	id s = [CCBReader loadAsScene:@"MainScene"];
	id t = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:1.0];
	[[CCDirector sharedDirector] presentScene:s withTransition:t];
}

+(void) presentGameScene
{
	CCScene* scene = [CCBReader loadAsScene:@"GameScene"];
	GameScene* gameScene = (GameScene*)scene.children.firstObject;

	int levelNumber = [GameState sharedGameState].currentLevel;
	NSString* level = [NSString stringWithFormat:@"Levels/Level%i", levelNumber];
	[gameScene loadLevelNamed:level];
	
	id t = [CCTransition transitionPushWithDirection:CCTransitionDirectionLeft duration:1.0];
	[[CCDirector sharedDirector] presentScene:scene withTransition:t];
}

+(void) presentGameSceneNoTransition
{
	[[CCDirector sharedDirector] presentScene:[CCBReader loadAsScene:@"GameScene"]];
}

@end
