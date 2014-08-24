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
#import <QuartzCore/QuartzCore.h>
#import "SVProgressHUD.h"

@interface RegisterViewController ()
@property (nonatomic,weak) UITextField *activeField;
@property (nonatomic,strong) NSString *companyName;
@property (nonatomic) BOOL registering;
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
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, f.frame.size.height-1.0f, f.frame.size.width, 1.0f);
        bottomBorder.backgroundColor = color.CGColor;
        [f.layer addSublayer:bottomBorder];
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
    if(_registering) return;
    _registering=YES;
    [_activeField resignFirstResponder];
    [SVProgressHUD show];
/*    dict[@"CompanyLogin"] = [_txtCompanyName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"EmailAddress"] = [_txtEMail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"FirstName"] = [_txtFirstName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"LastName"] = [_txtLastName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //new
    dict[@"Password"] = [_txtPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"Phone"] = [_txtPhone.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
 */
    NSString *email=[self trim:_emailTextField];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
//    [dateFormatter setTimeZone:timeZone];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
//    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    
    NSArray *names=[[self trim:_firstNameTextField] componentsSeparatedByString:@" "];
    
    self.companyName=[self trim:_lastNameTextField];
//    if([_companyName isEqualToString:@""]) {
//        self.companyName=[NSString stringWithFormat:@"%@+%@",email,date];
//    }
    
    NSDictionary *d=@{@"FirstName":[names count]>0?names[0]:@"",
                      @"LastName":[names count]>1?names[1]:@"",
                      @"CompanyName":_companyName,
                      @"Phone":[self trim:_phoneTextField],
                      @"EmailAddress":email,
                      @"Password":[self trim:_passwordTextField]};
    RegisterViewController __weak *weakSelf=self;
    [[ICRequestManager sharedManager] registerWithDictionary:d cb:^(BOOL success, id response) {
        [SVProgressHUD dismiss];
        _registering=NO;
        if(success) {
            Mixpanel *mixpanel=[Mixpanel sharedInstance];
            NSString *distinctID=mixpanel.distinctId;
            //[mixpanel createAlias:_txtEMail.text forDistinctID:mixpanel.distinctId];
            // You must call identify if you haven't already
            // (e.g., when your app launches).
            [mixpanel identify:d[@"EmailAddress"]];
            [BugSenseController setUserIdentifier:d[@"EmailAddress"]];
            [mixpanel createAlias:distinctID forDistinctID:d[@"EmailAddress"]];
            [mixpanel registerSuperPropertiesOnce:@{@"company":d[@"CompanyName"]}];
            [weakSelf performSegueWithIdentifier:@"AlmostDone" sender:nil];
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                                   UIRemoteNotificationTypeSound |
                                                                                   UIRemoteNotificationTypeAlert)];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ICUserLoggedInn" object:nil];
            
        } else {
            if(response[@"Message"]) {
                [weakSelf showErrors:response[@"Message"]];
            }else{
                [weakSelf showErrors:@[@"An error occured."]];
            }
        }
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return !_registering;
}

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

- (IBAction)next:(id)sender {
    [self proceedWithRegistration];
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
    advc.company=_companyName;
    advc.username=[self trim:_emailTextField];
}

@end
