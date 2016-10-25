//
//  SoftBodyDrawNode.m
//  LearnSpriteBuilder
//
//  Created by Steffen Itterheim on 28/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "SoftBodyDrawNode.h"

@implementation SoftBodyDrawNode
{
	int _numVertices;
	CCVertex* _vertices;
	CGPoint* _initialBodyPositions;

	CGFloat _enlargeDrawRadius;
	CGFloat _enlargeTextureRadius;
	
	BOOL _didLoad;
}

-(void) dealloc
{
	[self freeAllocatedMemory];
}

-(void) freeAllocatedMemory
{
	// ARC doesn't handle C memory management, so we have to free it ourselves
	// It is good practice to nil/NULL (same difference) free'd pointers, even in dealloc.
	free(_vertices);
	_vertices = nil;
	
	free(_initialBodyPositions);
	_initialBodyPositions = nil;
}

-(void) didLoadFromCCB
{
	[self setup];
	_didLoad = YES;

	[self logPointsOnCircleWithRadius:30 origin:CGPointMake(32, 32) numPoints:8];
}

-(void) logPointsOnCircleWithRadius:(CGFloat)radius origin:(CGPoint)origin numPoints:(int)numPoints
{
	NSLog(@"============================================================");
	CGFloat deltaAngle = 360.0 / numPoints;
	CGFloat angle = 360.0;
	
	for (int i = 1; i <= numPoints; i++)
	{
		CGPoint pos = CGPointMake(origin.x + radius * cos(CC_DEGREES_TO_RADIANS(angle)),
								  origin.y + radius * sin(CC_DEGREES_TO_RADIANS(angle)));
		NSLog(@"circumference point %i: {%.1f, %.1f} (angle: %.1f)", i, pos.x, pos.y, angle);
		angle -= deltaAngle;
	}
	NSLog(@"============================================================");
}

-(void) setup
{
	[self freeAllocatedMemory];

	// allocate memory for our vertex array
	_numVertices = (int)_children.count + 1;
	_vertices = calloc(_numVertices, sizeof(CCVertex));
	
	// allocate memory for the physics body original positions which represent our lookup coordinates of the texture
	_initialBodyPositions = calloc(_numVertices, sizeof(CGPoint));
	
	// remember the body's initial positions relative to the parent node
	int i = 0;
	CGPoint centerPos = ((CCNode*)_children[0]).positionInPoints;
	
	for (CCNode* child in _children)
	{
		if (child.physicsBody)
		{
			if (i == 0)
			{
				_initialBodyPositions[i] = centerPos;
			}
			else
			{
				CGPoint centerToChild = ccpSub(child.positionInPoints, centerPos);
				CGFloat newRadius = ccpLength(centerToChild) + _enlargeTextureRadius;
				CGPoint newPos = ccpMult(ccpNormalize(centerToChild), newRadius);
				_initialBodyPositions[i] = ccpAdd(newPos, centerPos);
			}
			
			//NSLog(@"initialpos: %@", NSStringFromCGPoint(_initialBodyPositions[i]));
			
			i++;
		}
	}
	
	// calculate the initial texture coords
	[self updateTextureCoordinates];
}

-(void) updateTextureCoordinates
{
	NSAssert2(_children.count >= 3,
			  @"not enough physics bodies (%i), %@ requires at least 3 child nodes with physics bodies",
			  (int)_children.count, NSStringFromClass([self class]));
	
	// we should set texture coordinates relative to the initial location of the physics bodies
	CCSpriteFrame* spriteFrame = self.spriteFrame;
	CGSize textureSize = spriteFrame.texture.contentSize;
	CGRect frameRect = spriteFrame.rect;
	CGSize frameSize = spriteFrame.originalSize;
	
	/*
	NSLog(@"SoftBody tex size: %.0fx%.0f, frame: %.0fx%.0f w:%.0f h:%.0f, orig size: %.0f, %.0f, rotated: %i", textureSize.width, textureSize.height,
		  frameRect.origin.x, frameRect.origin.y, frameRect.size.width, frameRect.size.height,
		  frameSize.width, frameSize.height, spriteFrame.rotated);
	 */
	
	for (int i = 0; i < _numVertices; i++)
	{
		// default color for each coordinate is completely white and opaque (ie texture is drawn as is with no color tinting or transparency)
		_vertices[i].color = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
		
		// convert the node position to texture coordinates, ensure tex coords are in the range 0.0 to 1.0
		// texture coordinate is simply a percentage of each child node's position relative to the texture size,
		// where 0.5, 0.5 is the texture center coordinate and 0,0 is the lower left corner
		CGPoint pos = _initialBodyPositions[i];
		
		// offset positions by origina of the sprite frame rectangle within the sprite sheet texture
		// Y coord is inverted (subtracted from top of the frame rectangle) because OpenGL textures are drawn upside down
		pos.x += frameRect.origin.x;
		pos.y = (frameRect.origin.y + frameSize.height) - pos.y;
		
		// MIN/MAX ensure texture coordinates can never be outside the bounds of the texture
		// Note: texCoord2 is ignored, it's only used by CCEffect/shaders
		_vertices[i].texCoord1 = (GLKVector2){
			MAX(0.0, MIN(pos.x / textureSize.width, 1.0)),
			1.0 - MAX(0.0, MIN(pos.y / textureSize.height, 1.0)),
		};
	}
	
	// coord and color for the last vertex same as the 2nd vertex to close the polygon
	int lastIndex = _numVertices - 1;
	_vertices[lastIndex].texCoord1 = _vertices[1].texCoord1;
	_vertices[lastIndex].color = _vertices[1].color;
	
	//[self logVertices];
}

