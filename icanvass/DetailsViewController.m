//
//  DetailsViewController.m
//  icanvass
//

#import "DetailsViewController.h"
#import "ICRequestManager.h"
#import "DetailsTableViewCell.h"
#import "DatePickerViewController.h"
#import "DropDownViewController.h"
#import "NoteViewController.h"
#import "HomeViewController.h"
#import "Pins.h"
#import "Fields.h"
#import "utilities.h"
#import "Mixpanel.h"
#import "MapController.h"
#import <EventKit/EventKit.h>
#import "SVProgressHUD/SVProgressHUD.h"
#import "TutorialViewController.h"
#import "ErrorHandle.h"
#import "UIDevice-Hardware.h"

#define PHONE_NUMBER @"Phone Number"
#define EMAIL @"Email"

@interface DetailsViewController () <UIActionSheetDelegate,DatePickerDelegate,DropDownDelegate,UITextViewDelegate, UIAlertViewDelegate>
{
    BOOL isCancel;
}
@property (nonatomic,strong) NSString *streetNumber;
@property (nonatomic,strong) NSString *streetName;
@property (nonatomic,strong) NSString *initialStreetNumber;
@property (nonatomic,strong) NSString *initialStreetName;
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
@property (nonatomic,strong) NSString *emailAdress;
@property (nonatomic,strong) NSString *phoneAdress;
@property (nonatomic) BOOL isDeletePinButton;
@property (nonatomic, copy) void (^retryBlock)();
@property (nonatomic, copy) void (^okBlock)();

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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinsChanged:) name:@"ICPinsChanged" object:nil];
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
		//Show Loading Circle
		[SVProgressHUD show];
		[self adjustForAdding];
		
	} else if(_pin){
		[self adjustForViewing];
	}
    [self updateFields];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Helpers

- (void)updateFields {
    
    __weak typeof(self) weakSelf = self;
    [[Fields sharedInstance] sendFieldsTo:^(NSArray *a)
    {
        weakSelf.customFields=a;
        [weakSelf extractPin];
        [_tableView reloadData];
    }];
}

- (void)adjustForAdding {
    UIButton *buttonL = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    [buttonL setImage:[UIImage imageNamed:@"cancel_button"] forState:UIControlStateNormal];
    [buttonL addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonL];
	//self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(done:)];
	self.navigationItem.rightBarButtonItem.enabled=NO;
	[_tableView setEditing:YES];
	[self updateAddressTextFields];
}

- (void)adjustForViewing {
    /*
	UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
	buttonContainer.backgroundColor = [UIColor clearColor];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setFrame:CGRectMake(0, 0, 150, 44)];
	[button setTitleColor:[UIColor colorWithRed:(243.0/255) green:(156.0/255) blue:(18.0/255) alpha:1.0f] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor colorWithRed:(243.0/255) green:(156.0/255) blue:(18.0/255) alpha:0.3f] forState:UIControlStateHighlighted];
	[button setTitle:@"View on Map" forState:UIControlStateNormal];
	button.showsTouchWhenHighlighted = TRUE;
	[button addTarget:self action:@selector(viewOnMap:) forControlEvents:UIControlEventTouchUpInside];
	[buttonContainer addSubview:button];
	self.navigationItem.titleView = buttonContainer;
	self.navigationItem.rightBarButtonItem=[self editButtonItem];*/
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 18, 17)];
    [button setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onBackPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
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
	_cityStateZipTextField.enabled=enable;
	_cityStateZipTextField.borderStyle=enable?UITextBorderStyleRoundedRect:UITextBorderStyleNone;
	_numberStepper.hidden=!enable;
}

- (void)extractPin {
	if(!_pin) return;
	
	if(!self.isAddEmpty) {
		self.streetName=_pin.location.streetName;
		self.initialStreetName=_streetName;
		self.streetNumber=[_pin.location.streetNumber stringValue];
		self.initialStreetNumber=_streetNumber;
	}
	
	self.city=_pin.location.city;
	self.state=_pin.location.state;
	self.zipCode=_pin.location.zip;
	self.unit=_pin.location.unit;
	_coordinate=CLLocationCoordinate2DMake([_pin.latitude doubleValue], [_pin.longitude doubleValue]);
	self.status=_pin.status;
	
	for(NSDictionary *d in _pin.customValuesOld){
		Field *f=[Fields sharedInstance].fieldById[[d[@"DefinitionId"] stringValue]];
		if(!f) continue;
		NSString *v=nilIfNull(d[@"DateTimeValue"]);
		if(v&&f.type==FieldDateTime){
			static NSDateFormatter *zoneFormatter;
			static NSDateFormatter *nozoneFormatter;
			if(!zoneFormatter) {
				zoneFormatter=[[NSDateFormatter alloc] init];
				zoneFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
			}
			if(!nozoneFormatter) {
				nozoneFormatter=[[NSDateFormatter alloc] init];
				nozoneFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
				NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
				[nozoneFormatter setTimeZone:gmt];
			}
			v=[v componentsSeparatedByString:@"."][0];
			NSDate *date=[zoneFormatter dateFromString:v];
			if(!date) {
				date=[nozoneFormatter dateFromString:v];
			}
			_addedFields[d[@"DefinitionId"]]=date;
			continue;
		}
		v=nilIfNull(d[@"StringValue"]);
		if(!v) v=nilIfNull(d[@"IntValue"]);
		if(!v) v=nilIfNull(d[@"DecimalValue"]);
		if(v){
			_addedFields[d[@"DefinitionId"]]=v;
		}
	}
}

