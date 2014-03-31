//
//  LoginViewController.m
//  icanvass
//
//  Created by Roman Kot on 14.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "LoginViewController.h"
#import "ICRequestManager.h"
#import "Mixpanel.h"

@interface LoginViewController ()
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *company;
@property (nonatomic,strong) NSArray *companies;
@property (nonatomic,weak) UITextField *activeField;
@end

@implementation LoginViewController

#pragma mark - View Controller

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[Mixpanel sharedInstance] track:@"LoginView"];
}

#pragma mark - Helpers

- (void)close {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)showWrongPassword:(BOOL)show {
    self.wrongPassLabel.hidden=!show;
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password company:(NSString*)company {
    self.company=company;
    [self showWrongPassword:NO];
    [[ICRequestManager sharedManager] loginUserName:username password:password company:company cb:^(BOOL success) {
        if(success) {
            Mixpanel *mixpanel=[Mixpanel sharedInstance];
            [mixpanel identify:username];
            [mixpanel registerSuperPropertiesOnce:@{@"company":company}];
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                                   UIRemoteNotificationTypeSound |
                                                                                   UIRemoteNotificationTypeAlert)];
            [self close];
        } else {
            [self showWrongPassword:YES];
        }
    }];
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password {
    self.username=username;
    self.password=password;
    NSDictionary *dic=@{@"login":username,@"password":password};
    [[ICRequestManager sharedManager] POST:@"MobileApp/GetActiveCompanies" parameters:dic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.companies=(NSArray*)responseObject;
        if(![_companies count]){
            [self showWrongPassword:YES];
        } else if(_companies.count==1) {
            [self loginWithUsername:username password:password company:_companies[0]];
        } else {
            [self showCompanySelection];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
}

- (void)showCompanySelection {
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"Select company" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for(NSString *company in _companies){
        [sheet addButtonWithTitle:company];
    }
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.cancelButtonIndex=_companies.count;
    [sheet showInView:self.view];
    //[sheet autorelease];
}

#pragma mark - Actions

- (IBAction)hideKeyboard:(UIButton *)sender {
    [_activeField resignFirstResponder];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex!=actionSheet.cancelButtonIndex){
        [self loginWithUsername:_username password:_password company:_companies[buttonIndex]];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeField=textField;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField==_loginTextField) {
        [_passwordTextField becomeFirstResponder];
    } else if(textField==_passwordTextField) {
        [textField resignFirstResponder];
        [self loginWithUsername:_loginTextField.text password:_passwordTextField.text];
    }
    return YES;
}

@end
