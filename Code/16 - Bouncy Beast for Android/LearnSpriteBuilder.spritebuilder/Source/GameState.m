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
		
		// Initially set volumes to the volume levels restored from NSUserDefaults
		[OALSimpleAudio sharedInstance].effectsVolume = sharedInstance.effectsVolume;
		[OALSimpleAudio sharedInstance].bgVolume = sharedInstance.musicVolume;
	});
	
	return sharedInstance;
}

-(void) synchronize
{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Music Volume

static NSString* KeyForMusicVolume = @"musicVolume";

-(void) setMusicVolume:(CGFloat)volume
{
	[OALSimpleAudio sharedInstance].bgVolume = volume;
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
	[OALSimpleAudio sharedInstance].effectsVolume = volume;
	[[NSUserDefaults standardUserDefaults] setDouble:volume forKey:KeyForEffectsVolume];
}

-(CGFloat) effectsVolume
{
	// if the volume is already stored in user defaults, return the stored volume, otherwise default volume (1.0)
	NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:KeyForEffectsVolume];
	return (number ? number.doubleValue : 1.0);
}

#pragma mark Unlocked Level

static NSString* KeyForUnlockedLevel = @"unlockedLevel";

-(void) setHighestUnlockedLevel:(int)level
{
	//int totalLevelCount = 9;
	int totalLevelCount = [self levelCount];
	
	if (_currentLevel > 0 && _currentLevel <= totalLevelCount)
	{
		[[NSUserDefaults standardUserDefaults] setInteger:level forKey:KeyForUnlockedLevel];
	}
}

-(int) highestUnlockedLevel
{
	NSNumber* number = [[NSUserDefaults standardUserDefaults] objectForKey:KeyForUnlockedLevel];
	return (number ? [number intValue] : 1);
}

-(BOOL) unlockNextLevel
{
	int highest = self.highestUnlockedLevel;
	if (_currentLevel >= highest)
	{
		[self setHighestUnlockedLevel:_currentLevel + 1];
	}
	
	return (highest < self.highestUnlockedLevel);
}

-(int) levelCount
{
	// try to load "level#.ccbi" sequentially until a level file can not be found
	NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* path;
	int count = 0;
	
	do
	{
		count++;
		
		// published CCB files go by the extension "ccbi" and are located in "Published-iOS" folder (case sensitive!)
		NSString* level = [NSString stringWithFormat:@"Level%i", count];
		path = [mainBundle pathForResource:level ofType:@"ccbi" inDirectory:@"Published-iOS/Levels"];
		
	} while (path != nil);
	
	// the most recent level was not found, hence we should not count it
	count--;
	
	NSLog(@"INFO: found %i Level#.ccb file(s)", count);
	
	return count;
}

@end