- (void)updateAddressTextFields {
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

- (void)addressFromPlacemark:(CLPlacemark*)placemark {
	if(!self.isAddEmpty) {
		self.streetName = placemark.thoroughfare;
		self.initialStreetName = _streetName;
		self.streetNumber =placemark.subThoroughfare;
		
		NSArray *range=[_streetNumber componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"–-"]];
		if([range count]) {
			self.streetNumber=range[0];
		}
		self.initialStreetNumber=_streetNumber;
	}
	self.city=placemark.addressDictionary[@"City"];
	self.state=placemark.addressDictionary[@"State"];
	self.zipCode=placemark.postalCode;
	[self updateAddressTextFields];
	dispatch_async(dispatch_get_main_queue(),^{
		[SVProgressHUD dismiss];
		[[TutorialViewController shared] showSelectStatusTip];
	});
}

- (void)addressForCoordinate2:(CLLocationCoordinate2D)coordinate {
	__weak typeof(self) weakSelf = self;
	CLLocation *loc=[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
	[[CLGeocoder new] reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
		if(error){
			weakSelf.retryBlock = ^{
				[SVProgressHUD show];
				[weakSelf addressForCoordinate2:coordinate];
			};
			[weakSelf handleError:error];
		} else {
			if ([placemarks count]) {
				[weakSelf addressFromPlacemark:[placemarks firstObject]];
			} else {
				[SVProgressHUD dismiss];
				[[TutorialViewController shared] skipTips];
			}
		}
	}];
}

- (void)userAddressWithBlock:(void (^)(NSString*))block {
	if(_coordinate.latitude==_userCoordinate.latitude
	   && _coordinate.longitude==_userCoordinate.longitude){
		block([NSString stringWithFormat:@"%@ %@",_streetNumber,_streetName]);
		return;
	}
	CLLocation *loc=[[CLLocation alloc] initWithLatitude:_userCoordinate.latitude longitude:_userCoordinate.longitude];
	[[CLGeocoder new] reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
		if([placemarks count]){
			CLPlacemark *placemark=[placemarks firstObject];
			NSString *n=placemark.subThoroughfare;
			NSString *s=[NSString stringWithFormat:@"%@ %@",n,placemark.thoroughfare];
			block(s);
		}else{
			block(@"");
		}
	}];
}

- (void)locationForAddressDictionary:(NSDictionary*)address block:(void (^)(CLLocation *l))block {
	if([_streetNumber isEqualToString:_initialStreetNumber]&&[_streetName isEqualToString:_initialStreetName]) {
		block(nil);
		return;
	}
	[[CLGeocoder new] geocodeAddressDictionary:address completionHandler:^(NSArray *placemarks, NSError *error) {
		CLPlacemark *placemark=[placemarks firstObject];
		block(placemark.location);
	}];
}

- (BOOL)addressExists:(NSString*)streetName number:(NSString*)number unit:(NSString*)unit{
	if(!unit) unit=@"";
	NSArray *a=[[Pins sharedInstance].pins grepWith:^BOOL(NSObject *o) {
		Pin *p=(Pin*)o;
		if([p.ident isEqualToString:_pin.ident]) return NO;
		NSString *pu=p.location.unit?p.location.unit:@"";
		return [p.location.streetName isEqualToString:streetName] && [[p.location.streetNumber stringValue] isEqualToString:number]
		&& [unit isEqualToString:pu];
	}];
	return [a count];
}

static NSDateFormatter *dateFormatter;

