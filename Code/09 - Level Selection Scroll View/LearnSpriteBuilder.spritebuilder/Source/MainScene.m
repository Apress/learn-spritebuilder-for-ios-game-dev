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
}

@end
