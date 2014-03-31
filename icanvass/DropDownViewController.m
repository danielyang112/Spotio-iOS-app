//
//  DropDownViewController.m
//  icanvass
//
//  Created by Roman Kot on 31.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "DropDownViewController.h"

@interface DropDownViewController () {
    NSInteger _selectedRow;
}

@end

@implementation DropDownViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.view.backgroundColor=
    self.tableView.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    [self.tableView reloadData];
    // Do any additional setup after loading the view.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [_options count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DropDownCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text=_options[indexPath.row];
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    _selectedRow=indexPath.row;
    [_delegate dropDown:self changedTo:_options[indexPath.row]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
