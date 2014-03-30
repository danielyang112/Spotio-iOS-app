//
//  FilterViewController.h
//  icanvass
//
//  Created by Roman Kot on 25.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DatesPickerViewController.h"

@interface FilterViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,DatesPickerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *statusTableView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
@end
