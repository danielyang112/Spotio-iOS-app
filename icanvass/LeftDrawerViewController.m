//
//  LeftDrawerViewController.m
//  icanvass
//
//  Created by Roman Kot on 24.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "LeftDrawerViewController.h"
#import "ICRequestManager.h"
#import "MMDrawerController/UIViewController+MMDrawerController.h"
#import "HomeViewController.h"
#import "GoToWebsiteViewController.h"
#import "ICRequestManager.h"
#import <FreshdeskSDK/FreshdeskSDK.h>
#import "Mixpanel.h"
#import "Pins.h"
#import "AppDetailViewController.h"


@interface LeftDrawerViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation LeftDrawerViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self=[super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    _mapSwitch.on=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
//	[self.mm_drawerController setRightDrawerViewController: vc];
}


#pragma mark - Actions

- (IBAction)pins:(id)sender {
    UINavigationController *nc=[self.storyboard instantiateViewControllerWithIdentifier:@"InitialNavigationController"];
    [self.mm_drawerController setCenterViewController:nc
                                   withCloseAnimation:YES
                                           completion:nil];
}

- (IBAction)satelliteView:(id)sender {
    [_mapSwitch setOn:!_mapSwitch.on animated:YES];
    [self switchChanged:_mapSwitch];
}

- (IBAction)switchChanged:(UISwitch *)sender {
    NSInteger on=sender.on?1:0;
    [[NSUserDefaults standardUserDefaults] setObject:@(on) forKey:@"Satellite"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICMapSettings" object:nil userInfo:nil];
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
}

- (IBAction)reports:(id)sender {
	if (![MFMailComposeViewController canSendMail]) {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"No Mail Account"
							  message:@"Please set up a Mail account in order to send email."
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		return;
	}

	BOOL allowed = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sharing"] isEqualToString:@"1"];
	if(!allowed) {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Share"
							  message:@"You do not have permission to share the reports."
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	NSMutableString *mainString=[[NSMutableString alloc]initWithString:@""];
	NSString *headerStr = @"\"Status\",\"Address\",\"City\",\"State\",\"Zip\",\"Name\",\"Phone\",\"Email\",\"Notes\",\"Created Dates\",\"Created Time\",\"Last Updated Date\",\"Last Updated Time\",\"User Name\"";
	[mainString appendString:headerStr];
	
	NSArray *filtered = [[Pins sharedInstance] filteredPinsArray];
	
	for(Pin *pin in filtered){
		NSString *name, *phone, *email, *notes;
		name = @"";
		phone = @"";
		email = @"";
		notes = @"";
		for(NSDictionary *d in pin.customValuesOld){
			NSNumber *id = d[@"DefinitionId"];
			switch([id intValue]){
				case 1:
					name = d[@"StringValue"];
					break;
				case 2:
					phone = d[@"StringValue"];
					break;
				case 3:
					email = d[@"StringValue"];
					break;
				case 4:
					notes = d[@"StringValue"];
					break;
			}
			
		}
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd"];
		NSString *creationDate = [formatter stringFromDate:pin.creationDate];
		NSString *updateDate = [formatter stringFromDate:pin.updateDate];
		[formatter setDateFormat:@"HH:mm:ss"];
		NSString *creationTime = [formatter stringFromDate:pin.creationDate];
		NSString *updateTime = [formatter stringFromDate:pin.updateDate];
		
		NSString *dataString = [NSString stringWithFormat:@"\n\"%@\",\"%@ %@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"", pin.status, pin.location.streetNumber, pin.location.streetName, pin.location.city, pin.location.state, pin.location.zip, name, phone, email, notes, creationDate, creationTime, updateDate, updateTime, pin.user];
		[mainString appendString:dataString];
	}
	
	NSLog(@"getdatafor csv:%@",mainString);
	
	NSData *myData = [mainString dataUsingEncoding:NSUTF8StringEncoding];

	MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
	mailer.mailComposeDelegate = self;
	[mailer setSubject:@"CSV File"];
	[mailer addAttachmentData:myData mimeType:@"text/csv" fileName:@"Spreadsheet.csv"];
	[self presentViewController:mailer animated:YES completion:nil];
	
}

- (IBAction)support:(id)sender {
    NSString *username=[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey];
    [FDSupport setUseremail:username];
    [[FDSupport sharedInstance] presentSupport:self];
}

- (IBAction)logout:(id)sender {
    [[Mixpanel sharedInstance] track:@"Logout"];
    [[ICRequestManager sharedManager] logoutWithCb:^(BOOL success) {
        [Pins sharedInstance].filter=nil;
        [self.mm_drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {}];
    }];
}

- (IBAction)appDetails:(id)sender {
	AppDetailViewController *vc=[self.storyboard instantiateViewControllerWithIdentifier:@"AppDetailViewController"];
//	UINavigationController *nc=[[UINavigationController alloc] initWithRootViewController:vc];
//	[self.mm_drawerController setCenterViewController:nc
//								   withCloseAnimation:YES
//										   completion:nil];
	[self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Delegate to MailComposer

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	if (error) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Error" message:[error localizedDescription] delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:NULL];
		[alert show];
	}
	UIAlertView *resultAlert;
	switch (result) {
		case MFMailComposeResultSent:
			resultAlert = [[UIAlertView alloc] initWithTitle:@"Sent" message:@"Mail sent successfully." delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:NULL];
			[resultAlert show];
			break;
		case MFMailComposeResultFailed:
			resultAlert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Failed to send mail." delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:NULL];
			[resultAlert show];
			break;
		case MFMailComposeResultSaved:
			resultAlert = [[UIAlertView alloc] initWithTitle:@"Saved" message:@"Mail saved successfully." delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:NULL];
			[resultAlert show];
			break;
		case MFMailComposeResultCancelled:
			break;
	}
	[self dismissViewControllerAnimated:NO completion:nil];
}


@end
