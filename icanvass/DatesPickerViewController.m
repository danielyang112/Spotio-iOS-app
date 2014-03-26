//
//  DatesPickerViewController.m
//  icanvass
//
//  Created by Roman Kot on 26.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "DatesPickerViewController.h"
#import "PinTemp.h"

@interface DatesPickerViewController () {
    NSInteger _selectedRow;
}

@end

@implementation DatesPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _selectedRow=0;
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self selectedFrom];
    // Do any additional setup after loading the view.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DateCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    if(indexPath.row==0) {
        label.text=@"From:";
        label=(UILabel*)[cell viewWithTag:2];
        label.text=[PinTemp formatDate:_from];
    } else {
        label.text=@"To:";
        label=(UILabel*)[cell viewWithTag:2];
        label.text=[PinTemp formatDate:_to];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _selectedRow=indexPath.row;
    if(_selectedRow==0) {
        [self selectedFrom];
    }else{
        [self selectedTo];
    }
    
}

- (void)selectedFrom {
    [_datePicker setDate:_from animated:YES];
}

- (void)selectedTo {
    [_datePicker setDate:_to animated:YES];
}

- (IBAction)dateChanged:(UIDatePicker *)sender {
    if(_selectedRow==0) {
        self.from=sender.date;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectedRow inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [_delegate datesPicker:self changedFrom:_from];
    } else {
        self.to=sender.date;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectedRow inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [_delegate datesPicker:self changedTo:_to];
    }
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}
@end
