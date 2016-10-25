//
//  GameMenuLayer.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 22/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameMenuLayer.h"
#import "GameScene.h"
#import "SceneManager.h"
#import "GameState.h"

@implementation GameMenuLayer
{
	__weak CCLabelBMFont* _hitsLabel;
	NSString* _hitsLocalizedFormatString;
	int _hitCount;
}

-(void) didLoadFromCCB
{
	_hitsLocalizedFormatString = _hitsLabel.string;
	[self updateHitsLabel];
}

-(void) updateHitsLabel
{
	if (_hitsLabel)
	{
		_hitsLabel.string = [NSString stringWithFormat:_hitsLocalizedFormatString, _hitCount];
	}
}

-(void) increaseHitCount
{
	_hitCount++;
	[self updateHitsLabel];
}

-(void) shouldPauseGame
{
	NSLog(@"BUTTON: should pause game");
	
	[_gameScene showPopoverNamed:@"UserInterface/Popovers/PauseMenuLayer"];
	// TODO: pause audio here
}

-(void) applicationWillResignActive:(UIApplication *)application
{
	[self shouldPauseGame];
}

-(void) shouldRestartGame
{
	[SceneManager presentGameSceneWithMusic:NO];
}

-(void) shouldExitGame
{
	[SceneManager presentMainMenu];
}

-(void) shouldResumeGame
{
	CCAnimationManager* am = self.animationManager;
	if ([am.runningSequenceName isEqualToString:@"resume game"] == NO)
	{
		[am runAnimationsForSequenceNamed:@"resume game"];
	}
}

-(void) resumeGameDidEnd
{
	[_gameScene removePopover];
	// TODO: resume audio here
}

-(void) shouldLoadNextLevel
{
	[GameState sharedGameState].currentLevel += 1;
	[SceneManager presentGameSceneWithMusic:NO];
}

@end
