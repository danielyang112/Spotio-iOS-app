//
//  HomeController.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "HomeViewController.h"
#import "ListController.h"
#import "MapController.h"
#import "DetailsViewController.h"
#import "MMDrawerController/MMDrawerBarButtonItem.h"

@interface HomeViewController () <MapControllerDelegate>
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D tappedCoordinate;
@property (nonatomic) BOOL tapped;
@property (nonatomic,weak) UIViewController *current;
@end

@implementation HomeViewController

#pragma mark - UIViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        self.locationManager=[CLLocationManager new];
        _locationManager.delegate=self;
        _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
        _locationManager.distanceFilter=5;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLeftMenuButton];
    ListController *list=[self.storyboard instantiateViewControllerWithIdentifier:@"ListController"];
    //list.delegate=self;
    self.map=[self.storyboard instantiateViewControllerWithIdentifier:@"MapController"];
    _map.delegate=self;
    _map.location=_locationManager.location;
    self.controllers=@[_map,list];
    [self switchToViewController:_controllers[0] animated:NO];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (void)viewWillLayoutSubviews {
    CGRect f=self.view.bounds;
    f.size.height-=44.f;
    self.container.frame=f;
    _current.view.frame=_container.bounds;
}

#pragma mark - Helpers

-(void)setupLeftMenuButton{
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
}

-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)switchToViewController:(UIViewController*)vc animated:(BOOL)animated {
    if(vc==_current) return;
    
    [self cycleFromViewController:_current toViewController:vc animated:animated];
}

- (void)cycleFromViewController:(UIViewController*)oldv toViewController:(UIViewController*)newv animated:(BOOL)animated{
    [oldv willMoveToParentViewController:nil];
    [self addChildViewController:newv];
    
    newv.view.frame=self.container.bounds;
    
    void(^completion)(BOOL)=^void(BOOL finished){
        [oldv removeFromParentViewController];
        [newv didMoveToParentViewController:self];
        self.current=newv;
    };
    
    if(!oldv) { //transitionFromVC toVC requires both vcs, if there is no old I need to add new view myself and call completion block
        [self.container addSubview:newv.view];
        completion(YES);
        return;
    }
    
    if(!animated){
        [oldv.view removeFromSuperview];[self.container addSubview:newv.view];
        completion(YES);
        return;
    }
    
    [self transitionFromViewController:oldv toViewController:newv
                              duration: 0.25 options:0
                            animations:^{}
                            completion:completion];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)shareClicked:(id)sender {
    
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
    
    for(Pin *pin in self.map.filtered){
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
    
    /*NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectoryPath  stringByAppendingPathComponent:@"history.csv"];
    //        filePath = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];*/
    NSData *myData = [mainString dataUsingEncoding:NSUTF8StringEncoding];
    
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    mailer.mailComposeDelegate = self;
    [mailer setSubject:@"CSV File"];
    [mailer addAttachmentData:myData mimeType:@"text/csv" fileName:@"Spreadsheet.csv"];
    [self presentViewController:mailer animated:YES completion:nil];
}

- (IBAction)filter:(id)sender {
    
}

- (IBAction)valueChanged:(id)sender {
    UISegmentedControl *segmented=(UISegmentedControl*)sender;
    [self switchToViewController:_controllers[segmented.selectedSegmentIndex] animated:YES];
}

#pragma mark - MapControllerDelegate

- (void)mapController:(MapController*)map didSelectBuildingAtCoordinate:(CLLocationCoordinate2D)coordinate {
    NSLog(@"%f, %f",coordinate.latitude, coordinate.longitude);
    self.tappedCoordinate=coordinate;
    self.tapped=YES;
    //[self performSegueWithIdentifier:@"AddPin" sender:nil];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navController = (UINavigationController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"navController"];
    DetailsViewController *dc=(DetailsViewController*)navController.topViewController;
    dc.coordinate=_tapped?_tappedCoordinate:_locationManager.location.coordinate;
    dc.userCoordinate=_locationManager.location.coordinate;
    _tapped=NO;
    dc.adding=YES;
    [self.navigationController pushViewController:dc animated:YES];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation *location = [locations lastObject];
    NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        // If the event is recent, do something with it.
        NSLog(@"recent latitude %.6f, longitude %.6f\n", location.coordinate.latitude, location.coordinate.longitude);
        _map.location=location;
    }
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"AddPin"]) {
        UINavigationController *nc=(UINavigationController*)[segue destinationViewController];
        DetailsViewController *dc=(DetailsViewController*)nc.topViewController;
        dc.coordinate=_tapped?_tappedCoordinate:_locationManager.location.coordinate;
        dc.userCoordinate=_locationManager.location.coordinate;
        _tapped=NO;
        dc.adding=YES;
    } else if([segue.identifier isEqualToString:@"ViewPin"]) {
        
    }
}

@end
