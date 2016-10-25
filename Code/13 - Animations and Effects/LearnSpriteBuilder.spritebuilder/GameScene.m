//
//  GameScene.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 25/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameScene.h"
#import "Trigger.h"
#import "GameMenuLayer.h"
#import "GameState.h"
#import "SpringBoard.h"

@implementation GameScene
{
	__weak CCNode* _levelNode;
	__weak CCPhysicsNode* _physicsNode;
	__weak CCNode* _playerNode;
	__weak CCNode* _backgroundNode;
	__weak GameMenuLayer* _gameMenuLayer;
	__weak GameMenuLayer* _popoverMenuLayer;
	
	CGFloat _playerNudgeRightVelocity;
	CGFloat _playerNudgeUpVelocity;
	CGFloat _playerMaxVelocity;
	BOOL _acceleratePlayer;
	
	BOOL _drawPhysicsShapes;
	BOOL _softBodyPlayer;
	BOOL _playingCollisionSound;
}

-(void) didLoadFromCCB
{
	_gameMenuLayer.gameScene = self;
	
	// enable receiving input events
	self.userInteractionEnabled = YES;

	/* Logging examples
	// basic data types
	int intValue = 123;
	NSUInteger unsignedIntegerValue = 456789;
	CGFloat floatValue = 0.123456789;
	NSLog(@"intValue=%i integerValue=%lu floatValue=%f floatValue.2=%.2f",
		  intValue, unsignedIntegerValue, floatValue, floatValue);

	// pointers
	NSString* helloLog = @"Hello Log";
	NSLog(@"string=%@ self=%@ cmd=%@",
		  helloLog, self, NSStringFromSelector(_cmd));
	
	// structs
	CGPoint point = CGPointMake(1024, 768);
	NSLog(@"point=%.0fx%.0f point=%@", point.x, point.y, NSStringFromCGPoint(point));
	 */
	
	// Display framerate and other counters:
	//[CCDirector sharedDirector].displayStats = YES;
	
	// Force framerate to 30 fps
	//[CCDirector sharedDirector].animationInterval = 1.0 / 30.0;
}

/*
// dump entire scene graph to console
-(void) onEnter
{
	[super onEnter];
	[self.scene walkSceneGraph:0];
}
*/

/* 
// Implement description method to change what objects of this class print via NSLog(@"%@", object)
-(NSString*) description
{
	return [NSString stringWithFormat:@"%@ selfPointer=%p selfClass=%@",
			[super description], self, NSStringFromClass([self class])];
}
 */

-(void) loadLevelNamed:(NSString*)levelCCB
{
	NSLog(@"loadLevelNamed: %@", levelCCB);
	NSAssert(levelCCB.length > 0, @"loadLevelNamed: received an empty or nil string");
	
	// remove the previous level
	[_levelNode removeFromParent];
	
	// Load the level (note: can't assign directly to _levelNode due to its _weak property)
	CCNode* level = [CCBReader load:levelCCB];
	NSAssert1(level, @"level could not be loaded: %@", levelCCB);
	// zOrder -1 draws the node before other nodes with zOrder 0 or higher
	level.zOrder = -1;
	[self addChild:level];
	
	// update _levelNode to the most recently loaded level
	_levelNode = level;
	
	_physicsNode = (CCPhysicsNode*)[_levelNode getChildByName:@"physics" recursively:NO];
	_physicsNode.debugDraw = _drawPhysicsShapes;
	_physicsNode.collisionDelegate = self;

	_backgroundNode = [_levelNode getChildByName:@"background" recursively:NO];
	
	_playerNode = [_physicsNode getChildByName:@"player" recursively:YES];
	
	// Soft body player has the actual player sprite as the first children
	if (_playerNode.children.count > 0)
	{
		CCNode* center = _playerNode.children.firstObject;
		_playerNode = center;
		_softBodyPlayer = YES;
	}
	
	// update the player position once, this focuses the view on the player before a scene transition runs
	CGPoint offset = (_softBodyPlayer ? _playerNode.parent.positionInPoints : CGPointZero);
	[self scrollToTarget:_playerNode withOffset:offset];
	
	NSAssert1(_physicsNode, @"physics node not found in level: %@", levelCCB);
	NSAssert1(_backgroundNode, @"background node not found in level: %@", levelCCB);
	NSAssert1(_playerNode, @"player node not found in level: %@", levelCCB);
}

-(void) completedAnimationSequenceNamed:(NSString*)name
{
	NSLog(@"completed animation sequence: %@", name);
}

-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	_acceleratePlayer = YES;
}

-(void) touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	_acceleratePlayer = NO;
}

-(void) touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
	[self touchEnded:touch withEvent:event];
}

-(void) update:(CCTime)delta
{
	if (_acceleratePlayer)
	{
		if (_softBodyPlayer)
		{
			for (CCNode* node in _playerNode.parent.children)
			{
				[self accelerateTarget:node];
			}
		}
		else
		{
			[self accelerateTarget:_playerNode];
		}
	}
	
	// update scroll node position to player node, with offset to center player in the view
	CGPoint offset = (_softBodyPlayer ? _playerNode.parent.positionInPoints : CGPointZero);
	[self scrollToTarget:_playerNode withOffset:offset];
}

