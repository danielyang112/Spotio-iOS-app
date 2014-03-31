//
//  DatePickerViewController.m
//  icanvass
//
//  Created by Roman Kot on 31.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "DatePickerViewController.h"

@interface DatePickerViewController ()

@end

@implementation DatePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    self.tableView.backgroundColor=[UIColor clearColor];
    self.datePicker.minimumDate=[NSDate date];
    [self.datePicker setDate:_date animated:YES];
    [self.tableView reloadData];
    // Do any additional setup after loading the view.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DatePickerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text=_name;
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat=@"MM/dd/yy hh:mm a";
    }
    cell.detailTextLabel.text=[dateFormatter stringFromDate:_date];
    
    return cell;
}

- (IBAction)dateChanged:(UIDatePicker *)sender {
    self.date=sender.date;
    [self.tableView reloadData];
    [_delegate datePicker:self changedDate:_date];
}
@end
