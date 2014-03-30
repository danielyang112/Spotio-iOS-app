//
//  DetailsViewController.m
//  icanvass
//
//  Created by Roman Kot on 12.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "DetailsViewController.h"
#import "ICRequestManager.h"
#import "DetailsTableViewCell.h"
#import "Pins.h"
#import "Fields.h"
#import "utilities.h"

@interface DetailsViewController () <UIActionSheetDelegate>
@property (nonatomic,strong) NSString *streetNumber;
@property (nonatomic,strong) NSString *streetName;
@property (nonatomic,strong) NSString *zipCode;
@property (nonatomic,strong) NSString *city;
@property (nonatomic,strong) NSString *state;
@property (nonatomic,strong) NSDictionary *googleLocation;
@property (nonatomic,strong) NSString *status;
@property (nonatomic,strong) NSArray *statuses;

@property (nonatomic,strong) NSMutableArray *fields;
@property (nonatomic,strong) NSArray *customFields;
@property (nonatomic,strong) NSMutableDictionary *addedFields;

@end

@implementation DetailsViewController

#pragma mark - View Controller

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self=[super initWithCoder:aDecoder];
    if(self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fieldsChanged:) name:@"ICFields" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
        self.addedFields=[NSMutableDictionary dictionaryWithCapacity:2];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(_adding) {
        [self adjustForAdding];
    } else if(_pin){
        [self adjustForViewing];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateFields];
}

#pragma mark - Helpers

- (void)updateFields {
    [[Fields sharedInstance] sendFieldsTo:^(NSArray *a) {
        self.customFields=a;
        [_tableView reloadData];
    }];
}

- (void)adjustForAdding {
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem.enabled=NO;
    [_tableView setEditing:YES];
    [self updateAddressTextFields];
}

- (void)adjustForViewing {
    self.navigationItem.rightBarButtonItem=[self editButtonItem];
    [self extractPin];
    [self enableChanges:NO];
    [self updateAddressTextFields];
}

- (void)adjustForEditing {
    self.navigationItem.rightBarButtonItem=[self editButtonItem];
    [self extractPin];
    [self updateAddressTextFields];
    [self setEditing:YES animated:YES];
}

- (void)enableChanges:(BOOL)enable {
    _statusButton.enabled=enable;
    
    _streetNameTextField.enabled=enable;
    _streetNameTextField.borderStyle=enable?UITextBorderStyleRoundedRect:UITextBorderStyleNone;
    _streetNumberTextField.enabled=enable;
    _streetNumberTextField.borderStyle=enable?UITextBorderStyleRoundedRect:UITextBorderStyleNone;
    _cityStateZipTextField.enabled=enable;
    _cityStateZipTextField.borderStyle=enable?UITextBorderStyleRoundedRect:UITextBorderStyleNone;
    
    _numberStepper.hidden=!enable;
}

- (void)extractPin {
    self.streetName=_pin.location.streetName;
    self.streetNumber=_pin.location.streetNumber;
    self.city=_pin.location.city;
    self.state=_pin.location.state;
    self.zipCode=_pin.location.zip;
    
    self.status=_pin.status;
}

- (void)updateAddressTextFields {
    _streetNameTextField.text=_streetName;
    _streetNumberTextField.text=_streetNumber;
    if(![_city isEqualToString:@""]) {
        _cityStateZipTextField.text=[NSString stringWithFormat:@"%@, %@, %@",_city,_state,_zipCode];
    }
    NSRange range = NSMakeRange(0, 1);
    NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationNone];
}

- (NSString*)name:(NSString*)name forComponentType:(NSString*)type fromComponents:(NSArray*)components {
    for(NSDictionary *c in components) {
        if([c[@"types"] indexOfObject:type]!=NSNotFound) {
            return c[name];
        }
    }
    return nil;
}

