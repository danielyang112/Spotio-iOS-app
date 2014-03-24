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
#import "HomeViewController.h"
#import "GoToWebsiteViewController.h"


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

- (void)goToWebsiteWithText:(NSString*)text {
    GoToWebsiteViewController *vc=[self.storyboard instantiateViewControllerWithIdentifier:@"GoToWebsiteViewController"];
    vc.text=text;
    UINavigationController *nc=[[UINavigationController alloc] initWithRootViewController:vc];
    [self.mm_drawerController setCenterViewController:nc
                                   withCloseAnimation:YES
                                           completion:nil];
}

#pragma mark - Actions

- (IBAction)pins:(id)sender {
    UINavigationController *nc=[self.storyboard instantiateViewControllerWithIdentifier:@"InitialNavigationController"];
    [self.mm_drawerController setCenterViewController:nc
                                   withCloseAnimation:YES
                                           completion:nil];
}

- (IBAction)satelliteView:(id)sender {
    [_mapSwitch setOn:!_mapSwitch.on animated:YES];
    [self switchChanged:_mapSwitch];
}

- (IBAction)switchChanged:(UISwitch *)sender {
    NSDictionary *ui=@{@"satellite":[NSNumber numberWithBool:sender.on]};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICMapSettings" object:nil userInfo:ui];
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
}

- (IBAction)addUser:(id)sender {
    [self goToWebsiteWithText:@"go to website to add users!\nof course we will change this text"];
}

- (IBAction)customizeStatus:(id)sender {
    [self goToWebsiteWithText:@"go to website to customize statuses!\nof course we will change this text"];
}

- (IBAction)customizeQuestions:(id)sender {
    [self goToWebsiteWithText:@"go to website to customize questions!\nof course we will change this text"];
}

- (IBAction)deletePin:(id)sender {
    [self goToWebsiteWithText:@"go to website to delete pins!\nof course we will change this text"];
}

- (IBAction)reports:(id)sender {
    [self goToWebsiteWithText:@"go to website to generate reports!\nof course we will change this text"];
}

- (IBAction)support:(id)sender {
}

- (IBAction)logout:(id)sender {
    [[ICRequestManager sharedManager] logoutWithCb:^(BOOL success) {
        [self.mm_drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {}];
    }];
}
@end
