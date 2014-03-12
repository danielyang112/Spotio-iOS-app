//
//  ViewController.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "ViewController.h"
#import "ListController.h"
#import "MapController.h"

@interface ViewController ()
@property (nonatomic,strong) NSArray *controllers;
@property (nonatomic,weak) UIViewController *current;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ListController *list=[self.storyboard instantiateViewControllerWithIdentifier:@"ListController"];
    MapController *map=[self.storyboard instantiateViewControllerWithIdentifier:@"MapController"];
    self.controllers=@[list,map];
    [self cycleFromViewController:nil toViewController:list];
    
}

- (void)switchToViewController:(UIViewController*)vc {
    if(vc==_current) return;
    
    [self cycleFromViewController:_current toViewController:vc];
}

- (void)cycleFromViewController:(UIViewController*)oldv toViewController:(UIViewController*)newv {
    [oldv willMoveToParentViewController:nil];
    [self addChildViewController:newv];
    
    newv.view.frame=self.view.bounds;
    void(^completion)(BOOL)=^void(BOOL finished){
        [oldv removeFromParentViewController];
        [newv didMoveToParentViewController:self];
        self.current=newv;
    };
    
    if(!oldv) {
        [self.view addSubview:newv.view];
        completion(YES);
        return;
    }
    
    [self transitionFromViewController:oldv toViewController:newv
                              duration: 0.25 options:0
                            animations:^{}
                            completion:completion];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)valueChanged:(id)sender {
    UISegmentedControl *segmented=(UISegmentedControl*)sender;
    [self switchToViewController:_controllers[segmented.selectedSegmentIndex]];
}

@end
