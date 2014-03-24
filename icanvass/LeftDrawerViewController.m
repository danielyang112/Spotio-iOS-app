//
//  LeftDrawerViewController.m
//  icanvass
//
//  Created by Roman Kot on 24.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "LeftDrawerViewController.h"
#import "ICRequestManager.h"
#import "MMDrawerController/UIViewController+MMDrawerController.h"

@interface LeftDrawerViewController ()

@end

@implementation LeftDrawerViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self=[super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

#pragma mark - Actions

- (IBAction)satelliteView:(id)sender {
}

- (IBAction)stwitchChanged:(UISwitch *)sender {
}

- (IBAction)addUser:(id)sender {
}

- (IBAction)customizeStatus:(id)sender {
}

- (IBAction)customizeQuestions:(id)sender {
}

- (IBAction)deletePin:(id)sender {
}

- (IBAction)reports:(id)sender {
}

- (IBAction)support:(id)sender {
}

- (IBAction)logout:(id)sender {
    [[ICRequestManager sharedManager] logoutWithCb:^(BOOL success) {
        [self.mm_drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {}];
    }];
}
@end
