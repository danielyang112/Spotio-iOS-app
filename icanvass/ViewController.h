//
//  ViewController.h
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (nonatomic,weak) IBOutlet UISegmentedControl *segment;
- (IBAction)valueChanged:(id)sender;
@end
