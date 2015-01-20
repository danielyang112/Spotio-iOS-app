//
//  RegisterViewController.m
//  icanvass
//
//  Created by Roman Kot on 14.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#define kIndustrySheet 1
#define kRoleSheet 2
#define kEmployeesSheet 4

#import "RegisterViewController.h"
#import "AlmostDoneViewController.h"
#import "ICRequestManager.h"
#import "Mixpanel.h"
#import <BugSense-iOS/BugSenseController.h>
#import <QuartzCore/QuartzCore.h>
#import "SVProgressHUD.h"
#import "TutorialViewController.h"

@interface RegisterViewController ()
{
    BOOL industrySelected;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintBottom;
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
    industrySelected = FALSE;
    UIColor *color = [UIColor lightGrayColor];
    for(UITextField *f in _fieldsCollection) {
        f.attributedPlaceholder = [[NSAttributedString alloc] initWithString:f.placeholder attributes:@{NSForegroundColorAttributeName:color}];
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, f.frame.size.height-1.0f, f.frame.size.width, 1.0f);
        bottomBorder.backgroundColor = color.CGColor;
        [f.layer addSublayer:bottomBorder];
    }
    [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, _doneButton.frame.origin.y + _doneButton.frame.size.height + 10.f)];
	// Do any additional setup after loading the view.
	[_emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[Mixpanel sharedInstance] track:@"RegisterView"];
}


- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.doneButton.frame.size.height + self.doneButton.frame.origin.y);
}

#pragma mark - Helpers

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardNotification:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardNotification:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)handleKeyboardNotification:(NSNotification*)sender {
	CGRect beginFrame = [sender.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat yDiff = endFrame.origin.y - beginFrame.origin.y;
	CGFloat duration = [sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	[UIView animateWithDuration:duration animations:^{
		UIEdgeInsets insets = self.scrollView.contentInset;
		insets.bottom -= yDiff;
		self.scrollView.contentInset = insets;
		insets = self.scrollView.scrollIndicatorInsets;
		insets.bottom -= yDiff;
		self.scrollView.scrollIndicatorInsets = insets;

	}];
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

- (void)proceedWithRegistration
{
    [_activeField resignFirstResponder];
    
/*    dict[@"CompanyLogin"] = [_txtCompanyName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"EmailAddress"] = [_txtEMail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"FirstName"] = [_txtFirstName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"LastName"] = [_txtLastName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //new
    dict[@"Password"] = [_txtPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dict[@"Phone"] = [_txtPhone.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
 */
//    NSString *email=[self trim:_emailTextField];
/*
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
//    [dateFormatter setTimeZone:timeZone];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
//    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    
//    if([_companyName isEqualToString:@""]) {
//        self.companyName=[NSString stringWithFormat:@"%@+%@",email,date];
//    }
    */
    BOOL allOk = [self checkFullName];
    if (allOk)
    {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        
        if(_registering) return;
        _registering=YES;
        
        NSArray *fullName = [_firstNameTextField.text componentsSeparatedByString:@" "];
        NSDictionary *d=@{@"FirstName":[fullName firstObject],
                          @"LastName":[fullName lastObject],
                          @"CompanyName":[self trim:_companyTextField],
                          @"Phone":[self trim:_phoneTextField],
                          @"EmailAddress":[self trim:_emailTextField],
                          @"Password":[self trim:_passwordTextField]};
        RegisterViewController __weak *weakSelf=self;
        [[ICRequestManager sharedManager] registerWithDictionary:d cb:^(BOOL success, id response)
        {
            [SVProgressHUD dismiss];
            _registering=NO;
            if(success)
            {
                Mixpanel *mixpanel=[Mixpanel sharedInstance];
                NSString *distinctID=mixpanel.distinctId;
                //[mixpanel createAlias:_txtEMail.text forDistinctID:mixpanel.distinctId];
                // You must call identify if you haven't already
                // (e.g., when your app launches).
                [mixpanel identify:d[@"EmailAddress"]];
                [BugSenseController setUserIdentifier:d[@"EmailAddress"]];
                [mixpanel createAlias:distinctID forDistinctID:d[@"EmailAddress"]];
                [mixpanel registerSuperPropertiesOnce:@{@"company":d[@"CompanyName"]}];
                
                NSDictionary *dic=@{@"companyLogin":[self trim:_companyTextField],
                                    @"login":[self trim:_emailTextField],
                                    @"answers":@{@"Industry":@"",
                                                 @"Role":@"",
                                                 @"EstimateUsersNumber":@""}};
                [[ICRequestManager sharedManager] POST:@"MobileApp/SaveRegistrantionQuestionsAnswers" parameters:dic success:^(AFHTTPRequestOperation *operation, id responseObject)
                 {
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"ICQuestions" object:nil];
					 [TutorialViewController showTutorialWithDidShowCompletion:^{
						 [weakSelf dismissViewControllerAnimated:YES completion:^{}];
					 }];
					 [[NSNotificationCenter defaultCenter] postNotificationName:@"ICRegister" object:nil];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error)
                 {
                     NSLog(@"%@",error);
                 }];
                
                
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                                       UIRemoteNotificationTypeSound |
                                                                                       UIRemoteNotificationTypeAlert)];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ICUserLoggedInn" object:nil userInfo:@{@"fromRegister": @(YES)}];
            }
            else
            {
                if(response[@"Message"])
                {
                    [weakSelf showErrors:response[@"Message"]];
                }
                else
                {
                    [weakSelf showErrors:@[@"An error occured."]];
                }
            }
        }];
    }
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
-(void)textFieldDidEndEditing:(UITextField *)textField
{
//    if (textField ==_firstNameTextField)
//    {
//        [self checkFullName];
//    }
}

-(BOOL)checkFullName
{
    NSArray *fullName = [_firstNameTextField.text componentsSeparatedByString:@" "];
    if ([fullName count]>1)
    {
        if (!([[fullName lastObject] isEqualToString:@""]||[[fullName firstObject] isEqualToString:@""]))
        {
            return YES;
        }
        else
        {
            UIAlertView* showError = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Enter Full Name: First and Last" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [showError show];
        }
        
    }
    else
    {
        UIAlertView* showError = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Enter Full Name: First and Last" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [showError show];
    }
    return NO;

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField==_passwordTextField) {
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

#pragma mark - Navigation

- (IBAction)role:(id)sender {
    [self showRoles];
}

- (IBAction)employees:(id)sender {
    [self showEmployees];
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
//    advc.company=_companyName;
//    advc.username=[self trim:_emailTextField];
}

- (void)showRoles {
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"Select your role:"
                                                     delegate:self
                                            cancelButtonTitle:nil
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"Manager", @"Owner", @"Sales Rep", @"Cavasser", nil];
    sheet.tag=kRoleSheet;
    [sheet showInView:self.view];
}

- (void)showEmployees {
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"How many employees would you be using: "
                                                     delegate:self
                                            cancelButtonTitle:nil
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"1 - 10", @"11 - 50", @"51 - 100", @"100+", nil];
    sheet.tag=kEmployeesSheet;
    [sheet showInView:self.view];
}



@end
