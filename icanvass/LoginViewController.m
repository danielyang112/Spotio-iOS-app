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
#import "SVProgressHUD.h"

@interface LoginViewController ()
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *company;
@property (nonatomic,strong) NSArray *companies;
@property (nonatomic,weak) UITextField *activeField;
@property (nonatomic) BOOL loggingIn;
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
    if([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]){
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
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

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    _loggingIn=NO;
    [[Mixpanel sharedInstance] track:@"LoginView"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
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
//    self.wrongPassLabel.hidden=!show;
    if(!show) return;
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                      message:@"Wrong username or password"
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    [message show];
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password company:(NSString*)company {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    _loggingIn=YES;
    self.company=company;
    [[ICRequestManager sharedManager] loginUserName:username password:password company:company cb:^(BOOL success) {
        [SVProgressHUD dismiss];
        _loggingIn=NO;
        if(success) {
            Mixpanel *mixpanel=[Mixpanel sharedInstance];
            [mixpanel identify:username];
            [BugSenseController setUserIdentifier:username];
            [mixpanel registerSuperPropertiesOnce:@{@"company":company}];
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                                   UIRemoteNotificationTypeSound |
                                                                                   UIRemoteNotificationTypeAlert)];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ICUserLoggedInn" object:nil];
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
            [SVProgressHUD dismiss];
            _loggingIn=NO;
            [self showWrongPassword:YES];
        } else if(_companies.count==1) {
            [self loginWithUsername:username password:password company:_companies[0]];
        } else {
            _loggingIn=NO;
            [self showCompanySelection];
            [SVProgressHUD dismiss];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        [SVProgressHUD dismiss];
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
    if(_loggingIn) return;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://app.spotio.com/Account/ForgotPassword"]];
}

- (IBAction)hideKeyboard:(UIButton *)sender {
    [_activeField resignFirstResponder];
}

- (IBAction)login:(id)sender {
    if(_loggingIn) return;
    [_activeField resignFirstResponder];
    _loggingIn=YES;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [self loginWithUsername:_loginTextField.text password:_passwordTextField.text];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex!=actionSheet.cancelButtonIndex){
        [self loginWithUsername:_username password:_password company:_companies[buttonIndex]];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return !_loggingIn;
}

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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return !_loggingIn;
}

@end
