//
//  GameState.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 31/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameState.h"

@implementation GameState

// ARC-compatible singleton accessor
// Note: this does not prevent creating additional GameState instances via regular alloc/init!
+(GameState*) sharedGameState
{
	// static variables default to nil / 0
	static GameState* sharedInstance;
	static dispatch_once_t onceToken;
	
	// this block only runs once, creating the instance if it doesn't exist yet:
	dispatch_once(&onceToken, ^{
		sharedInstance = [[GameState alloc] init];
	});
	
	return sharedInstance;
}

#pragma mark Music Volume

static NSString* KeyForMusicVolume = @"musicVolume";

-(void) setMusicVolume:(CGFloat)volume
{
	[[NSUserDefaults standardUserDefaults] setDouble:volume forKey:KeyForMusicVolume];
}

-(CGFloat) musicVolume
{
	// if the volume is already stored in user defaults, return the stored volume, otherwise default volume (1.0)
	NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:KeyForMusicVolume];
	return (number ? number.doubleValue : 1.0);
}

#pragma mark Effects Volume

static NSString* KeyForEffectsVolume = @"effectsVolume";

-(void) setEffectsVolume:(CGFloat)volume
{
	[[NSUserDefaults standardUserDefaults] setDouble:volume forKey:KeyForEffectsVolume];
}

-(CGFloat) effectsVolume
{
	// if the volume is already stored in user defaults, return the stored volume, otherwise default volume (1.0)
	NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:KeyForEffectsVolume];
	return (number ? number.doubleValue : 1.0);
}

@end
