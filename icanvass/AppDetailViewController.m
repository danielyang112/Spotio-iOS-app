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

@interface AppDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceModelLabel;
@property (weak, nonatomic) IBOutlet UILabel *iOSVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildNumberLabel;
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
	self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
//	[self setupLeftMenuButton];
	self.appVersionLabel.text = [self version];
	self.buildNumberLabel.text = [self build];
	self.deviceModelLabel.text = [self deviceName];
	self.iOSVersionLabel.text = [self iosVersion];
}

-(void)setupLeftMenuButton{
	MMDrawerBarButtonItem *leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
	[self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
}

-(void)leftDrawerButtonPress:(id)sender{
	[self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onExit:(id)sender {
  [self dismissViewControllerAnimated: NO completion:^{
  }];
	
}

-(NSString*) version {
	NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
	NSString *version = infoDictionary[@"CFBundleShortVersionString"];
	NSString *fullVersion = [NSString stringWithFormat:@"Version: %@", version];
	return fullVersion;
}

-(NSString*) build {
	NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
	NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
	NSString *fullVersion = [NSString stringWithFormat:@"Build: %@", build];
	return fullVersion;
}

-(NSString*) deviceName {
	NSString *name = [[UIDevice currentDevice] platformString];
	NSString *devName = [NSString stringWithFormat:@"Model: %@", name];
	return devName;
}

-(NSString*) iosVersion {
	float iosVer = [[UIDevice currentDevice].systemVersion floatValue];
	NSString *opName = [NSString stringWithFormat:@"iOS: %.1f", iosVer];
	return opName;
}

@end
