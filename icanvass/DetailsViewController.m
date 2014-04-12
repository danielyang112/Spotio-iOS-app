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
#import "DatePickerViewController.h"
#import "DropDownViewController.h"
#import "Pins.h"
#import "Fields.h"
#import "utilities.h"
#import "Mixpanel.h"
#import <EventKit/EventKit.h>

@interface DetailsViewController () <UIActionSheetDelegate,DatePickerDelegate,DropDownDelegate>
@property (nonatomic,strong) NSString *streetNumber;
@property (nonatomic,strong) NSString *streetName;
@property (nonatomic,strong) NSString *unit;
@property (nonatomic,strong) NSString *zipCode;
@property (nonatomic,strong) NSString *city;
@property (nonatomic,strong) NSString *state;
@property (nonatomic,strong) NSDictionary *googleLocation;
@property (nonatomic,strong) NSString *status;
@property (nonatomic,strong) NSArray *statuses;

@property (nonatomic,strong) NSMutableArray *fields;
@property (nonatomic,strong) NSArray *customFields;
@property (nonatomic,strong) NSMutableDictionary *addedFields;


@property (nonatomic,weak) UITextField *activeField;

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
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    self.tableView.backgroundColor=[UIColor clearColor];
    if(_adding) {
        [self adjustForAdding];
    } else if(_pin){
        [self adjustForViewing];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[Mixpanel sharedInstance] track:@"DetailsView"];
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
    self.unit=_pin.location.unit;
    
    self.status=_pin.status;
    
    for(NSDictionary *d in _pin.customValues){
        Field *f=[Fields sharedInstance].fieldById[[d[@"DefinitionId"] stringValue]];
        NSString *v=nilIfNull(d[@"StringValue"]);
        if(!v) v=nilIfNull(d[@"IntValue"]);
        if(!v) v=nilIfNull(d[@"DecimalValue"]);
        if(!v) {
            static NSDateFormatter *dFormatter;
            static NSDateFormatter *ddFormatter;
            if(!dFormatter){
                dFormatter=[[NSDateFormatter alloc] init];
                dFormatter.dateFormat=@"MM/dd/yy hh:mm a";
            }
            if(!ddFormatter) {
                ddFormatter=[[NSDateFormatter alloc] init];
                ddFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            }
            NSDate *date=[ddFormatter dateFromString:d[@"DateTimeValue"]];
            v=[dFormatter stringFromDate:date];
        }
        _addedFields[[d[@"DefinitionId"] stringValue]]=v;
    }
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

- (BOOL)addressExists:(NSString*)streetName number:(NSString*)number {
    NSArray *a=[[Pins sharedInstance].pins grepWith:^BOOL(NSObject *o) {
        PinTemp *p=(PinTemp*)o;
        if([p.ident isEqualToString:_pin.ident]) return NO;
        return [p.location.streetName isEqualToString:streetName] && [p.location.streetNumber isEqualToString:number];
    }];
    return [a count];
}

