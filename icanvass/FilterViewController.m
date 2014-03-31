//
//  FilterViewController.m
//  icanvass
//
//  Created by Roman Kot on 25.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "FilterViewController.h"
#import "Pins.h"
#import "PinTemp.h"
#import "Mixpanel.h"
#import "utilities.h"

#define kStatusSection 0
#define kCreationDateSection 1
#define kUserSection 1
#define kLastUpdatedSection 2

@interface FilterViewController () {
    BOOL _statusOn;
    BOOL _creationDateOn;
    BOOL _updateDateOn;
    NSInteger _pickerInSection;
}
@property (nonatomic,strong) NSDate *creationFrom;
@property (nonatomic,strong) NSDate *creationTo;
@property (nonatomic,strong) NSDate *updateFrom;
@property (nonatomic,strong) NSDate *updateTo;
@property (nonatomic,strong) NSArray *statuses;
@property (nonatomic,strong) NSMutableArray *selectedStatuses;

@end

@implementation FilterViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectedStatuses=[NSMutableArray arrayWithCapacity:5];
        self.creationFrom=[Pins sharedInstance].oldest;
        self.updateFrom=[Pins sharedInstance].oldest;
        self.creationTo=[Pins sharedInstance].newest;
        self.updateTo=[Pins sharedInstance].newest;
        NSDictionary *d=[Pins sharedInstance].filter;
        if(d){
            if(d[@"statuses"]) {
                self.selectedStatuses=d[@"statuses"];
                _statusOn=YES;
            }
            if(d[@"createdFrom"]) {
                self.creationFrom=d[@"createdFrom"];
                self.creationTo=d[@"createdTo"];
                _creationDateOn=YES;
            }
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    self.tableView.backgroundColor=[UIColor clearColor];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[Mixpanel sharedInstance] track:@"FilterView"];
    [[Pins sharedInstance] sendStatusesTo:^(NSArray *a) {
        self.statuses=a;
        [self.statusTableView reloadData];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView switchCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterSwitchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = switchView;
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    if(indexPath.section==kStatusSection) {
        label.text=@"Disposition";
        switchView.on=_statusOn;
        [switchView addTarget:self action:@selector(statusSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    } else if(indexPath.section==kCreationDateSection){
        label.text=@"Creation Date";
        switchView.on=_creationDateOn;
        [switchView addTarget:self action:@selector(creationDateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    } else if(indexPath.section==kLastUpdatedSection){
        label.text=@"Update Date";
        switchView.on=_updateDateOn;
        [switchView addTarget:self action:@selector(updateDateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView statusCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterStatusCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *status=_statuses[indexPath.row-1];
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    label.text=status;
    if([_selectedStatuses containsObject:status]){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView dateCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterDateCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    if(indexPath.section==kCreationDateSection) {
        label.text=[PinTemp formatDate:_creationFrom];
        label=(UILabel*)[cell viewWithTag:2];
        label.text=[PinTemp formatDate:_creationTo];
    } else {
        label.text=[PinTemp formatDate:_updateFrom];
        label=(UILabel*)[cell viewWithTag:2];
        label.text=[PinTemp formatDate:_updateTo];
    }
    
    return cell;
}

#pragma mark - Table View Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0 || indexPath.section>kStatusSection) {
        return indexPath;
    }
    NSString *status=_statuses[indexPath.row-1];
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType==UITableViewCellAccessoryNone){
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [_selectedStatuses addObject:status];
    } else if(cell.accessoryType==UITableViewCellAccessoryCheckmark) {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        [_selectedStatuses removeObject:status];
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _pickerInSection=indexPath.section;
    if(indexPath.section==kCreationDateSection) {
        [self performSegueWithIdentifier:@"DatesSegue" sender:nil];
    } else if(indexPath.section==kLastUpdatedSection) {
        [self performSegueWithIdentifier:@"DatesSegue" sender:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.row!=0);
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s",__FUNCTION__);
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s",__FUNCTION__);
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger ret=0;
    if(section==kStatusSection) {
        ret=_statusOn?[_statuses count]+1:1;
    } else if(section==kCreationDateSection) {
        ret=_creationDateOn?2:1;
    } else if(section==kLastUpdatedSection) {
        ret=_updateDateOn?2:1;
    }
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0) {
        return [self tableView:tableView switchCellForRowAtIndexPath:indexPath];
    }
    if(indexPath.section==0) {
        return [self tableView:tableView statusCellForRowAtIndexPath:indexPath];
    }
    return [self tableView:tableView dateCellForRowAtIndexPath:indexPath];
}

#pragma mark - DatesPickerDelegate

- (void)datesPicker:(DatesPickerViewController *)picker changedFrom:(NSDate *)date {
    if(_pickerInSection==kCreationDateSection) {
        self.creationFrom=date;
    }else{
        self.updateFrom=date;
    }
}

- (void)datesPicker:(DatesPickerViewController *)picker changedTo:(NSDate *)date {
    if(_pickerInSection==kCreationDateSection) {
        self.creationTo=date;
    }else{
        self.updateTo=date;
    }
}

#pragma mark - Actions

- (void)statusSwitchChanged:(UISwitch*)sender {
    _statusOn=sender.on;
    NSMutableArray *indexPaths=[NSMutableArray arrayWithCapacity:[_statuses count]];
    NSInteger k=[_statuses count];
    for(NSInteger i=0;i<k;++i) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i+1 inSection:kStatusSection]];
    }
    if(_statusOn) {
        [self.statusTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.statusTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [_selectedStatuses removeAllObjects];
    }
}

- (void)creationDateSwitchChanged:(UISwitch*)sender {
    _creationDateOn=sender.on;
    NSArray *indexPaths=@[[NSIndexPath indexPathForRow:1 inSection:kCreationDateSection]];
    if(_creationDateOn) {
        [self.statusTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.statusTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)updateDateSwitchChanged:(UISwitch*)sender {
    _updateDateOn=sender.on;
    NSArray *indexPaths=@[[NSIndexPath indexPathForRow:1 inSection:kLastUpdatedSection]];
    if(_updateDateOn) {
        [self.statusTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.statusTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (IBAction)done:(id)sender {
    NSMutableDictionary *d=[NSMutableDictionary dictionaryWithCapacity:2];
    if(_statusOn&&[_selectedStatuses count]){
        d[@"statuses"]=_selectedStatuses;
    }
    if(_creationDateOn){
        d[@"createdFrom"]=_creationFrom;
        d[@"createdTo"]=_creationTo;
    }
    if(_updateDateOn){
        d[@"updatedFrom"]=_updateFrom;
        d[@"updatedTo"]=_updateTo;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICFilter" object:nil userInfo:d];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICFilter" object:nil userInfo:nil];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DatesPickerViewController *d=segue.destinationViewController;
    d.delegate=self;
    if(_pickerInSection==kCreationDateSection) {
        d.from=_creationFrom;
        d.to=_creationTo;
    } else {
        d.from=_updateFrom;
        d.to=_updateTo;
    }
}

@end