- (void)addressFromGoogleResults:(NSArray*)results {
    NSArray *a=[results grepWith:^BOOL (NSObject *o) {
        NSDictionary *d=(NSDictionary*)o;
        NSArray *types=d[@"types"];
        return ([types indexOfObject:@"street_address"]!=NSNotFound);
    }];
    if([a count]) {
        NSArray *components=a[0][@"address_components"];
        self.streetName=[self name:@"long_name" forComponentType:@"route" fromComponents:components];
        self.streetNumber=[self name:@"long_name" forComponentType:@"street_number" fromComponents:components];
        NSArray *range=[_streetNumber componentsSeparatedByString:@"-"];
        if([range count]) {
            self.streetNumber=range[0];
        }
        self.city=[self name:@"long_name" forComponentType:@"locality" fromComponents:components];
        self.state=[self name:@"short_name" forComponentType:@"administrative_area_level_1" fromComponents:components];
        self.googleLocation=a[0][@"geometry"][@"location"];
    }
    
    a=[results grepWith:^BOOL (NSObject *o) {
        NSDictionary *d=(NSDictionary*)o;
        NSArray *types=d[@"types"];
        return ([types indexOfObject:@"postal_code"]!=NSNotFound);
    }];
    
    if([a count]) {
        NSArray *components=a[0][@"address_components"];
        self.zipCode=[self name:@"long_name" forComponentType:@"postal_code" fromComponents:components];
    }
    /*NSArray *f=[[Pins sharedInstance].pins grepWith:^BOOL(NSObject *o) {
        PinTemp *p=(PinTemp*)o;
        return [p.location.streetName isEqualToString:_streetName]&&[p.location.streetNumber isEqualToString:_streetNumber];
    }];
    if([f count]) {
        self.pin=f[0];
        [self adjustForViewing];
    }else{
        [self adjustForAdding];
    }*/
    [self updateAddressTextFields];
}

- (void)addressForCoordinate:(CLLocationCoordinate2D)coordinate {
    NSDictionary *params=@{@"sensor":@"true",
                           @"latlng":[NSString stringWithFormat:@"%.6f,%.6f",coordinate.latitude,coordinate.longitude]};
    [[ICRequestManager sharedManager] GET:@"https://maps.googleapis.com/maps/api/geocode/json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *d=(NSDictionary*)responseObject;
        if([d[@"status"] isEqualToString:@"OK"]) {
            [self addressFromGoogleResults:d[@"results"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"geocode error");
    }];
}
static NSDateFormatter *dateFormatter;
- (void)addPin {
    
    if(!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    }
    NSDictionary *location=@{@"Address":[NSString stringWithFormat:@"%@\n%@",_streetNumberTextField.text,_streetNameTextField.text],
                             @"City":_city,
                             @"State":_state,
                             @"Zip":_zipCode};
    NSDictionary *data=@{@"Id":[[NSUUID UUID] UUIDString],
                         @"Location":location,
                         @"Status":_status,
                         @"ClientData":@{},
                         @"Latitude":[NSString stringWithFormat:@"%.6f",_coordinate.latitude],
                         @"Longitude":[NSString stringWithFormat:@"%.6f",_coordinate.longitude],
                         @"UserName":[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey],
                         @"UserCurrentLatitude":[NSString stringWithFormat:@"%.6f",_coordinate.latitude],
                         @"UserCurrentLongitude":[NSString stringWithFormat:@"%.6f",_coordinate.longitude],
                         @"DateTimeInputted":[dateFormatter stringFromDate:[NSDate date]]};
    [[Pins sharedInstance] addPinWithDictionary:data block:^(BOOL success) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
}

- (void)editPin {
    if(!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    }
    NSDictionary *location=@{@"Address":[NSString stringWithFormat:@"%@\n%@",_streetNumberTextField.text,_streetNameTextField.text],
                             @"City":_city,
                             @"State":_state,
                             @"Zip":_zipCode};
    NSDictionary *d=@{@"DefinitionId":@"1",@"StringValue":@"1"};
    NSArray *customFields=@[d];
    NSDictionary *data=@{@"Id":_pin.ident,
                         @"Location":location,
                         @"Status":_status,
                         @"ClientData":@{},
                         @"Latitude":[NSString stringWithFormat:@"%.6f",[_pin.latitude doubleValue]],
                         @"Longitude":[NSString stringWithFormat:@"%.6f",[_pin.longitude doubleValue]],
                         @"UserName":[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey],
                         @"UserCurrentLatitude":[NSString stringWithFormat:@"%.6f",_coordinate.latitude],
                         @"UserCurrentLongitude":[NSString stringWithFormat:@"%.6f",_coordinate.longitude],
                         @"DateTimeInputted":[dateFormatter stringFromDate:[NSDate date]],
                         @"CustomValues":customFields};
    [[Pins sharedInstance] editPin:_pin withDictionary:data block:^(BOOL success) {
        [self adjustForViewing];
    }];
}



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section==0) {
        return 3;
    } else {
        return self.isEditing?[_customFields count]:0;
    }
    
    /*
    if(tableView.isEditing && section==1)
        return [_customFields count];
    
    return [_fields count];*/
}

