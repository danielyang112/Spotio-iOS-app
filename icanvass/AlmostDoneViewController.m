//
//  AlmostDoneViewController.m
//  icanvass
//
//  Created by Roman Kot on 17.04.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "AlmostDoneViewController.h"
#import "ICRequestManager.h"

#define kIndustrySheet 1
#define kRoleSheet 2
#define kEmployeesSheet 4

@interface AlmostDoneViewController () {
    NSInteger mask;
}

@end

@implementation AlmostDoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    _getStartedButton.enabled=NO;
    self.navigationItem.hidesBackButton=YES;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Skip" style:UIBarButtonItemStyleDone target:self action:@selector(skip:)];
	// Do any additional setup after loading the view.
}

#pragma mark - Helpers

- (void)showIndustries {
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:nil
                                                     delegate:self
                                            cancelButtonTitle:nil
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"Home Improvement", @"Cable/Satelite", @"Alarm", @"Real Estate", @"Solar", @"Other", nil];
    sheet.tag=kIndustrySheet;
    [sheet showInView:self.view];
}

- (void)showRoles {
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:nil
                                                     delegate:self
                                            cancelButtonTitle:nil
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"Manager", @"Owner", @"Sales Rep", @"Cavasser", nil];
    sheet.tag=kRoleSheet;
    [sheet showInView:self.view];
}

- (void)showEmployees {
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:nil
                                                     delegate:self
                                            cancelButtonTitle:nil
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"1 - 10", @"11 - 50", @"51 - 100", @"100+", nil];
    sheet.tag=kEmployeesSheet;
    [sheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex!=actionSheet.cancelButtonIndex){
        NSString *title=[actionSheet buttonTitleAtIndex:buttonIndex];
        if(actionSheet.tag==kIndustrySheet){
            [_industryButton setTitle:title forState:UIControlStateNormal];
        }else if(actionSheet.tag==kRoleSheet){
            [_roleButton setTitle:title forState:UIControlStateNormal];
        }else if(actionSheet.tag==kEmployeesSheet){
            [_employeesButton setTitle:title forState:UIControlStateNormal];
        }
        mask|=actionSheet.tag;
        if(mask==7){
            _getStartedButton.enabled=YES;
        }
    }
}

#pragma mark - Actions

- (void)skip:(id)sender {
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    [self performSegueWithIdentifier:@"Tutorial" sender:nil];
}

- (IBAction)industry:(id)sender {
    [self showIndustries];
}

- (IBAction)role:(id)sender {
    [self showRoles];
}

- (IBAction)employees:(id)sender {
    [self showEmployees];
}

- (IBAction)getStarted:(id)sender {
    NSDictionary *dic=@{@"companyLogin":_company,
                        @"login":_username,
                        @"answers":@{@"Industry":_industryButton.titleLabel.text,
                                     @"Role":_roleButton.titleLabel.text,
                                     @"EstimateUsersNumber":_employeesButton.titleLabel.text}};
    [[ICRequestManager sharedManager] POST:@"MobileApp/SaveRegistrantionQuestionsAnswers" parameters:dic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICQuestions" object:nil];
        [self performSegueWithIdentifier:@"Tutorial" sender:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
}
@end
