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
#import "PocketSVG.h"
#import "utilities.h"
#import "Mixpanel.h"

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
@property (nonatomic,strong) UIButton *statusButton;
@property (nonatomic,strong) UIButton *addressButton;
@property (nonatomic,strong) UIButton *dateButton;
@property (nonatomic,strong) NSSortDescriptor *currentDescriptor;
@property (nonatomic,strong) NSString *searchText;
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
        self.dateDescriptors=@[[[NSSortDescriptor alloc] initWithKey:@"updateDate" ascending:YES],
                               [[NSSortDescriptor alloc] initWithKey:@"updateDate" ascending:NO]];
        self.headerView=[[[NSBundle mainBundle] loadNibNamed:@"ListHeader" owner:nil options:nil] lastObject];
        self.statusButton=(UIButton*)[_headerView viewWithTag:1];
        [_statusButton addTarget:self action:@selector(sortStatus:) forControlEvents:UIControlEventTouchUpInside];
        self.addressButton=(UIButton*)[_headerView viewWithTag:2];
        [_addressButton addTarget:self action:@selector(sortAddress:) forControlEvents:UIControlEventTouchUpInside];
        self.dateButton=(UIButton*)[_headerView viewWithTag:3];
        [_dateButton addTarget:self action:@selector(sortDate:) forControlEvents:UIControlEventTouchUpInside];
        
        _currentDescriptor=_dateDescriptors[1];
        self.sortOrder=ICSortOrderDateDescending;
    }
    return self;
}