-(void) logVertices
{
	for (int i = 0; i < _numVertices; i++)
	{
		CCVertex vertex = _vertices[i];
		GLKVector4 pos = vertex.position;
		GLKVector2 tc1 = vertex.texCoord1;
		GLKVector4 col = vertex.color;
		NSLog(@"%i: pos{%.1f, %.1f} tex{%.2f, %.2f} col{%.2f, %.2f, %.2f, %.2f}", i+1, pos.x, pos.y, tc1.x, tc1.y, col.r, col.g, col.b, col.a);
	}
}

-(void) draw:(CCRenderer *)renderer transform:(const GLKMatrix4 *)transform
{
	// Drawing the triangle fan. Simple explanation of how a triangle fan is drawn:
	// http://stackoverflow.com/questions/8043923/gl-triangle-fan-explanation
	
	// in a triangle fan the first 3 vertices form one triangle, then each additional vertex forms another triangle
	// thus number of triangles is number of vertices minus the initial 2 vertices for the first triangle
	int numTriangles = _numVertices - 2;
	CCRenderBuffer buffer = [renderer enqueueTriangles:numTriangles
										   andVertexes:_numVertices
											 withState:self.renderState
									   globalSortOrder:0];
	
	// update the vertex coordinates using each child node's current position, and add them to the render buffer
	int i = 0;
	CGPoint centerPos = ((CCNode*)_children[0]).position;
	
	for (CCNode* child in _children)
	{
		CGPoint vertexPos = child.position;
		if (i > 0)
		{
			// elongate vertex position outwards by the body size
			CGPoint vectorToCenter = ccpSub(child.position, centerPos);
			CGFloat length = ccpLength(vectorToCenter);
			CGPoint normalVector = ccpMult(vectorToCenter, 1.0 / length);
			vectorToCenter = ccpMult(normalVector, length + _enlargeDrawRadius);
			vertexPos = ccpAdd(vectorToCenter, centerPos);
		}
		
		_vertices[i].position = GLKVector4Make(vertexPos.x, vertexPos.y, 0.0, 1.0);
		
		CCRenderBufferSetVertex(buffer, i, CCVertexApplyTransform(_vertices[i], transform));
		i++;
	}
	
	// adding the first circumference vertex as the last vertex closes the (circular) polygon
	int lastIndex = _numVertices - 1;
	_vertices[lastIndex].position = GLKVector4Make(_vertices[1].position.x, _vertices[1].position.y, 0.0, 1.0);
	CCRenderBufferSetVertex(buffer, lastIndex, CCVertexApplyTransform(_vertices[lastIndex], transform));
	
	for (int i = 0; i < numTriangles; i++)
	{
		// draw triangle from center (0) to circumference vertices (i+1, i+2), re-using each circumference vertex twice
		CCRenderBufferSetTriangle(buffer, i, 0, i+1, i+2);
	}
}

// needed when the soft body should be animated with a sprite frame animation
-(void) setSpriteFrame:(CCSpriteFrame *)spriteFrame
{
	[super setSpriteFrame:spriteFrame];

	if (_didLoad)
	{
		// if the sprite frame changed from one to another update the vertices and tex coords
		[self updateTextureCoordinates];
	}
}

@end
