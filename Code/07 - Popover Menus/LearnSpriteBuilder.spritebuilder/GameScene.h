//
//  GameScene.h
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 25/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface GameScene : CCNode <CCPhysicsCollisionDelegate, CCBAnimationManagerDelegate>

-(void) showPopoverNamed:(NSString*)popoverName;
-(void) removePopover;

@end
