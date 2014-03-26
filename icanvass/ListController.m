//
//  ListController.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "ListController.h"
#import "DetailsViewController.h"
#import "Pins.h"
#import "PinCell.h"
#import "PinTemp.h"

enum ICSortOrder : NSUInteger {
    ICSortOrderStatusAscending,
    ICSortOrderStatusDescending,
    ICSortOrderAddressAscending,
    ICSortOrderAddressDescending,
    ICSortOrderDateAscending,
    ICSortOrderDateDescending
};

@interface ListController ()
@property (nonatomic,strong) NSArray *pins;
@property (nonatomic,strong) NSArray *sorted;
@property (nonatomic,strong) NSArray *filtered;
@property (nonatomic,strong) NSArray *statusDescriptors;
@property (nonatomic,strong) NSArray *addressDescriptors;
@property (nonatomic,strong) NSArray *dateDescriptors;
@property (nonatomic,strong) UIView *headerView;
@property (nonatomic,strong) NSSortDescriptor *currentDescriptor;
@property (nonatomic) enum ICSortOrder sortOrder;
@end

@implementation ListController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinsChanged:) name:@"ICPinsChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsChanged:) name:@"ICPinColors" object:nil];
        
        self.statusDescriptors=@[[[NSSortDescriptor alloc] initWithKey:@"status" ascending:YES],
                                              [[NSSortDescriptor alloc] initWithKey:@"status" ascending:NO]];
        self.addressDescriptors=@[[[NSSortDescriptor alloc] initWithKey:@"address" ascending:YES],
                                              [[NSSortDescriptor alloc] initWithKey:@"address" ascending:NO]];
        self.dateDescriptors=@[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES],
                                           [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO]];
        self.headerView=[[[NSBundle mainBundle] loadNibNamed:@"ListHeader" owner:nil options:nil] lastObject];
        UIButton *button=(UIButton*)[_headerView viewWithTag:1];
        [button addTarget:self action:@selector(sortStatus:) forControlEvents:UIControlEventTouchUpInside];
        button=(UIButton*)[_headerView viewWithTag:2];
        [button addTarget:self action:@selector(sortAddress:) forControlEvents:UIControlEventTouchUpInside];
        button=(UIButton*)[_headerView viewWithTag:3];
        [button addTarget:self action:@selector(sortDate:) forControlEvents:UIControlEventTouchUpInside];
        
        _currentDescriptor=_dateDescriptors[1];
        self.sortOrder=ICSortOrderDateDescending;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView=[UIView new];
}

- (void)sort {
    NSArray *descriptors=@[_currentDescriptor];
    self.pins=[self.pins sortedArrayUsingDescriptors:descriptors];
    [self.tableView reloadData];
}

- (void)refresh {
    [[Pins sharedInstance] sendPinsTo:^(NSArray *a) {
        self.pins=a;
        [self sort];
    }];
}

- (void)sortStatus:(id)sender {
    if(_sortOrder==ICSortOrderStatusAscending) {
        _sortOrder=ICSortOrderStatusDescending;
        self.currentDescriptor=_statusDescriptors[1];
    } else {
        _sortOrder=ICSortOrderStatusAscending;
        self.currentDescriptor=_statusDescriptors[0];
    }
    [self sort];
}

- (void)sortAddress:(id)sender {
    if(_sortOrder==ICSortOrderAddressAscending) {
        _sortOrder=ICSortOrderAddressDescending;
        self.currentDescriptor=_addressDescriptors[1];
    } else {
        _sortOrder=ICSortOrderAddressAscending;
        self.currentDescriptor=_addressDescriptors[0];
    }
    [self sort];
}

- (void)sortDate:(id)sender {
    if(_sortOrder==ICSortOrderDateAscending) {
        _sortOrder=ICSortOrderDateDescending;
        self.currentDescriptor=_dateDescriptors[1];
    } else {
        _sortOrder=ICSortOrderDateAscending;
        self.currentDescriptor=_dateDescriptors[0];
    }
    [self sort];
}
#pragma mark - Notifications

- (void)colorsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [self refresh];
}

- (void)pinsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [self refresh];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [_pins count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return _headerView.frame.size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PinCell";
    PinCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    PinTemp *pin=_pins[indexPath.row];
    cell.topLabel.text=pin.address;
    cell.bottomLabel.text=[NSString stringWithFormat:@"%@ %@, %@",pin.location.city, pin.location.state, pin.location.zip];
    cell.rightLabel.text=[PinTemp formatDate:pin.creationDate];
    cell.icon.backgroundColor=[[Pins sharedInstance] colorForStatus:pin.status];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    DetailsViewController *dc=(DetailsViewController*)[segue destinationViewController];
    NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
    dc.pin=_pins[selectedRowIndex.row];
}

@end
