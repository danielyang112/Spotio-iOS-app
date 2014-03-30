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
#import "ICRequestManager.h"
#import <FreshdeskSDK/FreshdeskSDK.h>


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
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    _mapSwitch.on=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
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

- (void)goToWebsiteWithText:(NSString*)text title:(NSString*)title{
    GoToWebsiteViewController *vc=[self.storyboard instantiateViewControllerWithIdentifier:@"GoToWebsiteViewController"];
    vc.text=text;
    vc.title=title;
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
    NSInteger on=sender.on?1:0;
    [[NSUserDefaults standardUserDefaults] setObject:@(on) forKey:@"Satellite"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICMapSettings" object:nil userInfo:nil];
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
}

- (IBAction)addUser:(id)sender {
    [self goToWebsiteWithText:@"Want to add some people to your team? No problem! Just click the button to go to the web app." title:@"Add User"];
}

- (IBAction)customizeStatus:(id)sender {
    [self goToWebsiteWithText:@"Make it work for you! Go ahead and login to the web app by clicking the button below." title:@"Customize Status"];
}

- (IBAction)customizeQuestions:(id)sender {
    [self goToWebsiteWithText:@"Need to gather more info? Add all you want in the iCanvass web app, click the button below." title:@"Customize Questions"];
}

- (IBAction)deletePin:(id)sender {
    [self goToWebsiteWithText:@"I know, I know. Made a mistake and want to delete a PIN. Go to the web app, just cklick below." title:@"Delete PIN"];
}

- (IBAction)reports:(id)sender {
    [self goToWebsiteWithText:@"Custom reports with all your data are just around the corner in the web app, click below." title:@"Reports"];
}

- (IBAction)support:(id)sender {
    NSString *username=[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey];
    [FDSupport setUseremail:username];
    [[FDSupport sharedInstance] presentSupport:self];
}

- (IBAction)logout:(id)sender {
    [[ICRequestManager sharedManager] logoutWithCb:^(BOOL success) {
        [self.mm_drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {}];
    }];
}
@end
