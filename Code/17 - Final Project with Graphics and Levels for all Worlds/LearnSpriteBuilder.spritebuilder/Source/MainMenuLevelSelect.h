//
//  MainMenuLevelSelect.h
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 31/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@class MainMenuButtons;

@interface MainMenuLevelSelect : CCNode <CCScrollViewDelegate>

@property (weak) MainMenuButtons* mainMenuButtons;

@end
