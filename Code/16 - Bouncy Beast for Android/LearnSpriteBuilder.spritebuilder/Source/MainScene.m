//
//  MainScene.m
//  PROJECTNAME
//

#import "MainScene.h"
#import "GameState.h"

@implementation MainScene
{
	__weak CCScrollView* _levelSelectScrollView;
}

-(void) didLoadFromCCB
{
	NSLog(@"scroll view: %@", _levelSelectScrollView);

	// show the page with the highest unlocked level
	int numPages = _levelSelectScrollView.numHorizontalPages;
	if (numPages > 0)
	{
		int highest = [GameState sharedGameState].highestUnlockedLevel;
		int worldPage = (highest - 1) / numPages;
		
		// ensure page indices are 0-based, between 0 and 2
		worldPage = MIN(worldPage, numPages - 1);
		
		NSLog(@"changing to page: %i", worldPage);
		_levelSelectScrollView.horizontalPage = worldPage;
	}

	id levelSelect = _levelSelectScrollView.contentNode;
	_levelSelectScrollView.delegate = levelSelect;
	
	OALSimpleAudio* audio = [OALSimpleAudio sharedInstance];
#if __CC_PLATFORM_IOS
	[audio playBg:@"Audio/menu-music.m4a" loop:YES];
#elif __CC_PLATFORM_ANDROID
	// NOTE: the cocos2d version used here requires sound files for android to be addressed specifically - this will be fixed by the time you read this code
	[audio playBg:@"Published-Android/Audio/menu-music.ogg" loop:YES];
#endif

	/*
	// log font family and names
	for (NSString* family in [UIFont familyNames])
	{
		NSLog(@"%@ (family)", family);
		for (NSString* name in [UIFont fontNamesForFamilyName:family])
		{
			NSLog(@"   %@ (name)", name);
		}
	}
	 */
}

@end
