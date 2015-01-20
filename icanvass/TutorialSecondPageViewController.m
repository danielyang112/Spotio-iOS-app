//
//  TutorialSecondPageViewController.m
//  icanvass
//
//  Created by mobidevM199 on 16.11.14.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "TutorialSecondPageViewController.h"

@interface TutorialSecondPageViewController ()

@property (weak, nonatomic) IBOutlet UIView *darkView;

@end


@implementation TutorialSecondPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.darkView.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.7].CGColor;
	self.darkView.layer.borderWidth = 500.0;
	self.darkView.layer.cornerRadius = self.darkView.frame.size.height / 2.0;
	self.darkView.backgroundColor = [UIColor clearColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)onExit:(id)sender {
	[self.parentViewController dismissViewControllerAnimated:YES completion:^{}];
}

-(void)dealloc {

}
@end
