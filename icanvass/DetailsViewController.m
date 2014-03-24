//
//  DetailsViewController.m
//  icanvass
//
//  Created by Roman Kot on 12.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "DetailsViewController.h"
#import "ICRequestManager.h"
#import "Pins.h"
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
@end

@implementation DetailsViewController

#pragma mark - View Controller

- (id)initWithCoder:(NSCoder *)aDecoder {
    self=[super initWithCoder:aDecoder];
    if(self) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(_adding) {
        self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        self.navigationItem.rightBarButtonItem.enabled=NO;
    } else {
        self.navigationItem.rightBarButtonItem=[self editButtonItem];
    }
    [self updateAddressTextFields];
}

#pragma mark - Helpers

- (void)updateAddressTextFields {
    _streetNameTextField.text=_streetName;
    _streetNumberTextField.text=_streetNumber;
    if(![_city isEqualToString:@""]) {
        _cityStateZipTextField.text=[NSString stringWithFormat:@"%@, %@, %@",_city,_state,_zipCode];
    }
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

- (void)addPin {
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    }
    NSDictionary *location=@{@"Address":[NSString stringWithFormat:@"%@\n%@",_streetNumber,_streetName],
                             @"City":_city,
                             @"State":_state,
                             @"Zip":_zipCode};
    NSDictionary *data=@{@"Id":[[NSUUID UUID] UUIDString],
                         @"Location":location,
                         @"Status":_status,
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

#pragma mark - API

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    _streetNameTextField.enabled=_streetNumberTextField.enabled=
    _cityStateZipTextField.enabled=_statusButton.enabled=editing;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinate=coordinate;
    _streetName=_streetNumber=_city=_state=_zipCode=@"";
    [self addressForCoordinate:_coordinate];
}

- (void)setAdding:(BOOL)adding {
    _adding=adding;
    //[self setEditing:adding animated:NO];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex==actionSheet.cancelButtonIndex) return;
    self.status=_statuses[buttonIndex];
    [_statusButton setTitle:_status forState:UIControlStateNormal];
    [_statusButton setTitleColor:[[Pins sharedInstance] colorForStatus:_status] forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem.enabled=YES;
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
