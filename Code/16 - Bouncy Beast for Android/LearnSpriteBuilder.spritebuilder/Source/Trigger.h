//
//  Trigger.h
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 16/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@protocol TriggerDelegate <NSObject>
-(void) didTriggerWithNode:(CCNode*)activator;
@end

@interface Trigger : CCNode

@property int triggerCount;

-(void) triggerActivatedBy:(CCNode*)activator;

@end
