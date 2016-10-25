//
//  MainMenuButtons.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 29/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "MainMenuButtons.h"
#import "SettingsLayer.h"
#import "MainMenuLevelSelect.h"

@implementation MainMenuButtons
{
	__weak MainMenuLevelSelect* _levelSelect;
}

-(void) didLoadFromCCB
{
	_levelSelect = (MainMenuLevelSelect*)[self.parent getChildByName:@"levelSelect" recursively:YES];
	NSAssert(_levelSelect, @"levelSelect node not found");
	_levelSelect.parent.visible = NO; // hide its parent (CCScrollView) just in case
	_levelSelect.mainMenuButtons = self;
}

-(void) shouldPlayGame
{
	NSLog(@"PLAY");

	_levelSelect.parent.visible = YES; // show the CCScrollView
	self.visible = NO;
}

-(void) shouldShowSettings
{
	NSLog(@"SETTINGS");
	
	SettingsLayer* settingsLayer = (SettingsLayer*)[CCBReader load:@"UserInterface/SettingsLayer"];
	NSAssert(settingsLayer != nil, @"failed to load settings layer");
	settingsLayer.mainMenuButtons = self;
	[self.parent addChild:settingsLayer];
	
	self.visible = NO;
}

-(void) show
{
	self.visible = YES;
    // maybe play a timeline animation here?
}

@end
