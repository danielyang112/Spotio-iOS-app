//
//  LoginViewController.m
//  icanvass
//
//  Created by Roman Kot on 14.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "LoginViewController.h"
#import "ICRequestManager.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

#pragma mark - View Controller

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

#pragma mark - Helpers

- (void)close {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (void)showWrongPassword {
    
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password company:(NSString*)company {
    [[ICRequestManager sharedManager] loginUserName:username password:password company:company cb:^(BOOL success) {
        if(success) {
            [self close];
        } else {
            [self showWrongPassword];
        }
    }];
}

- (void)loginWithUserName:(NSString*)username password:(NSString*)password {
    NSDictionary *dic=@{@"login":username,@"password":password};
    [[ICRequestManager sharedManager] POST:@"MobileApp/GetActiveCompanies" parameters:dic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *companies=(NSArray*)responseObject;
        if(companies.count==1) {
            
        } else {
            
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

@end
