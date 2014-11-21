//
//  GoToWebsiteViewController.h
//  icanvass
//
//  Created by Roman Kot on 24.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GoToWebsiteViewController : UIViewController
@property (nonatomic,strong) NSString *text;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

- (IBAction)gotoWebsite:(id)sender;
@end