- (void)addPin {
	if(!_status){
		UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Status" message:@"You can't add a PIN with no status" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];

		[[TutorialViewController shared] skipTips];
		return;
	}
	if(!_streetName || [_streetName length] == 0){
		UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Street name" message:@"You can't add a PIN with no street name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];

		[[TutorialViewController shared] skipTips];
		return;
	}else if(!_streetNumber){
		_streetNumber=@"";
	}
	if(self.isAddEmpty && [_streetNumber length] == 0) {
		UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Street number" message:@"You can't add a PIN with no street number" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];

		[[TutorialViewController shared] skipTips];
		return;
	}
	
	if([self addressExists:_streetName number:_streetNumber unit:_unit]){
		UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Duplicate" message:@"PIN with the same address already exists" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[[TutorialViewController shared] skipTips];
		return;
	}
	if(!dateFormatter) {
		dateFormatter=[[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
	}
	NSMutableDictionary *location=[@{@"Address":[NSString stringWithFormat:@"%@\n%@",_streetNumber,_streetName],
									 @"HouseNumber":_streetNumber?_streetNumber:@"",
									 @"Street":_streetName?_streetName:@"",
									 @"City":_city?_city:@"",
									 @"State":_state?_state:@"",
									 @"Zip":_zipCode?_zipCode:@""} mutableCopy];
	if(_unit&&![_unit isEqualToString:@""]){
		location[@"Unit"]=_unit;
	}
	NSString *titleOfEvent;
	NSDate *dateOfEvent;
	NSString *locationOfEvent;
	NSMutableArray *customValues=[NSMutableArray arrayWithCapacity:[_addedFields count]];
	for(NSNumber *key in [_addedFields allKeys]) {
		Field *f=[Fields sharedInstance].fieldById[[key stringValue]];
		if(f.type==FieldDateTime){
			titleOfEvent=[NSString stringWithFormat:@"%@",_status];;
			locationOfEvent=[NSString stringWithFormat:@"%@ %@, %@, %@, %@",
							 emptyStringIfNil(_streetNumber),emptyStringIfNil(_streetName),emptyStringIfNil(_city),emptyStringIfNil(_state),emptyStringIfNil(_zipCode)];
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
	
	[customValues sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSDictionary *a=(NSDictionary*)obj1;
		NSDictionary *b=(NSDictionary*)obj2;
		
		if([[Fields sharedInstance].fieldById[a[@"DefinitionId"]] order] > [[Fields sharedInstance].fieldById[b[@"DefinitionId"]] order]){
			return NSOrderedDescending;
		}
		return NSOrderedAscending;
	}];
	
	[self locationForAddressDictionary:@{@"City":emptyStringIfNil(_city),@"State":emptyStringIfNil(_state),@"ZIP":emptyStringIfNil(_zipCode),@"Thoroughfare":emptyStringIfNil(_streetName),@"SubThoroughfare":emptyStringIfNil(_streetNumber)} block:^(CLLocation *l) {
		CLLocationDegrees latitude=_coordinate.latitude;
		CLLocationDegrees longitude=_coordinate.longitude;
		if(l){
			latitude=l.coordinate.latitude;
			longitude=l.coordinate.longitude;
		}
		[self userAddressWithBlock:^(NSString *ua) {
			NSDictionary *data=@{//@"Id":@"85b16b78-4e7c-4f14-92ee-07c8a4a189bb",//[[NSUUID UUID] UUIDString],
								 @"Location":location,
								 @"Status":_status,
								 @"ClientData":@{},
								 @"Latitude":[NSString stringWithFormat:@"%.6f",latitude],
								 @"Longitude":[NSString stringWithFormat:@"%.6f",longitude],
								 @"UserName":[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey],
								 @"UserCurrentLatitude":[NSString stringWithFormat:@"%.6f",_userCoordinate.latitude],
								 @"UserCurrentLongitude":[NSString stringWithFormat:@"%.6f",_userCoordinate.longitude],
								 @"UserLocation":ua,
								 @"DateTimeInputted":[dateFormatter stringFromDate:[NSDate date]],
								 @"CustomValues":customValues};
			__weak typeof(self) weakSelf = self;
			[[Pins sharedInstance] addPinWithDictionary:data block:^(NSError *error) {
				if(!error && titleOfEvent){
					EKEventStore *store = [[EKEventStore alloc] init];
					[store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
						if (!granted) { return; }
						EKEvent *event = [EKEvent eventWithEventStore:store];
						event.title = titleOfEvent;
						event.location=locationOfEvent;
						event.startDate = dateOfEvent;
						event.endDate = [event.startDate dateByAddingTimeInterval:60*60];  //set 1 hour meeting
						[event setCalendar:[store defaultCalendarForNewEvents]];
						NSError *err = nil;
						[store saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
					}];


				} else {
					void (^okBlock) () = ^{
						[[Pins sharedInstance] fetchPinsWithBlock:nil];

						NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
												  [NSNumber numberWithFloat: latitude], @"lat",
												  [NSNumber numberWithFloat: longitude], @"lon",
												  nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:@"SetMapPositionAfterAddPin" object:nil userInfo:userInfo];
						NSLog( @"lon:%f lat:%f", longitude, latitude);

						[weakSelf.navigationController popViewControllerAnimated:YES];

						[[TutorialViewController shared] showFinalTip];
						
					};
					if (error) {
						[weakSelf handleError:error];
						weakSelf.retryBlock = ^{
							[weakSelf addPin];
						};
						weakSelf.okBlock = okBlock;
					} else {
						okBlock();
					}
				}
				[weakSelf.navigationController popViewControllerAnimated:YES];

			}];
		}];
	}];
}

- (void)editPin {
	
	if(!_status){
		UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Status" message:@"You can't add a PIN with no status" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	if(!_streetName){
		UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Street name" message:@"You can't add a PIN with no street name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}else if(!_streetNumber){
		_streetNumber=@"";
	}
	
	if([self addressExists:_streetName number:_streetNumber unit:_unit]){
		UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Duplicate" message:@"PIN with the same address already exists" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	if(!dateFormatter) {
		dateFormatter=[[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
	}
	NSMutableDictionary *location=[@{@"Address":[NSString stringWithFormat:@"%@\n%@",_streetNumber,_streetName],
									 @"HouseNumber":_streetNumber?_streetNumber:@"",
									 @"Street":_streetName?_streetName:@"",
									 @"City":_city?_city:@"",
									 @"State":_state?_state:@"",
									 @"Zip":_zipCode?_zipCode:@""} mutableCopy];
	if(_unit&&![_unit isEqualToString:@""]){
		location[@"Unit"]=_unit;
	}
	NSString *titleOfEvent;
	NSDate *dateOfEvent;
	NSString *locationOfEvent;
	NSMutableArray *customValues=[NSMutableArray arrayWithCapacity:[_addedFields count]];
	for(NSNumber *key in [_addedFields allKeys]) {
		Field *f=[Fields sharedInstance].fieldById[[key stringValue]];
		if(f.type==FieldDateTime){
			titleOfEvent=[NSString stringWithFormat:@"%@",_status];;
			locationOfEvent=[NSString stringWithFormat:@"%@ %@, %@, %@, %@",
							 emptyStringIfNil(_streetNumber),emptyStringIfNil(_streetName),emptyStringIfNil(_city),emptyStringIfNil(_state),emptyStringIfNil(_zipCode)];
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
	
	[customValues sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSDictionary *a=(NSDictionary*)obj1;
		NSDictionary *b=(NSDictionary*)obj2;
		
		NSInteger orderA = [[Fields sharedInstance].fieldById[[a[@"DefinitionId"] stringValue]] order];
		NSInteger orderB = [[Fields sharedInstance].fieldById[[b[@"DefinitionId"] stringValue]] order];
		
		if(orderA > orderB){
			return NSOrderedDescending;
		}
		return NSOrderedAscending;
	}];
	__weak typeof(self) weakSelf = self;
	[self locationForAddressDictionary:@{@"City":emptyStringIfNil(_city),@"State":emptyStringIfNil(_state),@"ZIP":emptyStringIfNil(_zipCode),@"Thoroughfare":emptyStringIfNil(_streetName),@"SubThoroughfare":emptyStringIfNil(_streetNumber)} block:^(CLLocation *l) {
		CLLocationDegrees latitude=_coordinate.latitude;
		CLLocationDegrees longitude=_coordinate.longitude;
		if(l){
			latitude=l.coordinate.latitude;
			longitude=l.coordinate.longitude;
		}
        [weakSelf userAddressWithBlock:^(NSString *ua) {
            NSDictionary *data=@{@"Id":_pin.ident,
                                 @"Location":location,
                                 @"Status":_status,
                                 @"ClientData":@{},
                                 @"Latitude":[NSString stringWithFormat:@"%.6f",latitude],
                                 @"Longitude":[NSString stringWithFormat:@"%.6f",longitude],
                                 @"UserName":[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey],
                                 @"UserCurrentLatitude":[NSString stringWithFormat:@"%.6f",_userCoordinate.latitude],
                                 @"UserCurrentLongitude":[NSString stringWithFormat:@"%.6f",_userCoordinate.longitude],
                                 @"UserLocation":ua,
                                 @"UpdateDate":[dateFormatter stringFromDate:[NSDate date]],
                                 @"CustomValues":customValues};
            
            [[Pins sharedInstance] editPin:_pin withDictionary:data block:^(BOOL success) {
                [weakSelf adjustForViewing];
                if(success && titleOfEvent){
                    EKEventStore *store = [[EKEventStore alloc] init];
                    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                        if (!granted) { return; }
                        EKEvent *event = [EKEvent eventWithEventStore:store];
                        event.title = titleOfEvent;
                        event.location=locationOfEvent;
                        event.startDate = dateOfEvent;
                        event.endDate = [event.startDate dateByAddingTimeInterval:60*60];  //set 1 hour meeting
                        [event setCalendar:[store defaultCalendarForNewEvents]];
                        NSError *err = nil;
                        [store saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
                        
                    }];
                }
            }];
        }];
	}];
}

-(IBAction)showMapApp:(CLLocationCoordinate2D) coordinate isWalking:(BOOL)isWalking
{
	
	//create MKMapItem out of coordinates
	MKPlacemark* placeMark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
	MKMapItem* destination =  [[MKMapItem alloc] initWithPlacemark:placeMark];
	if([destination respondsToSelector:@selector(openInMapsWithLaunchOptions:)]) {
		//using iOS6 native maps app
		if(isWalking) {
			[destination openInMapsWithLaunchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeWalking}];
		} else {
			[destination openInMapsWithLaunchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving}];
		}
	} else{
		NSLog( @"iOS < 6.0");
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if(self.isDeletePinButton) {
		return 3;
	} else {
		return 2;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section) {
		case 0: {
			return self.isAddEmpty? 7 : 4;
		}
		case 1: {
			if(tableView.isEditing) {
				return [_customFields count];
			} else {
				return [_pin.customValuesOld count];
			};
		}
		case 2: {
			return 1;
		}
		default:
			return 0;
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
		UILabel *label=(UILabel*)[cell viewWithTag:1];
		if(_status){
            label.text = _status;
            cell.contentView.backgroundColor = [[Pins sharedInstance] colorForStatus:_status];
		}
        
        /*
		if(tableView.isEditing){
			[button removeTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
			[button addTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
			button.layer.cornerRadius = 5;
			button.layer.borderWidth = 1;
			button.layer.borderColor = button.titleLabel.textColor.CGColor;
		}else{
			[button removeTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
			button.layer.borderWidth = 0;
		}*/
		return cell;
	} else if(indexPath.row==1) {
		CellIdentifier=@"DetailsStreetNumberCell";
		DetailsStreetNumberCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
		cell.top.text=@"Number";
		cell.field.placeholder=@"Number";
		cell.bottom.text=_streetNumber;
		[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
		cell.field.text=_streetNumber;
		cell.field.keyboardType=UIKeyboardTypeNumbersAndPunctuation;
		cell.stepper.value=[_streetNumber doubleValue];
		[cell.stepper addTarget:self action:@selector(stepperChanged:) forControlEvents:UIControlEventValueChanged];
		cell.field.delegate=self;
		[cell.directionsButton  addTarget:self action:@selector(clickDirectionButton:) forControlEvents:UIControlEventTouchDown];
		return cell;
	} else if(indexPath.row==2){
		CellIdentifier=@"DetailsTextCell";
		DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
		cell.top.text=@"Street";
		cell.field.placeholder=@"Street";
		cell.field.keyboardType=UIKeyboardTypeDefault;
		cell.bottom.text=_streetName;
		[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
		cell.field.text=_streetName;
		cell.field.delegate=self;
		return cell;
	} else if(self.isAddEmpty) {
		if(indexPath.row==4) {
			CellIdentifier=@"DetailsTextCell";
			DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
			cell.top.text=@"City";
			cell.field.placeholder=@"City";
			cell.field.keyboardType=UIKeyboardTypeDefault;
			cell.bottom.text=_city;
			[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
			cell.field.text=_city;
			cell.field.delegate=self;
			return cell;
		} else if(indexPath.row==5) {
			CellIdentifier=@"DetailsTextCell";
			DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
			cell.top.text=@"State";
			cell.field.placeholder=@"State";
			cell.field.keyboardType=UIKeyboardTypeDefault;
			cell.bottom.text=_state;
			[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
			cell.field.text=_state;
			cell.field.delegate=self;
			return cell;
		} else if(indexPath.row==6) {
			CellIdentifier=@"DetailsTextCell";
			DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
			cell.top.text=@"Zip";
			cell.field.placeholder=@"Zip";
			cell.field.keyboardType=UIKeyboardTypeNumbersAndPunctuation;
			cell.bottom.text=_zipCode;
			[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
			cell.field.text=_zipCode;
			cell.field.delegate=self;
			return cell;
		}
	}
	
	CellIdentifier=@"DetailsTextCell";
	DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	cell.top.text=@"Unit";
	cell.field.placeholder=@"Unit";
	cell.field.keyboardType=UIKeyboardTypeNumbersAndPunctuation;
	cell.bottom.text=_unit;
	[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
	cell.field.text=_unit;
	cell.field.delegate=self;
	return cell;
}

- (IBAction)stepperChanged:(UIStepper*)sender {
	_streetNumber=[NSString stringWithFormat:@"%.0f",sender.value];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section==0) return 44.f;
	
	Field *f;
	if(tableView.isEditing) {
		f=_customFields[indexPath.row];
	} else {
		NSArray *c=_pin.customValuesOld;
		NSDictionary *d=c[indexPath.row];
		f=[Fields sharedInstance].fieldById[[d[@"DefinitionId"] stringValue]];
	}
	if(f.type==FieldNoteBox){
		return 132.f;
	}
	
	return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.section) {
		case 0:	{
			return [self tableView:tableView firstSectionForRowAtIndexPath:indexPath];
		}
		case 1:
			if(!tableView.isEditing){
				NSString *CellIdentifier = @"DetailsDropDownCell";
				DetailsDropDownCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
				cell.enabled=NO;
				NSArray *c=_pin.customValuesOld;
				NSDictionary *d=c[indexPath.row];
				Field *f=[Fields sharedInstance].fieldById[[d[@"DefinitionId"] stringValue]];
				if(f.type==FieldNoteBox) {
					cell.enabled = YES;
				}
				cell.top.text=f.name;
				NSString *v=nilIfNull(d[@"StringValue"]);
				if(!v) v=nilIfNull(d[@"IntValue"]);
				if(!v) v=nilIfNull(d[@"DecimalValue"]);
				if(!v) {
					static NSDateFormatter *dFormatter;
					if(!dFormatter){
						dFormatter=[[NSDateFormatter alloc] init];
						dFormatter.dateFormat=@"MM/dd/yy hh:mm a";
					}
					static NSDateFormatter *zoneFormatter;
					static NSDateFormatter *nozoneFormatter;
					if(!zoneFormatter) {
						zoneFormatter=[[NSDateFormatter alloc] init];
						zoneFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
					}
					if(!nozoneFormatter) {
						nozoneFormatter=[[NSDateFormatter alloc] init];
						nozoneFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
						NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
						[nozoneFormatter setTimeZone:gmt];
					}
					NSString *noMilliseconds=[d[@"DateTimeValue"] componentsSeparatedByString:@"."][0];
					NSDate *date=[zoneFormatter dateFromString:noMilliseconds];
					if(!date) {
						date=[nozoneFormatter dateFromString:noMilliseconds];
					}
					v=[dFormatter stringFromDate:date];
				}
                if([v isKindOfClass:[NSNumber class]]){
                    v=[(NSNumber*)v stringValue];
                }
				cell.bottom.text=v;
				[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
				[cell phoneOrEmail:0];
				BOOL isIPhone = [[UIDevice currentDevice] isIPhone];
				if( isIPhone) {
					if([f.name hasPrefix:PHONE_NUMBER]) {
						[cell phoneOrEmail:1];
						[cell.phoneOrEmailButton addTarget:self action:@selector(clickPhoneButton:) forControlEvents:UIControlEventTouchDown];
						self.phoneAdress = [NSString stringWithFormat: @"%@", v];
					}
				}
				if([f.name isEqualToString:EMAIL]) {
					[cell phoneOrEmail:2];
					[cell.phoneOrEmailButton addTarget:self action:@selector(clickEmailButton:) forControlEvents:UIControlEventTouchDown];
					self.emailAdress = [NSString stringWithFormat: @"%@", v];
					cell.field.keyboardType = UIKeyboardTypeEmailAddress;
				}
				return cell;
			}
			break;
		case 2 : {
			DeletePinCell *cell = [tableView dequeueReusableCellWithIdentifier: @"DeletePinCell"];
			return cell;
		}
	}
	
	Field *f=_customFields[indexPath.row];
	NSNumber *key=@(f.ident);
	
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
		[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
		
		return cell;
	}if(f.type==FieldDropDown){
		NSString *CellIdentifier = @"DetailsDropDownCell";
		DetailsDropDownCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
		//        cell.enabled=!!_addedFields[key];
		cell.enabled=YES;
        cell.phoneOrEmailButton.hidden = YES;
		cell.top.text=f.name;
		cell.bottom.text=_addedFields[key];
		[cell.bottom setFont:[UIFont systemFontOfSize:18.0]];
		
		return cell;
		
	}else if(f.type==FieldNoteBox){
		NSString *CellIdentifier = @"DetailsNotesCell";
		DetailsNotesCell *cell = (DetailsNotesCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
		cell.note.delegate=self;
		cell.note.text=_addedFields[key];
		cell.note.keyboardType=UIKeyboardTypeDefault;
		cell.note.layer.borderWidth = 1.f;
		cell.note.layer.borderColor = [[UIColor lightGrayColor] CGColor];
		cell.note.layer.cornerRadius = 5;
		//UITextField *field=(UITextField*)[cell viewWithTag:1];
		
		//        cell.field.placeholder=f.name;
		//        cell.field.keyboardType=UIKeyboardTypeDefault;
		//        cell.field.text=_addedFields[key];
		//        cell.enabled=!!_addedFields[key];
		cell.enabled=YES;
		return cell;
	}else{
		NSString *CellIdentifier = @"DetailsTextCell";
		DetailsTableViewCell *cell = (DetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
		cell.field.delegate=self;
		//UITextField *field=(UITextField*)[cell viewWithTag:1];
		
		cell.field.placeholder=f.name;
		cell.field.keyboardType=UIKeyboardTypeDefault;
        cell.field.text=_addedFields[key]?[NSString stringWithFormat:@"%@",_addedFields[key]]:@"";
		//        cell.enabled=!!_addedFields[key];
		cell.enabled=YES;
		
		if([f.name hasPrefix:PHONE_NUMBER]) {
			cell.field.keyboardType=UIKeyboardTypePhonePad;
		}
		if([f.name hasPrefix:EMAIL]) {
			[cell.field setAutocorrectionType:UITextAutocorrectionTypeNo];
			[cell.field setKeyboardType:UIKeyboardTypeEmailAddress];
		}
		
		return cell;
	}

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//Field *f=_customFields[indexPath.row];
	//NSString *key=[NSString stringWithFormat:@"%d",f.ident];
	//DetailsTableViewCell *cell = (DetailsTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
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
    BOOL should=cell.editingAccessoryType==UITableViewCellAccessoryDisclosureIndicator;
    return should;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//[tableView deselectRowAtIndexPath:indexPath animated:NO];
	if(!tableView.isEditing){
		[self performSegueWithIdentifier:@"NoteView" sender:nil];
        return;
	}
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

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(tableView.isEditing){
		if([indexPath row] == ([_customFields count] + 4 - 1) && tableView.isEditing){
			//end of loading
			//for example [activityIndicator stopAnimating];
		}
	}
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

- (UITableViewCell *)cellWithSubview:(UIView *)subview {
	
	while (subview && ![subview isKindOfClass:[UITableViewCell self]])
		subview = subview.superview;
	return (UITableViewCell *)subview;
}


//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//	UITableViewCell *cell= [self cellWithSubview:textField];
//	NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
//	if(!indexPath){
//		return YES;
//	}
//	if(indexPath.section==0) {
//		if(indexPath.row==1){
//			_streetNumber=[textField.text stringByReplacingCharactersInRange:range withString:string];
//		}else if(indexPath.row==2){
//			_streetName=[textField.text stringByReplacingCharactersInRange:range withString:string];
//		}
//		if(indexPath.row==3){
//			_unit=[textField.text stringByReplacingCharactersInRange:range withString:string];
//		}
//		if(indexPath.row==4){
//			_city=[textField.text stringByReplacingCharactersInRange:range withString:string];
//		}
//		if(indexPath.row==5){
//			_state=[textField.text stringByReplacingCharactersInRange:range withString:string];
//		}
//		if(indexPath.row==6){
//			_zipCode=[textField.text stringByReplacingCharactersInRange:range withString:string];
//		}
//		return YES;
//	}
//	
//	Field *f=_customFields[indexPath.row];
//	NSNumber *key=@(f.ident);
//	_addedFields[key]=[textField.text stringByReplacingCharactersInRange:range withString:string];
//	return YES;
//}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	UITableViewCell *cell=[self cellWithSubview:textView];
    NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
	if(!indexPath){
		return YES;
	}
	Field *f=_customFields[indexPath.row];
	NSNumber *key=@(f.ident);
	_addedFields[key]=[textView.text stringByReplacingCharactersInRange:range withString:text];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
	UITableViewCell *cell= [self cellWithSubview:textField];
	NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
	if(!indexPath){
		return;
	}
	if(indexPath.section==0) {
		if(indexPath.row==1){
			_streetNumber = textField.text;
		}
		if(indexPath.row==2){
			_streetName = textField.text;
		}
		if(indexPath.row==3){
			_unit= textField.text;
		}
		if(indexPath.row==4){
			_city= textField.text;
		}
		if(indexPath.row==5){
			_state = textField.text;
		}
		if(indexPath.row==6){
			_zipCode= textField.text;
		}
		return;
	}
	
	Field *f=_customFields[indexPath.row];
	NSNumber *key=@(f.ident);
	_addedFields[key] = textField.text;
	return;
	
	[textField resignFirstResponder];
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
	 NSNumber *key=@(f.ident);
	 _addedFields[key]=cell.field.text;
	 //f.clientData=cell.field.text;*/
	self.activeField=nil;
}


//- (void)textFieldDidEndEditing:(UITextField *)textField {
//    [textField resignFirstResponder];
//    self.activeField=nil;
//    
//    if(!textField.text){    //default is nil
//        return;
//    }
//    
//    UITableViewCell *cell= [self cellWithSubview:textField];
//    NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
//    if(!indexPath){
//        return;
//    }
//    
//    if(indexPath.section==0) {
//        if(indexPath.row==1){
//            _streetNumber=textField.text;
//        }else if(indexPath.row==2){
//            _streetName=textField.text;
//        }
//        if(indexPath.row==3){
//            _unit=textField.text;
//        }
//    }else{
//        Field *f=_customFields[indexPath.row];
//        NSNumber *key=@(f.ident);
//        _addedFields[key]=textField.text;
//    }
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField endEditing:YES];
    UITableViewCell *cell= [self cellWithSubview:textField];
    NSIndexPath *indexPath=[_tableView indexPathForCell:cell];
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
    UITableViewCell *nextCell;
    while ((nextCell=[self.tableView cellForRowAtIndexPath: newPath])!=nil) {
        if([nextCell isKindOfClass:[DetailsNotesCell class]]){
            DetailsNotesCell *noteCell=(DetailsNotesCell*)nextCell;
            [self.tableView scrollToRowAtIndexPath:newPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            [noteCell.note becomeFirstResponder];
            return NO;
        }else if([nextCell isKindOfClass:[DetailsTableViewCell class]]){
            DetailsTableViewCell *textCell=(DetailsTableViewCell*)nextCell;
            [textCell.field becomeFirstResponder];
            return NO;
        }
        newPath = [NSIndexPath indexPathForRow:newPath.row+1 inSection:indexPath.section];
    }
	return YES;
}

#pragma mark - DatePickerDelegate

- (void)datePicker:(DatePickerViewController *)picker changedDate:(NSDate *)date {
    NSIndexPath *indexPath=picker.indexPath;
    if(!indexPath) return;
    Field *f=_customFields[indexPath.row];
    NSNumber *key=@(f.ident);
    _addedFields[key]=date;
    [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - DropDownDelegate

- (void)dropDown:(DropDownViewController *)dropDown changedTo:(NSString *)value {
    NSIndexPath *indexPath=dropDown.indexPath;
    if(!indexPath) return;
    Field *f=_customFields[indexPath.row];
    NSNumber *key=@(f.ident);
    _addedFields[key]=value;
    [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - API

- (void)refreshList {
	NSLog(@"%s",__FUNCTION__);
	[[Pins sharedInstance] fetchPinsWithBlock:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	self.isDeletePinButton = editing;
	
	[_activeField resignFirstResponder];
	[super setEditing:editing animated:animated];
	//    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	
	[_tableView setEditing:editing animated:animated];
	[self.navigationItem.titleView setHidden:YES];
	
	[_tableView reloadData];
	
	if(!editing && !isCancel) {
		[self editPin];
	}
	
	if(!self.isDeletePinButton) {
		dispatch_queue_t concurrentQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async( concurrentQueue, ^{
			[NSThread sleepForTimeInterval:1.0];
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatePinFields" object:nil userInfo:nil];
			});
		});
	}
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
	_coordinate=coordinate;
	_streetName=_streetNumber=_city=_state=_zipCode=_initialStreetName=_initialStreetNumber=@"";
	[self addressForCoordinate2:_coordinate];
}

- (void)setAdding:(BOOL)adding {
	_adding=adding;
}

- (void)setStatus:(NSString *)status {
	_status=status;
	//NSRange range = NSMakeRange(0, 1);
	//NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
	//[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView reloadData];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex==actionSheet.cancelButtonIndex) return;
	self.status=_statuses[buttonIndex];
	self.navigationItem.rightBarButtonItem.enabled=YES;
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[[TutorialViewController shared] dismissCurrentTip];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[[TutorialViewController shared] showDoneTip];
	});
}

#pragma mark - Notifications

- (void)fieldsChanged:(NSNotification*)notification {
	[self updateFields];
}

- (void)pinsChanged:(NSNotification*)notification {
	[self extractPin];
	[self.tableView reloadData];
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

- (void)maybeDeletePin:(Pin*)pin {
    BOOL allowed=[[[NSUserDefaults standardUserDefaults] objectForKey:@"deleting"] isEqualToString:@"1"];
    if(!allowed) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Delete"
                              message:@"You do not have permission to delete pins."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    __weak __typeof(self)weakSelf = self;
    [[Pins sharedInstance] deletePin:pin
                               block: ^ (BOOL success) {
                                   if(success) {
                                       [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRefreshDate];
                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                       [[Pins sharedInstance] clear];
                                       [weakSelf refreshList];
                                   }
                               }];
}

#pragma mark - Actions

- (IBAction)clickDeletePinButton:(id)sender {
	NSLog( @"DELETE PIN");
	
    [self maybeDeletePin:_pin];
}


- (IBAction)clickPhoneButton:(id)sender {
	if( self.phoneAdress && self.phoneAdress.length > 0) {
		NSString *number = [NSString stringWithFormat: @"telprompt://%@", self.phoneAdress];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:number]];
		NSLog( @"%@", number);
		return;
	}
}

- (IBAction)clickEmailButton:(id)sender {
	if( self.emailAdress && self.emailAdress.length > 0) {
		NSString *url = [NSString stringWithFormat: @"mailto:%@?cc=&subject=Hello&body=",
						 self.emailAdress];
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
		NSLog( @"%@", url);
		return;
	}
}


- (IBAction)clickDirectionButton:(id)sender {
	[self showMapApp: self.coordinate isWalking:NO];
}

- (IBAction)onBackPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)done:(id)sender {
	[[TutorialViewController shared] dismissCurrentTip];
	[self textFieldDidEndEditing:_activeField];
	[self addPin];
}

- (IBAction)cancel:(id)sender {
	[_activeField endEditing:YES];
	if(_adding){
        [SVProgressHUD dismiss];
		[self.navigationController popViewControllerAnimated:YES];
	}else{
		[self setEditing:NO animated:YES];
	}
}

- (IBAction)status:(id)sender {
	[[TutorialViewController shared] dismissCurrentTip];
	[self textFieldDidEndEditing:_activeField];
	[[TutorialViewController shared] showActionSheetTip];

	__weak typeof(self) weakSelf = self;
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

	} failure:^(NSError *error) {
		__weak id weakSender = sender;
		weakSelf.retryBlock = ^{
			[SVProgressHUD show];
			[weakSelf status:weakSender];
		};
		[weakSelf handleError:error];
	}];
}


- (IBAction)viewOnMap:(id)sender {
    
    HomeViewController *homeViewController = [self.navigationController.viewControllers objectAtIndex:0];
    [homeViewController setCategory:0];
    [homeViewController switchToViewController:homeViewController.controllers[0] animated:NO];  //animation here conflicts with popping to root animation
    
    CLLocation *loc=[[CLLocation alloc] initWithLatitude:_coordinate.latitude longitude:_coordinate.longitude];
    homeViewController.map.moved = NO;
    homeViewController.map.location = loc;
    homeViewController.map.moved = YES;
    [homeViewController.map viewOnMap:self.pin];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)edit:(id)sender {
    
    UIButton *buttonL = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    [buttonL setImage:[UIImage imageNamed:@"cancel_button"] forState:UIControlStateNormal];
    [buttonL addTarget:self action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonL];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(editClicked)];
    
    self.btnEdit.hidden = YES;
    [self setEditing:YES animated:YES];
}

- (void)editClicked
{
    isCancel = NO;
    self.btnEdit.hidden = NO;
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 18, 17)];
    [button setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onBackPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = nil;
    [self setEditing:NO animated:YES];
}

- (void)cancelClicked
{
    isCancel = YES;
    self.btnEdit.hidden = NO;
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 18, 17)];
    [button setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onBackPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = nil;
    [self setEditing:NO animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSIndexPath *indexPath=[_tableView indexPathForSelectedRow];
    Field *f=_customFields[indexPath.row];
    NSNumber *key=@(f.ident);
    if([segue.identifier isEqualToString:@"DatePicker"]) {
        DatePickerViewController *d=segue.destinationViewController;
        d.indexPath=indexPath;
        d.delegate=self;
        d.name=f.name;
        d.date=[_addedFields[key] isKindOfClass:[NSDate class]]?_addedFields[key]:[NSDate date];
    } else if([segue.identifier isEqualToString:@"DropDown"]) {
        DropDownViewController *drop=segue.destinationViewController;
        drop.indexPath=indexPath;
        drop.delegate=self;
        drop.options=f.settings;
    } else if([segue.identifier isEqualToString:@"NoteView"]) {
        NoteViewController *noteView=segue.destinationViewController;
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        DetailsDropDownCell *cell=(DetailsDropDownCell *)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
        noteView.note = cell.bottom.text;
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 1:
			if (self.retryBlock) {
				self.retryBlock();
				self.retryBlock = nil;
				[[TutorialViewController shared] showFromPrevious];
			}
			break;
		default:
			[[TutorialViewController shared] skipTips];
			if (self.okBlock) {
				self.okBlock();
				self.okBlock = nil;
			}
			break;
	}
}


- (void)handleError:(NSError*)error {
	if ([ErrorHandle isInternetConnectionError:error]) {
		[[[UIAlertView alloc] initWithTitle:@"Error!"
									message:@"No internet connection"
								   delegate:self
						  cancelButtonTitle:nil
						  otherButtonTitles:@"OK",@"RETRY", nil] show];
		[[TutorialViewController shared] hide];

		[SVProgressHUD dismiss];
	} else {
		[SVProgressHUD showErrorWithStatus:error.localizedDescription];
		[[TutorialViewController shared] skipTips];
	}
}

@end
