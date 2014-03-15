//
//  LoginViewController.h
//  icanvass
//
//  Created by Roman Kot on 14.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *loginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@end
