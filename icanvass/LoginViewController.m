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
#import <BugSense-iOS/BugSenseController.h>

@interface LoginViewController ()
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *company;
@property (nonatomic,strong) NSArray *companies;
@property (nonatomic,weak) UITextField *activeField;
@end

@implementation LoginViewController

#pragma mark - View Controller

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self=[super initWithCoder:aDecoder];
    if(self) {
        [self registerForKeyboardNotifications];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
    UIColor *color = [UIColor whiteColor];
    _loginTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"email address" attributes:@{NSForegroundColorAttributeName: color}];
    _loginTextField.leftViewMode=UITextFieldViewModeAlways;
    _loginTextField.leftView = paddingView;
    _passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"password" attributes:@{NSForegroundColorAttributeName: color}];
    _passwordTextField.leftViewMode=UITextFieldViewModeAlways;
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
    _passwordTextField.leftView = paddingView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[Mixpanel sharedInstance] track:@"LoginView"];
}

#pragma mark - Helpers

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

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
            [BugSenseController setUserIdentifier:username];
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

- (IBAction)forgotPassword:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://app.spotio.com/Account/ForgotPassword"]];
}

- (IBAction)hideKeyboard:(UIButton *)sender {
    [_activeField resignFirstResponder];
}

- (IBAction)login:(id)sender {
    [self loginWithUsername:_loginTextField.text password:_passwordTextField.text];
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

#pragma mark - Notifications

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, _activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:_activeField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}

@end
