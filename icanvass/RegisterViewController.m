//
//  RegisterViewController.m
//  icanvass
//
//  Created by Roman Kot on 14.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "RegisterViewController.h"
#import "AlmostDoneViewController.h"
#import "ICRequestManager.h"
#import "Mixpanel.h"
#import <BugSense-iOS/BugSenseController.h>

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
    //    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    UIColor *color = [UIColor lightGrayColor];
    for(UITextField *f in _fieldsCollection) {
        f.attributedPlaceholder = [[NSAttributedString alloc] initWithString:f.placeholder attributes:@{NSForegroundColorAttributeName:color}];
    }
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[Mixpanel sharedInstance] track:@"RegisterView"];
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
    NSString *email=[self trim:_emailTextField];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
//    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    NSDictionary *d=@{@"FirstName":[self trim:_firstNameTextField],
                      @"LastName":[self trim:_lastNameTextField],
                      @"CompanyLogin":[NSString stringWithFormat:@"%@+%@",email,date],
                      @"Phone":[self trim:_phoneTextField],
                      @"EmailAddress":email,
                      @"Password":[self trim:_passwordTextField]};
    [[ICRequestManager sharedManager] registerWithDictionary:d cb:^(BOOL success, id response) {
        if(success) {
            Mixpanel *mixpanel=[Mixpanel sharedInstance];
            NSString *distinctID=mixpanel.distinctId;
            //[mixpanel createAlias:_txtEMail.text forDistinctID:mixpanel.distinctId];
            // You must call identify if you haven't already
            // (e.g., when your app launches).
            [mixpanel identify:d[@"EmailAdderss"]];
            [BugSenseController setUserIdentifier:d[@"EmailAdderss"]];
            [mixpanel createAlias:distinctID forDistinctID:d[@"EmailAdderss"]];
            [mixpanel registerSuperPropertiesOnce:@{@"company":d[@"CompanyLogin"]}];
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                                   UIRemoteNotificationTypeSound |
                                                                                   UIRemoteNotificationTypeAlert)];
            [self performSegueWithIdentifier:@"AlmostDone" sender:nil];
        } else {
            if(response[@"Message"]) {
                [self showErrors:response[@"Message"]];
            }else{
                [self showErrors:@[@"An error occured."]];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    AlmostDoneViewController *advc=segue.destinationViewController;
    advc.company=[self trim:_companyTextField];
    advc.username=[self trim:_emailTextField];
}

@end
