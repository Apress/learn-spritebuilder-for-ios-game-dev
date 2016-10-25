//
//  PlayTimelineWhenTriggered.h
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 16/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "Trigger.h"

@interface PlayTimelineWhenTriggered : CCNode <TriggerDelegate>

@property NSString* timelineName;

@end
