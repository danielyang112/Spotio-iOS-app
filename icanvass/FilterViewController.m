//
//  FilterViewController.m
//  icanvass
//
//  Created by Roman Kot on 25.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "FilterViewController.h"
#import "Pins.h"
#import "Pin.h"
#import "Users.h"
#import "Mixpanel.h"
#import "utilities.h"
#import "SVProgressHUD/SVProgressHUD.h"

#define kStatusSection 0
#define kCreationDateSection 1
#define kUserSection 2
#define kLastUpdatedSection 3

@interface FilterViewController () {
    BOOL _statusOn;
    BOOL _userOn;
    BOOL _creationDateOn;
    BOOL _updateDateOn;
    NSInteger _pickerInSection;
}
@property (nonatomic,strong) NSDate *creationFrom;
@property (nonatomic,strong) NSDate *creationTo;
@property (nonatomic,strong) NSDate *updateFrom;
@property (nonatomic,strong) NSDate *updateTo;
@property (nonatomic,strong) NSArray *statuses;
@property (nonatomic,strong) NSArray *users;
@property (nonatomic,strong) NSMutableArray *selectedStatuses;
@property (nonatomic,strong) NSMutableArray *selectedUsers;

@end

@implementation FilterViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectedStatuses=[NSMutableArray arrayWithCapacity:5];
        self.selectedUsers=[NSMutableArray arrayWithCapacity:5];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    self.tableView.backgroundColor=[UIColor clearColor];
    [self setupLeftMenuButton];
    [self updateFilterData];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self updateFilterData];
    [[Mixpanel sharedInstance] track:@"FilterView"];
    [[Pins sharedInstance] sendStatusesTo:^(NSArray *a) {
        self.statuses=a;
        [self.statusTableView reloadData];
    } failure:^(NSError *error) {
		[SVProgressHUD showErrorWithStatus:error.localizedDescription];
	}];
    [[Users sharedInstance] sendUsersTo:^(NSArray *a) {
        self.users=a;
        [self.statusTableView reloadData];
    }];
}

