//
//  DetailsViewController.h
//  icanvass
//
//  Created by Roman Kot on 12.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsViewController : UIViewController

@property (nonatomic) BOOL preview;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end
