//
//  MainMenuButtons.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 29/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "MainMenuButtons.h"
#import "SettingsLayer.h"

@implementation MainMenuButtons

-(void) shouldPlayGame
{
	NSLog(@"PLAY");
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