- (void)viewWillLayoutSubviews {
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!_searchText || [_searchText isEqualToString:@""]){
        [self refresh];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [_searchBar resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView=[UIView new];
}

- (void)updateArrows {
    NSString *status=@"Status";
    NSString *address=@"Address";
    NSString *date=@"Date";
    switch (_sortOrder) {
        case ICSortOrderAddressAscending:
            address=[address stringByAppendingString:@" \u25b2"];
            break;
        case ICSortOrderAddressDescending:
            address=[address stringByAppendingString:@" \u25bc"];
            break;
        case ICSortOrderStatusAscending:
            status=[status stringByAppendingString:@" \u25b2"];
            break;
        case ICSortOrderStatusDescending:
            status=[status stringByAppendingString:@" \u25bc"];
            break;
        case ICSortOrderDateAscending:
            date=[date stringByAppendingString:@" \u25b2"];
            break;
        case ICSortOrderDateDescending:
            date=[date stringByAppendingString:@" \u25bc"];
            break;
            
        default:
            break;
    }
    [_statusButton setTitle:status forState:UIControlStateNormal];
    [_addressButton setTitle:address forState:UIControlStateNormal];
    [_dateButton setTitle:date forState:UIControlStateNormal];
}

- (void)sort {
    [self updateArrows];
    NSArray *descriptors=@[_currentDescriptor];
    self.pins=[self.pins sortedArrayUsingDescriptors:descriptors];
    self.filtered=[self.filtered sortedArrayUsingDescriptors:descriptors];
    [self.tableView reloadData];
}

- (void)filterArray {
    if(!_searchText || [_searchText isEqualToString:@""]){
        self.filtered=_pins;
        [self.tableView reloadData];
        return;
    }
    self.filtered=[_pins grepWith:^BOOL(NSObject *o) {
        PinTemp *p=(PinTemp*)o;
        return ([p.status rangeOfString:_searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
        || ([p.address rangeOfString:_searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
        || ([p.address2 rangeOfString:_searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
    }];
    [self.tableView reloadData];
}

- (void)refresh {
    NSLog(@"%s",__FUNCTION__);
    [[Pins sharedInstance] sendPinsTo:^(NSArray *a) {
        self.pins=a;
        self.filtered=a;
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
    return [_filtered count];
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
    PinTemp *pin=_filtered[indexPath.row];
    cell.topLabel.text=pin.address;
    cell.bottomLabel.text=pin.address2;
    cell.rightLabel.text=[PinTemp formatDate:pin.creationDate];
    cell.icon.backgroundColor=[[Pins sharedInstance] colorForStatus:pin.status];
    cell.icon.layer.borderColor=[UIColor darkGrayColor].CGColor;
    cell.icon.layer.borderWidth=1.f;
    /*
     CGPathRef path=[PocketSVG pathFromDAttribute:@"M0 0 h80 c40 0 50 10 50 50 v80 c0 25 0 25 -25 50 l-45 50 c-10 10 -30 10 -40 0 l-45 -50 c-25 -25 -25 -25 -25 -50 v-80 c0 -40 10 -50 50 -50 z"];
     
     
     CAShapeLayer *shapeLayer=[CAShapeLayer layer];
     shapeLayer.path=path;
     shapeLayer.lineWidth=20;
     CGRect boundingBox = CGPathGetBoundingBox(shapeLayer.path);
     
     CGFloat boundingBoxAspectRatio = CGRectGetWidth(boundingBox)/CGRectGetHeight(boundingBox);
     CGFloat viewAspectRatio = 1.0;
     
     CGFloat scaleFactor = 1.0;
     if (boundingBoxAspectRatio > viewAspectRatio) {
     // Width is limiting factor
     scaleFactor = CGRectGetWidth(cell.icon.frame)/CGRectGetWidth(boundingBox);
     } else {
     // Height is limiting factor
     scaleFactor = CGRectGetHeight(cell.icon.frame)/CGRectGetHeight(boundingBox);
     }
     
     
     // Scaling the path ...
     CGAffineTransform scaleTransform = CGAffineTransformIdentity;
     // Scale down the path first
     scaleTransform = CGAffineTransformScale(scaleTransform, scaleFactor, scaleFactor);
     // Then translate the path to the upper left corner
     scaleTransform = CGAffineTransformTranslate(scaleTransform, -CGRectGetMinX(boundingBox), -CGRectGetMinY(boundingBox));
     
     // If you want to be fancy you could also center the path in the view
     // i.e. if you don't want it to stick to the top.
     // It is done by calculating the heigth and width difference and translating
     // half the scaled value of that in both x and y (the scaled side will be 0)
     CGSize scaledSize = CGSizeApplyAffineTransform(boundingBox.size, CGAffineTransformMakeScale(scaleFactor, scaleFactor));
     CGSize centerOffset = CGSizeMake((CGRectGetWidth(cell.icon.frame)-scaledSize.width)/(scaleFactor*2.0),
     (CGRectGetHeight(cell.icon.frame)-scaledSize.height)/(scaleFactor*2.0));
     scaleTransform = CGAffineTransformTranslate(scaleTransform, centerOffset.width, centerOffset.height);
     // End of "center in view" transformation code
     
     CGPathRef scaledPath = CGPathCreateCopyByTransformingPath(shapeLayer.path,
     &scaleTransform);
     shapeLayer.path=scaledPath;
     shapeLayer.strokeColor=[[UIColor darkGrayColor] CGColor];
     shapeLayer.lineWidth=2;
     CAShapeLayer *another=[CAShapeLayer layer];
     another.path=scaledPath;
     another.strokeColor=[[UIColor whiteColor] CGColor];
     another.fillColor=[[[Pins sharedInstance] colorForStatus:pin.status] CGColor];
     another.lineWidth=1;
     [cell.icon.layer addSublayer:shapeLayer];
     [cell.icon.layer addSublayer:another];
     */
    return cell;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchText=searchText;
    [self filterArray];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    //self.searchText=nil;
    //[self filterArray];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    self.searchText=nil;
    [self filterArray];
    [searchBar resignFirstResponder];
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    DetailsViewController *dc=(DetailsViewController*)[segue destinationViewController];
    NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
    dc.pin=_filtered[selectedRowIndex.row];
}

@end
