//
//  LeftDrawerViewController.h
//  icanvass
//
//  Created by Roman Kot on 24.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeftDrawerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISwitch *mapSwitch;

- (IBAction)pins:(id)sender;
- (IBAction)satelliteView:(id)sender;
- (IBAction)switchChanged:(UISwitch *)sender;
- (IBAction)reports:(id)sender;
- (IBAction)support:(id)sender;
- (IBAction)logout:(id)sender;

@end