static NSDateFormatter *dateFormatter;
- (void)addPin {
    if([self addressExists:_streetNameTextField.text number:_streetNumberTextField.text]){
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Duplicate" message:@"PIN with the same address already exists" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if(!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    }
    NSMutableDictionary *location=[@{@"Address":[NSString stringWithFormat:@"%@\n%@",_streetNumberTextField.text,_streetNameTextField.text],
                             @"City":_city,
                             @"State":_state,
                             @"Zip":_zipCode} mutableCopy];
    if(![_unitTextField.text isEqualToString:@""]){
        location[@"Unit"]=_unitTextField.text;
    }
    //NSArray *customFields=@[@{@"DefinitionId":@"1",@"StringValue":@"Abcdefgh"},
                            //@{@"DefinitionId":@"6",@"StringValue":@"note note note note"}];
    NSString *titleOfEvent;
    NSDate *dateOfEvent;
    NSMutableArray *customValues=[NSMutableArray arrayWithCapacity:[_addedFields count]];
    for(NSString *key in [_addedFields allKeys]) {
        Field *f=[Fields sharedInstance].fieldById[key];
        if(f.type==FieldDateTime){
            titleOfEvent=f.name;
            dateOfEvent=_addedFields[key];
            [customValues addObject:@{@"DefinitionId":key,@"DateTimeValue":[dateFormatter stringFromDate:_addedFields[key]]}];
        }else if(f.type==FieldNumber){
            [customValues addObject:@{@"DefinitionId":key,@"IntValue":_addedFields[key]}];
        }else if(f.type==FieldMoney){
            [customValues addObject:@{@"DefinitionId":key,@"DecimalValue":_addedFields[key]}];
        }else{
            [customValues addObject:@{@"DefinitionId":key,@"StringValue":_addedFields[key]}];
        }
    }
    NSDictionary *data=@{//@"Id":@"85b16b78-4e7c-4f14-92ee-07c8a4a189bb",//[[NSUUID UUID] UUIDString],
                         @"Location":location,
                         @"Status":_status,
                         @"ClientData":@{},
                         @"Latitude":[NSString stringWithFormat:@"%.6f",_coordinate.latitude],
                         @"Longitude":[NSString stringWithFormat:@"%.6f",_coordinate.longitude],
                         @"UserName":[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey],
                         @"UserCurrentLatitude":[NSString stringWithFormat:@"%.6f",_coordinate.latitude],
                         @"UserCurrentLongitude":[NSString stringWithFormat:@"%.6f",_coordinate.longitude],
                         @"DateTimeInputted":[dateFormatter stringFromDate:[NSDate date]],
                         @"CustomValues":customValues};
    [[Pins sharedInstance] addPinWithDictionary:data block:^(BOOL success) {
        if(success && titleOfEvent){
            EKEventStore *store = [[EKEventStore alloc] init];
            [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                if (!granted) { return; }
                EKEvent *event = [EKEvent eventWithEventStore:store];
                event.title = titleOfEvent;
                event.startDate = dateOfEvent;
                event.endDate = [event.startDate dateByAddingTimeInterval:60*60];  //set 1 hour meeting
                [event setCalendar:[store defaultCalendarForNewEvents]];
                NSError *err = nil;
                [store saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
            }];
        }
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
}

- (void)editPin {
    if([self addressExists:_streetNameTextField.text number:_streetNumberTextField.text]){
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Duplicate" message:@"PIN with the same address already exists" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if(!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    }
    NSDictionary *location=@{@"Address":[NSString stringWithFormat:@"%@\n%@",_streetNumberTextField.text,_streetNameTextField.text],
                             @"City":_city,
                             @"State":_state,
                             @"Zip":_zipCode};
    //NSDictionary *d=@{@"DefinitionId":@"1",@"StringValue":@"Abc"};
    NSArray *customFields=@[];
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
        return 4;
    } else {
        return tableView.isEditing?[_customFields count]:[_pin.customValues count];
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
        if(_status){
            [button setTitle:_status forState:UIControlStateNormal];
            [button setTitleColor:[[Pins sharedInstance] colorForStatus:_status] forState:UIControlStateNormal];
        }
        if(tableView.isEditing){
            [button removeTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
            button.layer.cornerRadius = 5;
            button.layer.borderWidth = 1;
            button.layer.borderColor = button.titleLabel.textColor.CGColor;
        }
        return cell;
    } else if(indexPath.row==1) {
        CellIdentifier=@"DetailsStreetNumberCell";
        DetailsStreetNumberCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.top.text=@"Number";
        cell.field.placeholder=@"Number";
        cell.bottom.text=_streetNumber;
        cell.field.text=_streetNumber;
        cell.stepper.value=[_streetNumber doubleValue];
        cell.field.delegate=self;
        self.streetNumberTextField=cell.field;
        return cell;
    } else if(indexPath.row==2){
        CellIdentifier=@"DetailsTextCell";
        DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.top.text=@"Street";
        cell.field.placeholder=@"Street";
        cell.bottom.text=_streetName;
        cell.field.text=_streetName;
        cell.field.delegate=self;
        self.streetNameTextField=cell.field;
        return cell;
    }else{
        CellIdentifier=@"DetailsTextCell";
        DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.top.text=@"Unit";
        cell.field.placeholder=@"Unit";
        cell.bottom.text=_unit;
        cell.field.text=_unit;
        cell.field.delegate=self;
        self.unitTextField=cell.field;
        return cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section==0) {
        return [self tableView:tableView firstSectionForRowAtIndexPath:indexPath];
    }else if(!tableView.isEditing){
        NSString *CellIdentifier = @"DetailsDropDownCell";
        DetailsDropDownCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.enabled=NO;
        NSArray *c=_pin.customValues;
        NSDictionary *d=c[indexPath.row];
        Field *f=[Fields sharedInstance].fieldById[[d[@"DefinitionId"] stringValue]];
        cell.top.text=f.name;
        NSString *v=nilIfNull(d[@"StringValue"]);
        if(!v) v=nilIfNull(d[@"IntValue"]);
        if(!v) v=nilIfNull(d[@"DecimalValue"]);
        if(!v) {
            static NSDateFormatter *dFormatter;
            static NSDateFormatter *ddFormatter;
            if(!dFormatter){
                dFormatter=[[NSDateFormatter alloc] init];
                dFormatter.dateFormat=@"MM/dd/yy hh:mm a";
            }
            if(!ddFormatter) {
                ddFormatter=[[NSDateFormatter alloc] init];
                ddFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            }
            NSDate *date=[ddFormatter dateFromString:d[@"DateTimeValue"]];
            v=[dFormatter stringFromDate:date];
        }
        cell.bottom.text=v;
        return cell;
    }
    
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    
    if(f.type==FieldDateTime){
        NSString *CellIdentifier = @"DetailsDateCell";
        DetailsDateCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        //cell.enabled=!!_addedFields[key];
        cell.enabled=YES;
        cell.top.text=f.name;
        static NSDateFormatter *dFormatter;
        if(!dFormatter){
            dFormatter=[[NSDateFormatter alloc] init];
            dFormatter.dateFormat=@"MM/dd/yy hh:mm a";
        }
        cell.bottom.text=[dFormatter stringFromDate:_addedFields[key]];
        
        return cell;
    }if(f.type==FieldDropDown){
        NSString *CellIdentifier = @"DetailsDropDownCell";
        DetailsDropDownCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//        cell.enabled=!!_addedFields[key];
        cell.enabled=YES;
        
        cell.top.text=f.name;
        cell.bottom.text=_addedFields[key];
        
        return cell;
    }else{
        NSString *CellIdentifier = @"DetailsTextCell";
        DetailsTableViewCell *cell = (DetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.field.delegate=self;
        //UITextField *field=(UITextField*)[cell viewWithTag:1];
        
        cell.field.placeholder=f.name;
        cell.field.text=_addedFields[key];
//        cell.enabled=!!_addedFields[key];
        cell.enabled=YES;
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    DetailsTableViewCell *cell = (DetailsTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    if(editingStyle==UITableViewCellEditingStyleInsert) {
//        _addedFields[key]=@"";
//        cell.enabled=YES;
    } else {
//        [_addedFields removeObjectForKey:key];
//        cell.enabled=NO;
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    [_activeField endEditing:YES];
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    return cell.editingAccessoryType==UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //[tableView deselectRowAtIndexPath:indexPath animated:NO];
    Field *f=_customFields[indexPath.row];
    [_activeField endEditing:YES];
    if(f.type==FieldDateTime){
        [self performSegueWithIdentifier:@"DatePicker" sender:nil];
    }else if(f.type==FieldDropDown){
        [self performSegueWithIdentifier:@"DropDown" sender:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
//    return indexPath.section==1;
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if(indexPath.section==0) {
        return UITableViewCellEditingStyleNone;
//    }
    
//    Field *f=_customFields[indexPath.row];
//    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
//    return _addedFields[key]?UITableViewCellEditingStyleDelete:UITableViewCellEditingStyleInsert;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
//    UITableViewCell *cell=(UITableViewCell*)(textField.superview.superview.superview);
//    NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
    
//    if(indexPath.section==0) {
        return YES;
//    }
//    return cell.editingStyle==UITableViewCellEditingStyleDelete;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeField=textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    DetailsTableViewCell *cell=(DetailsTableViewCell*)(textField.superview.superview.superview);
    NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
    if(!indexPath){
        return YES;
    }
    if(indexPath.section==0) {
        if(textField==_unitTextField){
            _unit=[textField.text stringByReplacingCharactersInRange:range withString:string];
        }
        return YES;
    }
    
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    _addedFields[key]=[textField.text stringByReplacingCharactersInRange:range withString:string];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    /*DetailsTableViewCell *cell=(DetailsTableViewCell*)(textField.superview.superview.superview);
    NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
    if(!indexPath || indexPath.section==0){
        return;
    }
    if(indexPath.section==0) {
        if(indexPath.row==0) {
            self.streetNumber=textField.text;
        }else{
            self.streetName=textField.text;
        }
        [textField endEditing:YES];
        return;
    }
    
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    _addedFields[key]=cell.field.text;
    //f.clientData=cell.field.text;*/
    self.activeField=nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:YES];
    return YES;
}

#pragma mark - DatePickerDelegate

- (void)datePicker:(DatePickerViewController *)picker changedDate:(NSDate *)date {
    NSIndexPath *indexPath=[_tableView indexPathForSelectedRow];
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    _addedFields[key]=date;
}

#pragma mark - DropDownDelegate

- (void)dropDown:(DropDownViewController *)dropDown changedTo:(NSString *)value {
    NSIndexPath *indexPath=[_tableView indexPathForSelectedRow];
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    _addedFields[key]=value;
}

#pragma mark - API

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
//    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
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
    //NSRange range = NSMakeRange(0, 1);
    //NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    [self textFieldDidEndEditing:_activeField];
    [self addPin];
}

- (IBAction)cancel:(id)sender {
    [_activeField endEditing:YES];
    if(_adding){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }else{
        [self setEditing:NO animated:YES];
    }
}

- (IBAction)status:(id)sender {
    [self textFieldDidEndEditing:_activeField];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath=[_tableView indexPathForSelectedRow];
    Field *f=_customFields[indexPath.row];
    NSString *key=[NSString stringWithFormat:@"%d",f.ident];
    if([segue.identifier isEqualToString:@"DatePicker"]) {
        DatePickerViewController *d=segue.destinationViewController;
        d.delegate=self;
        d.name=f.name;
        d.date=[_addedFields[key] isKindOfClass:[NSDate class]]?_addedFields[key]:[NSDate date];
    } else if([segue.identifier isEqualToString:@"DropDown"]) {
        DropDownViewController *drop=segue.destinationViewController;
        drop.delegate=self;
        drop.options=f.settings;
    }
}

@end
