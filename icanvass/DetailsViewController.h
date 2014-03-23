//
//  DetailsViewController.h
//  icanvass
//
//  Created by Roman Kot on 12.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface DetailsViewController : UIViewController

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL adding;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UITextField *streetNumberTextField;
@property (weak, nonatomic) IBOutlet UIStepper *numberStepper;
@property (weak, nonatomic) IBOutlet UITextField *streetNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityStateZipTextField;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)status:(id)sender;

@end
