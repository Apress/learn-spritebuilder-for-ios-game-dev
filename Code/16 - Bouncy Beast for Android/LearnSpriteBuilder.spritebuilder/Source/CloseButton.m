//
//  CloseButton.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 30/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CloseButton.h"

@implementation CloseButton

-(void) shouldClose
{
	// forward the selector to the closest parent class that implements the selector
	CCNode* aParent = self.parent;
	
	do
	{
		if ([aParent respondsToSelector:_cmd])
		{
			[aParent performSelector:_cmd withObject:nil afterDelay:0];
			break;
		}
		
		// try the next parent until parent returns nil (that would be the CCScene instance)
		aParent = aParent.parent;
	}
	while (aParent != nil);
	
	[[OALSimpleAudio sharedInstance] playEffect:@"Audio/menu-sfx.caf"];
}

@end
