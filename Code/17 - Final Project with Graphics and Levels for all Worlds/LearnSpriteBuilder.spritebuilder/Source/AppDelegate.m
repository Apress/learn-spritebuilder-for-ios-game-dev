/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2012 Zynga Inc.
 * Copyright (c) 2013 Apportable Inc.
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

#import "cocos2d.h"

#import "AppDelegate.h"
#import "CCBuilderReader.h"

// needed to load a level directly
#import "GameScene.h"
#import "GameState.h"

@implementation AppController

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure Cocos2d with the options set in SpriteBuilder
    NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Published-iOS"]; // TODO: add support for Published-Android support
    configPath = [configPath stringByAppendingPathComponent:@"configCocos2d.plist"];
    
    NSMutableDictionary* cocos2dSetup = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
    
    // Note: this needs to happen before configureCCFileUtils is called, because we need apportable to correctly setup the screen scale factor.
#ifdef APPORTABLE
    if([cocos2dSetup[CCSetupScreenMode] isEqual:CCScreenModeFixed])
        [UIScreen mainScreen].currentMode = [UIScreenMode emulatedMode:UIScreenAspectFitEmulationMode];
    else
        [UIScreen mainScreen].currentMode = [UIScreenMode emulatedMode:UIScreenScaledAspectFitEmulationMode];
#endif
    
    // Configure CCFileUtils to work with SpriteBuilder
    [CCBReader configureCCFileUtils];
    
    // Do any extra configuration of Cocos2d here (the example line changes the pixel format for faster rendering, but with less colors)
    //[cocos2dSetup setObject:kEAGLColorFormatRGB565 forKey:CCConfigPixelFormat];
    
    [self setupCocos2dWithOptions:cocos2dSetup];
	
    return YES;
}

-(CCScene*) startScene
{
	//[CCDirector sharedDirector].displayStats = YES;
	
	/*
#pragma message "REMOVE ME"
	// load first level instantly ...
	CCScene* scene = [CCBReader loadAsScene:@"GameScene"];
	GameScene* gameScene = (GameScene*)scene.children.firstObject;
	[GameState sharedGameState].currentLevel = 10;
	[gameScene loadLevelNamed:[NSString stringWithFormat:@"Levels/Level%i", [GameState sharedGameState].currentLevel]];
	return scene;
	*/

	return [CCBReader loadAsScene:@"MainScene"];
}

-(void) performSelector:(SEL)selector onNode:(CCNode*)node withObject:(id)object recursive:(BOOL)recursive
{
	if ([node respondsToSelector:selector])
	{
		[node performSelector:selector withObject:object afterDelay:0];
	}
	
	if (recursive)
	{
		for (CCNode* child in node.children)
		{
			[self performSelector:selector onNode:child withObject:object recursive:YES];
		}
	}
}

-(void) applicationWillResignActive:(UIApplication *)application
{
	// forward this to the currently running scene's first node if it implements the same selector
	CCScene* scene = [CCDirector sharedDirector].runningScene;
	[self performSelector:_cmd onNode:scene withObject:application recursive:YES];
	
	// let CCAppDelegate handle default behavior
	[super applicationWillResignActive:application];
}

@end
