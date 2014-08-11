//
//  TutorialViewController.m
//  icanvass
//
//  Created by Roman Kot on 11.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "TutorialViewController.h"
#import "TutorialPageViewController.h"

@interface TutorialViewController ()

@end

@implementation TutorialViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)skip:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton=YES;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStyleDone target:self action:@selector(skip:)];
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    TutorialPageViewController *initialViewController = [self viewControllerAtIndex:0];
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIPageControllerDelegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(TutorialPageViewController *)viewController page];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(TutorialPageViewController *)viewController page];
    
    
    index++;
    
    if (index == 4) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}

- (TutorialPageViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    TutorialPageViewController *childViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TutorialPage"];
    childViewController.page = index;
    
    return childViewController;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
