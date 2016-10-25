//
//  SpringBoard.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 21/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "SpringBoard.h"
#import "CCPhysicsJoint.h"

@implementation SpringBoard
{
	// The __weak keyword was omitted on purpose to keep the reference to the joint even after it has been invalidated.
	CCPhysicsJoint* _lockJoint;
}

-(void) didLoadFromCCB
{
	Class distanceJointClass = NSClassFromString(@"CCPhysicsSlideJoint");
	NSAssert(distanceJointClass, @"distance joint class not found, it used to be called 'CCPhysicsSlideJoint', perhaps it was renamed?");
	
	NSLog(@">>> self: %@ physicsBody: %@, joints: %@", self, self.physicsBody, self.physicsBody.joints);
	NSAssert(self.physicsBody.joints.count, @"springboard joints list is empty");
	
	// get the joint of the specific CCPhysicsSlideJoint class
	// another way to identify a specific joint is to look at the joint's bodyA.node and bodyB.node properties
	for (CCPhysicsJoint* joint in self.physicsBody.joints)
	{
		if ([joint.bodyA.node.name isEqualToString:@"node A"] &&
			[joint.bodyB.node.name isEqualToString:@"node B"]) {
			// do something
		}
		
		if ([joint isKindOfClass:distanceJointClass])
		{
			_lockJoint = joint;
			break;
		}
	}
	
	NSAssert(_lockJoint, @"SpringBoard: lock joint not found");
}

-(void) letGo
{
	if (_lockJoint.valid)
	{
		// this removes the lock joint, if _lockJoint were __weak it would become nil immediately afterwards
		[_lockJoint invalidate];
		
		// wait for a short time, then create a new lock joint with the same bodies as the original lock joint
		[self scheduleOnce:@selector(resetSpring) delay:0.5];
	}
}

-(void) resetSpring
{
	// replace the original lock joint with the new one because invalidated joints can't be re-used!
	_lockJoint = [CCPhysicsJoint connectedDistanceJointWithBodyA:_lockJoint.bodyA
														   bodyB:_lockJoint.bodyB
														 anchorA:CGPointMake(0.0, -300.0)
														 anchorB:CGPointMake(32.0, 32.0)
													 minDistance:223.0
													 maxDistance:223.0];
	
	// Note: there are ways to obtain a Joint's private data such as anchors and distances, but this requires
	// use of the CCPhysicJoint private 'constraint' property to obtain the also private ChipmunkConstraint class.
}

@end
