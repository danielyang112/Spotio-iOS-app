//
//  AlmostDoneViewController.h
//  icanvass
//
//  Created by Roman Kot on 17.04.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlmostDoneViewController : UIViewController <UIActionSheetDelegate>

@property (nonatomic,strong) NSString *company;
@property (nonatomic,strong) NSString *username;

@property (weak, nonatomic) IBOutlet UIButton *industryButton;
@property (weak, nonatomic) IBOutlet UIButton *roleButton;
@property (weak, nonatomic) IBOutlet UIButton *employeesButton;
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
- (IBAction)industry:(id)sender;
- (IBAction)role:(id)sender;
- (IBAction)employees:(id)sender;
- (IBAction)getStarted:(id)sender;

@end
