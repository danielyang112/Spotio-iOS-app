//
//  AppDetailViewController.m
//  icanvass
//
//  Created by mobidevM199 on 13.11.14.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "AppDetailViewController.h"
#import "MMDrawerController/MMDrawerBarButtonItem.h"
#import "MMDrawerController/UIViewController+MMDrawerController.h"
#import "UIDevice-Hardware.h"
#import "ICRequestManager.h"
#import "Mixpanel.h"
#import "Pins.h"
#import <BugSense-iOS/BugSenseController.h>

@interface AppDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *iOSVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceModelLabel;
@property (weak, nonatomic) IBOutlet UILabel *logOutLabel;

- (IBAction)onLogOutClicked:(id)sender;

@end

@implementation AppDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	//self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    
	[self setupLeftMenuButton];
	self.appVersionLabel.text = [self version];
	//self.buildNumberLabel.text = [self build];
    self.iOSVersionLabel.text = [self iosVersion];
	self.deviceModelLabel.text = [self deviceName];
    self.logOutLabel.text = [self logoutText];
}

-(void)setupLeftMenuButton{
	MMDrawerBarButtonItem *leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
    UIButton *btnTitle = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 70, 20)];
    [btnTitle  setTitle:@"Settings" forState:UIControlStateNormal];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:btnTitle];
    [self.navigationItem setLeftBarButtonItems:@[leftDrawerButton, barItem] animated:YES];
}

-(void)leftDrawerButtonPress:(id)sender{
	[self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onLogOutClicked:(id)sender {
    [[Mixpanel sharedInstance] track:@"Logout"];
    [[ICRequestManager sharedManager] logoutWithCb:^(BOOL success) {
        [Pins sharedInstance].filter=nil;
        [self.mm_drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {}];
    }];
}

-(NSString*) version {
	NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
	NSString *version = infoDictionary[@"CFBundleShortVersionString"];
	NSString *fullVersion = [NSString stringWithFormat:@"%@", version];
	return fullVersion;
}

-(NSString*) build {
	NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
	NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
	NSString *fullVersion = [NSString stringWithFormat:@"Build: %@", build];
	return fullVersion;
}

-(NSString*) iosVersion {
    float iosVer = [[UIDevice currentDevice].systemVersion floatValue];
    NSString *opName = [NSString stringWithFormat:@"%.1f", iosVer];
    return opName;
}

-(NSString*) deviceName {
	NSString *name = [[UIDevice currentDevice] platformString];
	NSString *devName = [NSString stringWithFormat:@"%@", name];
	return devName;
}

-(NSString*) logoutText {
    NSString *opName = [NSString stringWithFormat:@"You are logged in as %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey]];
    return opName;
}

@end
