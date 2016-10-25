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

-(void) didLoadFromCCB
{
	NSLog(@"didLoadFromCCB: %@", self);
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
	[SceneManager presentGameScene];
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
	[SceneManager presentGameScene];
}

@end
