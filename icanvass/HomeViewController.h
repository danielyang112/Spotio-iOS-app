//
//  HomeController.h
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#define kCategory @"Category"

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>
#import "MMDrawerController/UIViewController+MMDrawerController.h"

@class  MapController;

@interface HomeViewController : UIViewController <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnCategory;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (nonatomic,strong) MapController *map;
@property (nonatomic,strong) NSArray *controllers;
@property (nonatomic,assign) int category;
@property (nonatomic,strong) UIButton *btnTitle;

- (IBAction)categoryChanged:(id)sender;
- (IBAction)shareClicked:(id)sender;
- (void)switchToViewController:(UIViewController*)vc animated:(BOOL)animated;

@end
