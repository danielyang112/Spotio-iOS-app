//
//  DatePickerViewController.h
//  icanvass
//
//  Created by Roman Kot on 31.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DatePickerViewController;
@protocol DatePickerDelegate <NSObject>
- (void)datePicker:(DatePickerViewController*)picker changedDate:(NSDate*)date;
@end

@interface DatePickerViewController : UIViewController
@property (nonatomic,weak) id<DatePickerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSDate *date;
@property (nonatomic,strong) NSIndexPath *indexPath;
@end