- (UITableViewCell *)tableView:(UITableView *)tableView firstSectionForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier;
    if(indexPath.row==0) {
        CellIdentifier=@"DetailsStatusCell";
        DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UIButton *button=(UIButton*)[cell viewWithTag:1];
        if(self.isEditing){
            [button removeTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
        }
        if(_status){
            [button setTitle:_status forState:UIControlStateNormal];
            [button setTitleColor:[[Pins sharedInstance] colorForStatus:_status] forState:UIControlStateNormal];
        }
        return cell;
    } else if(indexPath.row==1) {
        CellIdentifier=@"DetailsStreetNumberCell";
        DetailsStreetNumberCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.field.text=_streetNumber;
        cell.stepper.value=[_streetNumber doubleValue];
        cell.field.delegate=self;
        self.streetNumberTextField=cell.field;
        return cell;
    } else {
        CellIdentifier=@"DetailsTextCell";
        DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.field.text=_streetName;
        self.streetNameTextField=cell.field;
        return cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0) {
        return [self tableView:tableView firstSectionForRowAtIndexPath:indexPath];
    }
    static NSString *CellIdentifier = @"DetailsTextCell";
    DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.field.delegate=self;
    //UITextField *field=(UITextField*)[cell viewWithTag:1];
    Field *f=_customFields[indexPath.row];
    cell.field.placeholder=f.name;
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    cell.field.text=_addedFields[key];
    cell.enabled=!!_addedFields[key];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    DetailsTableViewCell *cell = (DetailsTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    if(editingStyle==UITableViewCellEditingStyleInsert) {
        _addedFields[key]=cell.field.text;
///        f.clientData=cell.field.text;
        cell.enabled=YES;
    } else {
//        f.clientData=nil;
        [_addedFields removeObjectForKey:key];
        cell.enabled=NO;
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section==1;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0) {
        return UITableViewCellEditingStyleNone;
    }
    
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    return _addedFields[key]?UITableViewCellEditingStyleDelete:UITableViewCellEditingStyleInsert;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    DetailsTableViewCell *cell=(DetailsTableViewCell*)(textField.superview.superview.superview);
    NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
    
    if(indexPath.section==0) {
        if(indexPath.row==0) {
            self.streetNumber=textField.text;
        }else{
            self.streetName=textField.text;
        }
        [textField endEditing:YES];
        return YES;
    }
    
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    _addedFields[key]=cell.field.text;
    //f.clientData=cell.field.text;
    [textField endEditing:YES];
    return YES;
}

#pragma mark - API

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [_tableView setEditing:editing animated:animated];
    [_tableView reloadData];
    if(!editing) {
        [self editPin];
    }
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinate=coordinate;
    _streetName=_streetNumber=_city=_state=_zipCode=@"";
    [self addressForCoordinate:_coordinate];
}

- (void)setAdding:(BOOL)adding {
    _adding=adding;
}

- (void)setStatus:(NSString *)status {
    _status=status;
    NSRange range = NSMakeRange(0, 1);
    NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex==actionSheet.cancelButtonIndex) return;
    self.status=_statuses[buttonIndex];
    self.navigationItem.rightBarButtonItem.enabled=YES;
}

#pragma mark - Notifications

- (void)fieldsChanged:(NSNotification*)notification {
    [self updateFields];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _tableView.contentInset = contentInsets;
    _tableView.scrollIndicatorInsets = contentInsets;
    /*
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, _activeField.frame.origin) ) {
        [self.tableView scrollRectToVisible:_activeField.frame animated:YES];
    }*/
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _tableView.contentInset = contentInsets;
    _tableView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self addPin];
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)status:(id)sender {
    [[Pins sharedInstance] sendStatusesTo:^(NSArray *a) {
        self.statuses=a;
        UIActionSheet *as=[[UIActionSheet alloc] initWithTitle:@"Status"
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:nil];
        for(NSString *s in a){
            [as addButtonWithTitle:s];
        }
        [as addButtonWithTitle:@"Cancel"];
        as.cancelButtonIndex=[a count];
        [as showInView:self.view];
    }];
}

@end
