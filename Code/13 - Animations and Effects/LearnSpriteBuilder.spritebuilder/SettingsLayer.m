//
//  SettingsLayer.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 30/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "SettingsLayer.h"
#import "MainMenuButtons.h"
#import "GameState.h"

@implementation SettingsLayer
{
	__weak CCSlider* _musicSlider;
	__weak CCSlider* _effectsSlider;
	
	BOOL _playingEffectSliderAudio;
}

-(void) didLoadFromCCB
{
	GameState* gameState = [GameState sharedGameState];
	_musicSlider.sliderValue = gameState.musicVolume;
	_effectsSlider.sliderValue = gameState.effectsVolume;
}

-(void) volumeDidChange:(CCSlider*)sender
{
	NSLog(@"volume changed, sender: %@", sender);
	
	if (sender == _musicSlider)
	{
		[GameState sharedGameState].musicVolume = _musicSlider.sliderValue;
	}
	else if (sender == _effectsSlider)
	{
		[GameState sharedGameState].effectsVolume = _effectsSlider.sliderValue;
		
		if (_playingEffectSliderAudio == NO)
		{
			[[OALSimpleAudio sharedInstance] playEffect:@"Audio/menu-sfx.caf"];

			_playingEffectSliderAudio = YES;
			[self scheduleBlock:^(CCTimer *timer) {
				_playingEffectSliderAudio = NO;
			} delay:0.2f];
		}
	}
}

-(void) shouldClose
{
	NSLog(@"closing SettingsLayer");

	// force write-out of changed GameState values
	[[GameState sharedGameState] synchronize];

    // maybe play a timeline animation here instead of instantly removing the layer?
	[self removeFromParent];
	[_mainMenuButtons show];
}

@end
