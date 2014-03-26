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
@property (nonatomic,strong) NSArray *controllers;
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D tappedCoordinate;
@property (nonatomic) BOOL tapped;
@property (nonatomic,weak) UIViewController *current;
@property (nonatomic,strong) MapController *map;
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
    [self switchToViewController:_controllers[0]];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Helpers

-(void)setupLeftMenuButton{
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
}

-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)switchToViewController:(UIViewController*)vc {
    if(vc==_current) return;
    
    [self cycleFromViewController:_current toViewController:vc];
}

- (void)cycleFromViewController:(UIViewController*)oldv toViewController:(UIViewController*)newv {
    [oldv willMoveToParentViewController:nil];
    [self addChildViewController:newv];
    
    newv.view.frame=_container.bounds;
    
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
    
    [self transitionFromViewController:oldv toViewController:newv
                              duration: 0.25 options:0
                            animations:^{}
                            completion:completion];
}

#pragma mark - Actions

- (IBAction)filter:(id)sender {
    
}

- (IBAction)valueChanged:(id)sender {
    UISegmentedControl *segmented=(UISegmentedControl*)sender;
    [self switchToViewController:_controllers[segmented.selectedSegmentIndex]];
}

#pragma mark - MapControllerDelegate

- (void)mapController:(MapController*)map didSelectBuildingAtCoordinate:(CLLocationCoordinate2D)coordinate {
    NSLog(@"%f, %f",coordinate.latitude, coordinate.longitude);
    self.tappedCoordinate=coordinate;
    self.tapped=YES;
    [self performSegueWithIdentifier:@"AddPin" sender:nil];
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
        _tapped=NO;
        dc.adding=YES;
    } else if([segue.identifier isEqualToString:@"ViewPin"]) {
        
    }
}

@end
