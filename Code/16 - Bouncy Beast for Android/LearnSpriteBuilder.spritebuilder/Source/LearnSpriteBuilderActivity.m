/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2014 Apportable Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


#import "LearnSpriteBuilderActivity.h"

// needed to load a level directly
#import "GameScene.h"
#import "GameState.h"

@implementation LearnSpriteBuilderActivity

- (CCScene *)startScene
{
	NSLog(@"startScene");
	
	/*
#pragma message "REMOVE ME"
	// load first level instantly ...
	CCScene* scene = [CCBReader loadAsScene:@"GameScene"];
	GameScene* gameScene = (GameScene*)scene.children.firstObject;
	[GameState sharedGameState].currentLevel = 1;
	[gameScene loadLevelNamed:@"Levels/Level1"];
	return scene;
	 */
	
    return [CCBReader loadAsScene:@"MainScene"];
}

- (BOOL)onKeyUp:(int32_t)keyCode keyEvent:(AndroidKeyEvent *)event
{
    if (keyCode == AndroidKeyEventKeycodeBack)
    {
        [self finish];
    }
    return NO;
}

/*
-(void) onPause
{
	NSLog(@">>>>>>>>>>> onPause");
	[super onPause];
}

-(void) onResume
{
	NSLog(@">>>>>>>>>>> onResume");
	[super onResume];
}
*/

@end
