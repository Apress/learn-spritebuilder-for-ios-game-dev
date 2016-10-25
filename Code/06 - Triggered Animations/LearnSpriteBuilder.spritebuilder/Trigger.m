//
//  Trigger.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 16/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Trigger.h"

static NSMutableDictionary* targetArrays;
static NSMutableDictionary* triggerArrays;

@implementation Trigger
{
	BOOL _repeatsForever;
}

-(void) didLoadFromCCB
{
	// if targets is nil (variables of type id are always initialized to 'nil' unless specified otherwise)
	// create and assign an instance of a NSMutableDictionary class (assumes triggerArray is also nil)
	if (targetArrays == nil)
	{
		targetArrays = [NSMutableDictionary dictionary];
		triggerArrays = [NSMutableDictionary dictionary];
	}

	// during load targets/triggers may contain items from the previous level, so remove them
	[targetArrays removeAllObjects];
	[triggerArrays removeAllObjects];
	
	_repeatsForever = (_triggerCount <= 0);
}

// only in onEnter will all nodes of the current level have been loaded, hence onEnter is used to collect these targets
// rather than didLoadFromCCB - otherwise we might miss some targets because they might not have been loaded
-(void) onEnter
{
	// must always call super in onEnter
	[super onEnter];
	
	// hide the trigger, you don't want to see it in the game
	self.parent.visible = NO;

	// take over the parent's name since the Color Node (trigger) isn't named
	NSAssert1(_parent.name.length > 0, @"Trigger node has no name: %@", self);
	self.name = _parent.name;
	
	// get or create the list of triggers
	NSPointerArray* triggers = [triggerArrays objectForKey:_name];
	if (triggers == nil)
	{
		triggers = [NSPointerArray weakObjectsPointerArray];
		[triggerArrays setObject:triggers forKey:_name];
	}
	
	// add this trigger to the list
	[triggers addPointer:(void*)self];
	
	// add targets if no targets using self.name have been gathered before (by another trigger of the same name)
	if ([targetArrays objectForKey:_name] == nil)
	{
		// The NSPointerArray allows us to store zeroing weak references to each target node, to prevent retaining target nodes.
		// This is important in case one of the triggered nodes is removed before the trigger activated.
		// Removed nodes can still be freed from memory, while this array contains either valid references or nil.
		NSPointerArray* targets = [NSPointerArray weakObjectsPointerArray];

		// add the list of targets using the trigger's name as key
		[targetArrays setObject:targets forKey:_name];
		
		// recursively find and add targets, this fills the targets array
		[self addTargetsTo:targets searchInNode:self.scene];
	}
}

-(void) addTargetsTo:(NSPointerArray*)targets searchInNode:(CCNode*)node
{
	// recursively search for nodes of the same name as the trigger node
	for (CCNode* child in node.children)
	{
		if ([child.name isEqualToString:_name])
		{
			// targets must also implement the trigger delegate protocol,
			// this also prevents adding triggers since they do not implement this protocol
			if ([child conformsToProtocol:@protocol(TriggerDelegate)])
			{
				[targets addPointer:(void*)child];
			}
		}
		
		// recursive: continue searching for targets in child's children
		[self addTargetsTo:targets searchInNode:child];
	}
}

-(void) triggerActivatedBy:(CCNode*)activator
{
	// let all targets run their trigger method and do whatever they need to do
	NSPointerArray* targets = [targetArrays objectForKey:_name];

	// send the trigger method to each target
	for (id target in targets)
	{
		[target didTriggerWithNode:activator];
	}

	// update trigger count and remove trigger if necessary
	if (_repeatsForever == NO)
	{
		NSPointerArray* triggers = [triggerArrays objectForKey:_name];
		[self updateTriggers:triggers];
		[self cleanupTriggers:triggers];
	}
}

-(void) updateTriggers:(NSPointerArray*)triggers
{
	// must decrease trigger count for all triggers of the same name
	// Note: this assumes all triggers of the same name have the same initial triggerCount
	for (Trigger* trigger in triggers)
	{
		trigger.triggerCount--;
	}
}

-(void) cleanupTriggers:(NSPointerArray*)triggers
{
	// if count is 0 or less the triggers should no longer activate
	if (_triggerCount <= 0)
	{
		// remove the trigger nodes
		for (Trigger* trigger in triggers)
		{
			// triggers are child nodes of the Trigger.CCB root node, so you'll want to remove its parent as well
			[trigger.parent removeFromParent];
		}
		
		// cleanup triggers and targets
		[targetArrays removeObjectForKey:_name];
		[triggerArrays removeObjectForKey:_name];
	}
}

@end
