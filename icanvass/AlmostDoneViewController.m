//
//  AlmostDoneViewController.m
//  icanvass
//
//  Created by Roman Kot on 17.04.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "AlmostDoneViewController.h"
#import "ICRequestManager.h"


@interface AlmostDoneViewController () {
    NSInteger mask;
}

@end

@implementation AlmostDoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
////    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
//    _getStartedButton.enabled=NO;
//    self.navigationItem.hidesBackButton=YES;
//    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Skip" style:UIBarButtonItemStyleDone target:self action:@selector(skip:)];
	// Do any additional setup after loading the view.
}

#pragma mark - Helpers
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
}

#pragma mark - Actions

- (void)skip:(id)sender {
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

//- (IBAction)industry:(id)sender {
//    [self showIndustries];
//}
//
//- (IBAction)role:(id)sender {
//    [self showRoles];
//}
//
//- (IBAction)employees:(id)sender {
//    [self showEmployees];
//}
//
//- (IBAction)getStarted:(id)sender {
//}
@end
