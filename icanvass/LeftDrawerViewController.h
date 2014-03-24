//
//  LeftDrawerViewController.h
//  icanvass
//
//  Created by Roman Kot on 24.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeftDrawerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *mapSwitch;
- (IBAction)pins:(id)sender;
- (IBAction)satelliteView:(id)sender;
- (IBAction)switchChanged:(UISwitch *)sender;
- (IBAction)addUser:(id)sender;
- (IBAction)customizeStatus:(id)sender;
- (IBAction)customizeQuestions:(id)sender;
- (IBAction)deletePin:(id)sender;
- (IBAction)reports:(id)sender;
- (IBAction)support:(id)sender;
- (IBAction)logout:(id)sender;

@end