-(void)setupLeftMenuButton{
    
    UIButton *buttonL = [[UIButton alloc] initWithFrame:CGRectMake(-10, 0, 21, 37)];
    [buttonL setImage:[UIImage imageNamed:@"filter_back"] forState:UIControlStateNormal];
    [buttonL addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    UIButton *btnTitle = [[UIButton alloc] initWithFrame:CGRectMake(40, 0, 50, 20)];
    [btnTitle  setTitle:@"Filter" forState:UIControlStateNormal];
    UIBarButtonItem *barItem1 = [[UIBarButtonItem alloc] initWithCustomView:buttonL];
    UIBarButtonItem *barItem2 = [[UIBarButtonItem alloc] initWithCustomView:btnTitle];
    [self.navigationItem setLeftBarButtonItems:@[barItem1, barItem2] animated:YES];
}

- (void)updateFilterData {
    self.creationFrom=[Pins sharedInstance].oldest?:[NSDate date];
    self.updateFrom=[Pins sharedInstance].oldest?:[NSDate date];
    self.creationTo=[Pins sharedInstance].newest?:[NSDate date];
    self.updateTo=[Pins sharedInstance].newest?:[NSDate date];
    NSDictionary *d=[Pins sharedInstance].filter;
    if(d){
        if(d[@"statuses"]) {
            self.selectedStatuses=[d[@"statuses"] mutableCopy];
            _statusOn=YES;
        }
        if(d[@"createdFrom"]) {
            self.creationFrom=[d[@"createdFrom"] copy];
            self.creationTo=[d[@"createdTo"] copy];
            _creationDateOn=YES;
        }
        if(d[@"users"]) {
            self.selectedUsers=[d[@"users"] mutableCopy];
            _userOn=YES;
        }
    }
    [self.statusTableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView switchCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterSwitchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    //UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    //cell.accessoryView = switchView;
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    UIButton *btn = (UIButton *)[cell viewWithTag:2];
    if(indexPath.section==kStatusSection) {
        label.text=@"Status";
        //switchView.on=_statusOn;
        //[switchView addTarget:self action:@selector(statusSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [btn addTarget:self action:@selector(statusSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
    } else if(indexPath.section==kUserSection){
        label.text=@"Assigned to";
        //switchView.on=_userOn;
        //[switchView addTarget:self action:@selector(userSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [btn addTarget:self action:@selector(userSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
    } else if(indexPath.section==kCreationDateSection){
        label.text=@"Date";
        //switchView.on=_creationDateOn;
        //[switchView addTarget:self action:@selector(creationDateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [btn addTarget:self action:@selector(creationDateSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
    } else if(indexPath.section==kLastUpdatedSection){
        label.text=@"Update Date";
        //switchView.on=_updateDateOn;
        //[switchView addTarget:self action:@selector(updateDateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [btn addTarget:self action:@selector(updateDateSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView statusCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterStatusCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *status=_statuses[indexPath.row-1];
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    label.text=status;
    UIImageView *imgView = (UIImageView *)[cell viewWithTag:2];
    if ([status isEqualToString:@"Not Contacted"])
        imgView.image = [UIImage imageNamed:@"pin_notcontacted"];
    else if ([status isEqualToString:@"Sold - Test"])
        imgView.image = [UIImage imageNamed:@"pin_sold"];
    else if ([status isEqualToString:@"Not Interested"])
        imgView.image = [UIImage imageNamed:@"pin_notinterested"];
    else if ([status isEqualToString:@"Lead"])
        imgView.image = [UIImage imageNamed:@"pin_lead"];
    else if ([status isEqualToString:@"Not Home"])
        imgView.image = [UIImage imageNamed:@"pin_nothome"];
    
    UIImageView *imgCheck = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19, 19)];
    if([_selectedStatuses containsObject:status]){
        imgCheck.image = [UIImage imageNamed:@"filter_checked"];
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        imgCheck.image = [UIImage imageNamed:@"filter_unchecked"];
        //cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.accessoryView = imgCheck;
    cell.separatorInset = UIEdgeInsetsMake(0.f, cell.bounds.size.width, 0.f, 0.f);
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView userCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterUserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UserTemp *user=_users[indexPath.row-1];
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    label.text=user.fullName;
    UIImageView *imgCheck = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19, 19)];
    if([_selectedUsers containsObject:user.userName]){
        imgCheck.image = [UIImage imageNamed:@"filter_checked"];
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        imgCheck.image = [UIImage imageNamed:@"filter_unchecked"];
        //cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.accessoryView = imgCheck;
    cell.separatorInset = UIEdgeInsetsMake(0.f, cell.bounds.size.width, 0.f, 0.f);
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView dateCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterDateCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UILabel *label=(UILabel*)[cell viewWithTag:1];
    if(indexPath.section==kCreationDateSection) {
        label.text=[Pin formatDate:_creationFrom];
        label=(UILabel*)[cell viewWithTag:2];
        label.text=[Pin formatDate:_creationTo];
    } else {
        label.text=[Pin formatDate:_updateFrom];
        label=(UILabel*)[cell viewWithTag:2];
        label.text=[Pin formatDate:_updateTo];
    }
    
    return cell;
}

#pragma mark - Table View Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0 || indexPath.section==kCreationDateSection) {
        return indexPath;
    }
    if(indexPath.section==kStatusSection){
        NSString *status=_statuses[indexPath.row-1];
        UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
        UIImageView *imgView = (UIImageView *)cell.accessoryView;
        if(![_selectedStatuses containsObject:status]){
            imgView.image = [UIImage imageNamed:@"filter_checked"];
            //[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            [_selectedStatuses addObject:status];
        } else {
            imgView.image = [UIImage imageNamed:@"filter_unchecked"];
            //[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            [_selectedStatuses removeObject:status];
        }
    }else if(indexPath.section==kUserSection) {
        NSString *username=[_users[indexPath.row-1] userName];
        UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
        UIImageView *imgView = (UIImageView *)cell.accessoryView;
        if(![_selectedUsers containsObject:username]){
            imgView.image = [UIImage imageNamed:@"filter_checked"];
            //[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            [_selectedUsers addObject:username];
        } else {
            imgView.image = [UIImage imageNamed:@"filter_unchecked"];
            //[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            [_selectedUsers removeObject:username];
        }
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
    } else if(section==kUserSection) {
        ret=_userOn?[_users count]+1:1;
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
    if(indexPath.section==kStatusSection) {
        return [self tableView:tableView statusCellForRowAtIndexPath:indexPath];
    } else if(indexPath.section==kUserSection) {
        return [self tableView:tableView userCellForRowAtIndexPath:indexPath];
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

- (void)statusSwitchChanged:(UIButton*)sender {
    _statusOn = !_statusOn;
    NSMutableArray *indexPaths=[NSMutableArray arrayWithCapacity:[_statuses count]];
    NSInteger k=[_statuses count];
    for(NSInteger i=0;i<k;++i) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i+1 inSection:kStatusSection]];
    }
    if(_statusOn) {
        [self.statusTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_up"] forState:UIControlStateNormal];
    } else {
        [self.statusTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_down"] forState:UIControlStateNormal];
        [_selectedStatuses removeAllObjects];
    }
}

- (void)userSwitchChanged:(UIButton*)sender {
    _userOn = !_userOn;
    NSMutableArray *indexPaths=[NSMutableArray arrayWithCapacity:[_users count]];
    NSInteger k=[_users count];
    for(NSInteger i=0;i<k;++i) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i+1 inSection:kUserSection]];
    }
    if(_userOn) {
        [self.statusTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_up"] forState:UIControlStateNormal];
    } else {
        [self.statusTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_down"] forState:UIControlStateNormal];
        [_selectedUsers removeAllObjects];
    }
}

- (void)creationDateSwitchChanged:(UIButton*)sender {
    _creationDateOn = !_creationDateOn;
    NSArray *indexPaths=@[[NSIndexPath indexPathForRow:1 inSection:kCreationDateSection]];
    if(_creationDateOn) {
        [self.statusTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_up"] forState:UIControlStateNormal];
    } else {
        [self.statusTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_down"] forState:UIControlStateNormal];
    }
}

- (void)updateDateSwitchChanged:(UIButton*)sender {
    _updateDateOn = !_updateDateOn;
    NSArray *indexPaths=@[[NSIndexPath indexPathForRow:1 inSection:kLastUpdatedSection]];
    if(_updateDateOn) {
        [self.statusTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_up"] forState:UIControlStateNormal];
    } else {
        [self.statusTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [sender setBackgroundImage:[UIImage imageNamed:@"filter_arrow_down"] forState:UIControlStateNormal];
    }
}

- (IBAction)done:(id)sender {
    NSMutableDictionary *d=[NSMutableDictionary dictionaryWithCapacity:2];
    if(_statusOn&&[_selectedStatuses count]){
        d[@"statuses"]=[_selectedStatuses copy];
    }
    if(_userOn&&[_selectedUsers count]){
        d[@"users"]=[_selectedUsers copy];
    }
    if(_creationDateOn){
        d[@"createdFrom"]=[_creationFrom copy];
        d[@"createdTo"]=[_creationTo copy];
    }
    if(_updateDateOn){
        d[@"updatedFrom"]=[_updateFrom copy];
        d[@"updatedTo"]=[_updateTo copy];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICFilter" object:nil userInfo:d];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)cancel:(id)sender {
    [self updateFilterData];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICFilter" object:nil userInfo:nil];
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
