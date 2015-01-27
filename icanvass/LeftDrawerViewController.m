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
    //self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    _mapSwitch.on=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
    
}

- (IBAction)appDetails:(id)sender {
	AppDetailViewController *vc=[self.storyboard instantiateViewControllerWithIdentifier:@"AppDetailViewController"];
//	UINavigationController *nc=[[UINavigationController alloc] initWithRootViewController:vc];
//	[self.mm_drawerController setCenterViewController:nc
//								   withCloseAnimation:YES
//										   completion:nil];
	[self presentViewController:vc animated:YES completion:nil];
}

#pragma mark -

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0)
        return 50.0;
    
    return 64.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellSettings" forIndexPath:indexPath];
    
    // Configure the cell...
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:2];
    
    switch ((int)indexPath.row) {
        case 1:
            label.text = @"Performance";
            imageView.image = [UIImage imageNamed:@"settings_performance"];
            break;
        case 2:
            label.text = @"Map";
            imageView.image = [UIImage imageNamed:@"settings_map"];
            break;
        case 3:
            label.text = @"List";
            imageView.image = [UIImage imageNamed:@"settings_list"];
            break;
        case 4:
            label.text = @"Settings";
            imageView.image = [UIImage imageNamed:@"settings_settings"];
            break;
        case 5:
            label.text = @"Help & Feedback";
            imageView.image = [UIImage imageNamed:@"settings_support"];
            break;

        default:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            label.text = @"Spotio";
            imageView.image = [UIImage imageNamed:@"settings_menu"];
            label.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:24.0f];
            break;
    }
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:243/255.0 green:156/255.0 blue:18/255.0 alpha:1.0];
    [cell setSelectedBackgroundView:bgColorView];
    cell.backgroundColor = [UIColor clearColor];
    cell.separatorInset = UIEdgeInsetsMake(0.f, cell.bounds.size.width, 0.f, 0.f);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1) {
        
    } else if (indexPath.row == 2) {
        UINavigationController *nc=[self.storyboard instantiateViewControllerWithIdentifier:@"InitialNavigationController"];
        [self.mm_drawerController setCenterViewController:nc
                                       withCloseAnimation:YES
                                               completion:nil];
    } else if (indexPath.row == 3) {
        UINavigationController *nc=(UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:@"InitialNavigationController"];
        [[NSUserDefaults standardUserDefaults] setObject:@"list" forKey:kCategory];
        [self.mm_drawerController setCenterViewController:nc
                                       withCloseAnimation:YES
                                               completion:nil];
    } else if (indexPath.row == 4) {
        AppDetailViewController *vc=[self.storyboard instantiateViewControllerWithIdentifier:@"AppDetailViewController"];
        UINavigationController *nc=[[UINavigationController alloc] initWithRootViewController:vc];
        nc.navigationBar.barTintColor = [UIColor colorWithRed:37/255.0 green:37/255.0 blue:37/255.0 alpha:1.0];
        nc.navigationBar.translucent = NO;
        [self.mm_drawerController setCenterViewController:nc
                                        withCloseAnimation:YES
                                               completion:nil];
        //[self presentViewController:vc animated:YES completion:nil];
    } else if (indexPath.row == 5) {
        NSString *username=[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey];
        [FDSupport setUseremail:username];
        [[FDSupport sharedInstance] presentSupport:self];
    }
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
