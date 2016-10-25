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

+(void) presentGameSceneWithMusic:(BOOL)playMusic
{
	CCScene* scene = [CCBReader loadAsScene:@"GameScene"];
	GameScene* gameScene = (GameScene*)scene.children.firstObject;

	int levelNumber = [GameState sharedGameState].currentLevel;
	NSString* level = [NSString stringWithFormat:@"Levels/Level%i", levelNumber];
	[gameScene loadLevelNamed:level];
	
	id t = [CCTransition transitionPushWithDirection:CCTransitionDirectionLeft duration:1.0];
	[[CCDirector sharedDirector] presentScene:scene withTransition:t];

	// play music if requested
	if (playMusic)
	{
		OALSimpleAudio* audio = [OALSimpleAudio sharedInstance];
#if __CC_PLATFORM_IOS
		[audio playBg:@"Audio/game-music.m4a" loop:YES];
#elif __CC_PLATFORM_ANDROID
		// NOTE: the cocos2d version used here requires sound files for android to be addressed specifically - this will be fixed by the time you read this code
		[audio playBg:@"Published-Android/Audio/game-music.ogg" loop:YES];
#endif

	}
	
	// preloading prevents a short 'hiccup' when the sound effect is first played
	OALSimpleAudio* audio = [OALSimpleAudio sharedInstance];
	for (int i = 1; i <= 3; i++)
	{
		NSString* path = [NSString stringWithFormat:@"Audio/splat%i.caf", i];
		[audio preloadEffect:path];
	}
}

+(void) presentGameSceneNoTransition
{
	[SceneManager presentGameSceneWithMusic:NO];
}

@end