-(void) accelerateTarget:(CCNode*)target
{
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

-(void) scrollToTarget:(CCNode*)target withOffset:(CGPoint)offset
{
	CGSize viewSize = [CCDirector sharedDirector].viewSize;
	CGPoint viewCenter = CGPointMake(viewSize.width / 2.0, viewSize.height / 2.0);
	
	CGPoint viewPos = ccpSub(ccpAdd(target.positionInPoints, offset), viewCenter);

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

/*
// collision of player with any body (wildcard)
-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player wildcard:(CCNode *)wildcard
{
	//NSLog(@"collision - player: %@, wildcard: %@", player, wildcard);

	// return YES to let the collision happen (bodies bounce off of each other)
	return YES;
}
 */

// collision of player with exit
-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player exit:(CCNode *)exit
{
	NSLog(@"collision with exit - player: %@, exit: %@", player, exit);

	[[GameState sharedGameState] unlockNextLevel];
	// make sure unlocked levels won't get lost if the app were to crash a moment later
	[[GameState sharedGameState] synchronize];
	
	[self showPopoverNamed:@"UserInterface/Popovers/LevelCompleteLayer"];

	// return NO to allow the bodies to intersect / pass through each other
	return NO;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player trigger:(Trigger *)trigger
{
	NSLog(@"collision with trigger - player: %@, trigger: %@", player, trigger);

	// inform the trigger which in turn passes the didTriggerWithNode: to the trigger's targets
	[trigger triggerActivatedBy:player];
	
	// return NO to allow the bodies to intersect / pass through each other
	return NO;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player saw:(CCNode *)saw
{
	NSLog(@"collision with saw - player: %@, saw: %@", player, saw);

	[self showPopoverNamed:@"UserInterface/Popovers/GameOverMenuLayer"];
	
	// return YES to let the collision happen (not that it matters on death...)
	return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player spring:(SpringBoard *)spring
{
	//NSLog(@"collision with spring - player: %@, spring: %@", player, spring);
	
	//NSLog(@"SPRING impulse: %f, %f, energy: %f, velocity: %f, %f", pair.totalImpulse.x, pair.totalImpulse.y, pair.totalKineticEnergy, pair.surfaceVelocity.x, pair.surfaceVelocity.y);
	[spring letGo];
	[self playCollisionSoundWithPair:pair];
	
	// return YES to let the collision happen (bodies bounce off of each other)
	return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player obstacle:(CCNode*)obstacle
{
	//NSLog(@"OBSTACLE impulse: %f, %f, energy: %f, velocity: %f, %f", pair.totalImpulse.x, pair.totalImpulse.y, pair.totalKineticEnergy, pair.surfaceVelocity.x, pair.surfaceVelocity.y);
	[self playCollisionSoundWithPair:pair];
	return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player gear:(CCNode*)gear
{
	//NSLog(@"GEAR impulse: %f, %f, energy: %f, velocity: %f, %f", pair.totalImpulse.x, pair.totalImpulse.y, pair.totalKineticEnergy, pair.surfaceVelocity.x, pair.surfaceVelocity.y);
	[self playCollisionSoundWithPair:pair];
	return YES;
}

/*
-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair player:(CCNode *)player border:(CCNode*)border
{
	//NSLog(@"BORDER impulse: %f, %f, energy: %f, velocity: %f, %f", pair.totalImpulse.x, pair.totalImpulse.y, pair.totalKineticEnergy, pair.surfaceVelocity.x, pair.surfaceVelocity.y);
	[self playCollisionSoundWithPair:pair];
	return YES;
}
 */

-(void) playCollisionSoundWithPair:(CCPhysicsCollisionPair*)pair
{
	if (pair.totalKineticEnergy > 0.0)
	{
		[_gameMenuLayer increaseHitCount];
	}

	if (_playingCollisionSound == NO && pair.totalKineticEnergy > 0.0)
	{
		NSString* splat = [NSString stringWithFormat:@"Audio/splat%i.caf", arc4random_uniform(3) + 1];
		[[OALSimpleAudio sharedInstance] playEffect:splat
											 volume:1.0
											  pitch:0.8 + (arc4random_uniform(50) / 100.0)	// generates random value in range 0.8 to 1.3
												pan:0.0
											   loop:NO];
		
		_playingCollisionSound = YES;
		[self scheduleBlock:^(CCTimer *timer) {
			_playingCollisionSound = NO;
		} delay:0.4];
	}
}

-(void) showPopoverNamed:(NSString*)popoverName
{
	// allow only one overlay menu at a time
	if (_popoverMenuLayer == nil)
	{
		// create a new menu manager with the pause menu
		GameMenuLayer* newMenuLayer = (GameMenuLayer*)[CCBReader load:popoverName];
		NSAssert1(newMenuLayer != nil, @"failed to load menu named: %@", popoverName);
		NSAssert1([newMenuLayer isKindOfClass:[GameMenuLayer class]], @"menu layer not using the GameMenuLayer class: %@", newMenuLayer);
		
		// since the menu loaded from CCB is a new node we need to add it as child
		[self addChild:newMenuLayer];
		
		// now that the new menu manager is retained by self.children we can assign it to its weak reference ivar
		// if we assigned to the __weak _overlayMenuManager ivar right away, ARC would have set it to nil before reaching the addChild: line!
		_popoverMenuLayer = newMenuLayer;
		_popoverMenuLayer.gameScene = self;
		
		// pause game and hide menu layer
		_gameMenuLayer.visible = NO;
		_levelNode.paused = YES;
	}
}

-(void) removePopover
{
	if (_popoverMenuLayer)
	{
		// remove the "regular" menu now
		[_popoverMenuLayer removeFromParent];
		// assigning nil is not strictly necessary since it is a zeroing __weak variable which is automatically
		// set to nil but it's nevertheless good style because it shows the intent
		_popoverMenuLayer = nil;
		
		// resume game and show menu layer
		_gameMenuLayer.visible = YES;
		_levelNode.paused = NO;
	}
}

@end
