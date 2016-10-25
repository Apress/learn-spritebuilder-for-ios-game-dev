//
//  GameState.h
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 31/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameState : NSObject

+(GameState*) sharedGameState;

-(void) synchronize;

// Audio
@property CGFloat musicVolume;
@property CGFloat effectsVolume;

// Level
@property int currentLevel;
@property (readonly) int highestUnlockedLevel;
-(BOOL) unlockNextLevel;

@end
