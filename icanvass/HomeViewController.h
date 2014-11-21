//
//  HomeController.h
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>
#import "MMDrawerController/UIViewController+MMDrawerController.h"

@class  MapController;

@interface HomeViewController : UIViewController <CLLocationManagerDelegate>
@property (nonatomic,weak) IBOutlet UISegmentedControl *segment;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (nonatomic,strong) MapController *map;
@property (nonatomic,strong) NSArray *controllers;

- (IBAction)filter:(id)sender;
- (IBAction)valueChanged:(id)sender;
- (IBAction)shareClicked:(id)sender;
- (void)switchToViewController:(UIViewController*)vc animated:(BOOL)animated;
@end
