//
//  GameMenuLayer.h
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 22/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@class GameScene;

@interface GameMenuLayer : CCNode

@property (weak) GameScene* gameScene;
-(void) increaseHitCount;

@end
