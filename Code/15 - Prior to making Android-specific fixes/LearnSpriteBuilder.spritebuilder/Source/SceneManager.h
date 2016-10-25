//
//  SceneManager.h
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 23/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SceneManager : NSObject

+(void) presentMainMenu;
+(void) presentGameSceneWithMusic:(BOOL)playMusic;
+(void) presentGameSceneNoTransition;

@end
