//
//  RegisterViewController.m
//  icanvass
//
//  Created by Roman Kot on 14.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "RegisterViewController.h"
#import "ICRequestManager.h"
#import "Mixpanel.h"

@interface RegisterViewController ()
@property (nonatomic,weak) UITextField *activeField;
@end

@implementation RegisterViewController

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
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
	// Do any additional setup after loading the view.
}

#pragma mark - Helpers

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (NSString*)trim:(UITextField*)textField {
    return [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)showErrors:(NSArray*)errors {
    NSString *m=[errors componentsJoinedByString:@"\n"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:m
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)proceedWithRegistration {
/*    dict[@"CompanyLogin"] = [_txtCompanyName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"EmailAddress"] = [_txtEMail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"FirstName"] = [_txtFirstName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"LastName"] = [_txtLastName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //new
    dict[@"Password"] = [_txtPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"Phone"] = [_txtPhone.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
 */
    NSDictionary *d=@{@"FirstName":[self trim:_firstNameTextField],
                      @"LastName":[self trim:_lastNameTextField],
                      @"CompanyLogin":[self trim:_companyTextField],
                      @"Phone":[self trim:_phoneTextField],
                      @"EmailAddress":[self trim:_emailTextField],
                      @"Password":[self trim:_passwordTextField]};
    [[ICRequestManager sharedManager] registerWithDictionary:d cb:^(BOOL success, id response) {
        if(success) {
            Mixpanel *mixpanel=[Mixpanel sharedInstance];
            NSString *distinctID=mixpanel.distinctId;
            //[mixpanel createAlias:_txtEMail.text forDistinctID:mixpanel.distinctId];
            // You must call identify if you haven't already
            // (e.g., when your app launches).
            [mixpanel identify:d[@"EmailAdderss"]];
            [mixpanel createAlias:distinctID forDistinctID:d[@"EmailAdderss"]];
            [mixpanel registerSuperPropertiesOnce:@{@"company":d[@"CompanyLogin"]}];
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                                   UIRemoteNotificationTypeSound |
                                                                                   UIRemoteNotificationTypeAlert)];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
        } else {
            if(response[@"Message"]) {
                [self showErrors:response[@"Message"]];
            }
        }
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeField=textField;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField==_passwordTextField) {
        [textField resignFirstResponder];
        [self proceedWithRegistration];
    } else {
        NSUInteger idx=[_fieldsCollection indexOfObject:textField];
        [_fieldsCollection[idx+1] becomeFirstResponder];
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
