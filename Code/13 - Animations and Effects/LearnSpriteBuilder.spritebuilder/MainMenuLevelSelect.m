//
//  MainMenuLevelSelect.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 31/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "MainMenuLevelSelect.h"
#import "MainMenuButtons.h"
#import "SceneManager.h"
#import "GameState.h"

@implementation MainMenuLevelSelect

-(void) didLoadFromCCB
{
	int count = 1;
	int highest = [GameState sharedGameState].highestUnlockedLevel;
	CCNode* button;
	
	while ((button = [self getChildByName:@(count).stringValue recursively:YES]))
	{
		// if that specific level is unlocked (accessible) the sprite's color is set to white (full brightness)
		if (button.name.intValue <= highest)
		{
			CCSprite* sprite = (CCSprite*)button.parent;
			sprite.color = [CCColor whiteColor];
		}

		count++;
	}
}

-(void) shouldClose
{
	// just hide the parent (the CCScrollView)
	self.parent.visible = NO;
	[_mainMenuButtons show];
}

-(void) shouldLoadLevel:(CCButton*)sender
{
	GameState* gameState = [GameState sharedGameState];

	int levelNumber = sender.name.intValue;
	if (levelNumber <= gameState.highestUnlockedLevel)
	{
		gameState.currentLevel = levelNumber;
		[SceneManager presentGameSceneWithMusic:YES];
	}
	else
	{
		// maybe play a 'access denied' sound effect
	}
}

-(void) scrollViewDidScroll:(CCScrollView *)scrollView
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}
-(void) scrollViewWillBeginDragging:(CCScrollView *)scrollView
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}
-(void) scrollViewDidEndDragging:(CCScrollView * )scrollView willDecelerate:(BOOL)decelerate
{
	NSLog(@"%@%@", NSStringFromSelector(_cmd), decelerate ? @"YES" : @"NO");
}
-(void) scrollViewWillBeginDecelerating:(CCScrollView *)scrollView
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
	// This delegate method will only run when paging is not enabled
}
-(void) scrollViewDidEndDecelerating:(CCScrollView *)scrollView
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
