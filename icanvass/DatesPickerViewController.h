//
//  DatesPickerViewController.h
//  icanvass
//
//  Created by Roman Kot on 26.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DatesPickerViewController;
@protocol DatesPickerDelegate <NSObject>
- (void)datesPicker:(DatesPickerViewController*)picker changedFrom:(NSDate*)date;
- (void)datesPicker:(DatesPickerViewController*)picker changedTo:(NSDate*)date;
@end

@interface DatesPickerViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) NSDate *from;
@property (nonatomic,strong) NSDate *to;
@property (nonatomic,weak) id<DatesPickerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)dateChanged:(UIDatePicker *)sender;
@end
