//
//  GameScene.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 25/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene
{
	__weak CCNode* _levelNode;
	__weak CCPhysicsNode* _physicsNode;
	__weak CCNode* _playerNode;
	__weak CCNode* _backgroundNode;
	
	CGFloat _playerNudgeRightVelocity;
	CGFloat _playerNudgeUpVelocity;
	CGFloat _playerMaxVelocity;
	BOOL _acceleratePlayer;
	
	BOOL _drawPhysicsShapes;
}

-(void) didLoadFromCCB
{
	// enable receiving input events
	self.userInteractionEnabled = YES;
	
	// load the current level
	[self loadLevelNamed:nil];
	
	NSLog(@"_levelNode = %@", _levelNode);
}

-(void) loadLevelNamed:(NSString*)levelCCB
{
	_physicsNode = (CCPhysicsNode*)[_levelNode getChildByName:@"physics" recursively:NO];
	_physicsNode.debugDraw = _drawPhysicsShapes;
	_backgroundNode = [_levelNode getChildByName:@"background" recursively:NO];
	_playerNode = [_physicsNode getChildByName:@"player" recursively:YES];

	NSAssert1(_physicsNode, @"physics node not found in level: %@", levelCCB);
	NSAssert1(_backgroundNode, @"background node not found in level: %@", levelCCB);
	NSAssert1(_playerNode, @"player node not found in level: %@", levelCCB);
}

-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	_acceleratePlayer = YES;
}

-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	_acceleratePlayer = NO;
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self touchEnded:touch withEvent:event];
}

-(void) exitButtonPressed
{
	NSLog(@"Get me outa here!");
	
	CCScene* scene = [CCBReader loadAsScene:@"MainScene"];
	CCTransition* transition = [CCTransition transitionFadeWithDuration:1.5];
	[[CCDirector sharedDirector] presentScene:scene withTransition:transition];
}

-(void) update:(CCTime)delta
{
	if (_acceleratePlayer)
	{
		[self accelerateTarget:_playerNode];
	}
	
	// update scroll node position to player node, with offset to center player in the view
	[self scrollToTarget:_playerNode];
}

-(void) accelerateTarget:(CCNode*)target
{
	/*
	// Temporary variables
	_playerMaxVelocity = 350.0;
	_playerNudgeRightVelocity = 30.0;
	_playerNudgeUpVelocity = 80.0;
	 */
	
	CCPhysicsBody* physicsBody = target.physicsBody;
	
	// when user taps the player should always move to the right instantly
	if (physicsBody.velocity.x < 0.0)
	{
		// this cancels out any negative (to the left) x axis movement
		physicsBody.velocity = CGPointMake(0.0, physicsBody.velocity.y);
	}
	
	// updates velocity taking body's mass into account
	[physicsBody applyImpulse:CGPointMake(_playerNudgeRightVelocity, _playerNudgeUpVelocity)];
	
	if (ccpLength(physicsBody.velocity) > _playerMaxVelocity)
	{
		// restrict velocity in given direction to maximum
		CGPoint direction = ccpNormalize(physicsBody.velocity);
		physicsBody.velocity = ccpMult(direction, _playerMaxVelocity);
	}
}

-(void) scrollToTarget:(CCNode*)target
{
	CGSize viewSize = [CCDirector sharedDirector].viewSize;
	CGPoint viewCenter = CGPointMake(viewSize.width / 2.0, viewSize.height / 2.0);
	
	CGPoint viewPos = ccpSub(target.positionInPoints, viewCenter);
	
	CGSize levelSize = _levelNode.contentSizeInPoints;
	viewPos.x = MAX(0.0, MIN(viewPos.x, levelSize.width - viewSize.width));
	viewPos.y = MAX(0.0, MIN(viewPos.y, levelSize.height - viewSize.height));
	
	_physicsNode.positionInPoints = ccpNeg(viewPos);
	
	
	
	CGPoint viewPosPercent = CGPointMake(viewPos.x / (levelSize.width - viewSize.width),
										 viewPos.y / (levelSize.height - viewSize.height));
	
	for (CCNode* layer in _backgroundNode.children)
	{
		CGSize layerSize = layer.contentSizeInPoints;
		CGPoint layerPos = CGPointMake(viewPosPercent.x * (layerSize.width - viewSize.width),
									   viewPosPercent.y * (layerSize.height - viewSize.height));
		layer.positionInPoints = ccpNeg(layerPos);
	}
}

@end
