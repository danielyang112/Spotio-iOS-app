//
//  TutorialViewController.h
//  icanvass
//
//  Created by Roman Kot on 11.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialViewController : UIViewController <UIPageViewControllerDataSource>
@property (strong, nonatomic) UIPageViewController *pageController;
@end
