//
//  DetailsViewController.h
//  icanvass
//
//  Created by Roman Kot on 12.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PinTemp.h"

@interface DetailsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL adding;
@property (nonatomic,strong) PinTemp *pin;
@property (weak, nonatomic) IBOutlet UIStepper *numberStepper;
@property (weak, nonatomic) IBOutlet UITextField *cityStateZipTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)status:(id)sender;

@end
