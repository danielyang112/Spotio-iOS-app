//
//  MapController.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#import "MapController.h"
#import "DetailsViewController.h"
#import "Pins.h"
#import "Pin.h"
#import "Mixpanel.h"
#import "Users.h"
#import "utilities.h"
#import "GClusterAlgorithm.h"
#import "NonHierarchicalDistanceBasedAlgorithm.h"
#import "GDefaultClusterRenderer.h"
#import "GClusterItem.h"
#import "CustomClusterManager.h"
//#import <sys/utsname.h>




@interface MapController () <GMSMapViewDelegate,NSFetchedResultsControllerDelegate>
{
    CustomClusterManager *clusterManager_;
    BOOL firstLocationUpdate_;
    GMSCameraPosition *previousCameraPosition;

}
@property (nonatomic,strong) NSMutableDictionary *markers;
@property (nonatomic,strong) GMSMapView *allAnnotationMapView;

@property (nonatomic,strong) NSMutableDictionary *icons;
@property (nonatomic,strong) NSString *searchText;
@property (nonatomic,strong) GMSMarker* selectedMarker;
@property (nonatomic,strong) UISearchBar *searchBar;
@property (nonatomic,strong) NSFetchedResultsController* fetchController;
@end

@implementation MapController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        self.markers=[[NSMutableDictionary alloc] initWithCapacity:10];
        self.icons=[[NSMutableDictionary alloc] initWithCapacity:5];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinsChanged:) name:@"ICPinsChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchChanged:) name:@"ICSearch" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsChanged:) name:@"ICPinColors" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapSettingsChanged:) name:@"ICMapSettings" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:@"ICLogOut" object:nil];
    }
    return self;
}
//-(NSString*)machineName
//{
//    struct utsname systemInfo;
//    uname(&systemInfo);
//    
//    return [NSString stringWithCString:systemInfo.machine
//                              encoding:NSUTF8StringEncoding];
//}
//


- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect f=self.view.bounds;
    self.mapView=[GMSMapView mapWithFrame:f camera:[self cameraPosition]];
    _mapView.delegate=self;
    _mapView.myLocationEnabled=YES;
    [_mapView isMyLocationEnabled];
//    if ([[self machineName] isEqualToString:@"iPhone3,1"]||[[self machineName] isEqualToString:@"iPhone4,1"])
//    {
//        _mapView.indoorEnabled = NO;
//        _mapView.buildingsEnabled = NO;
//    }
//    else
//    {
//        _mapView.indoorEnabled = YES;
//        _mapView.buildingsEnabled = YES;
//
//    }
//    [_mapView addObserver:self
//               forKeyPath:@"myLocation"
//                  options:NSKeyValueObservingOptionNew
//                  context:NULL];
    

    _mapView.settings.myLocationButton=YES;
    NSLog(@"User's location: %@", _mapView.myLocation);

    _mapView.settings.compassButton=YES;
    clusterManager_ = [CustomClusterManager managerWithMapView:_mapView
                                                algorithm:[[NonHierarchicalDistanceBasedAlgorithm alloc] init]
                                                 renderer:[[GDefaultClusterRenderer alloc] initWithMapView:_mapView]];
    clusterManager_.trueDelegate = self;
    clusterManager_.clustered = NO;
    [_mapView setDelegate:clusterManager_];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [clusterManager_ removeItems];
        [self createClusterItems];
        [_mapView clear];
        _fetchController = [Pins sharedInstance].fetchController;
        _fetchController.delegate = self;
        [_fetchController performFetch:nil];
        

//        [clusterManager_ cluster];
    });
    BOOL satellite=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
    _mapView.mapType=satellite?kGMSTypeSatellite:kGMSTypeNormal;
    [self.view insertSubview:_mapView atIndex:0];
//    self.searchBar=[[UISearchBar alloc] initWithFrame:CGRectMake(0.f,0.f,320.f,44.f)];
//    _searchBar.delegate=self;
//    _searchBar.showsCancelButton=YES;
    [self.view addSubview:_searchBar];
    [self.view layoutIfNeeded];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        _mapView.myLocationEnabled = YES;
//    });

}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!firstLocationUpdate_) {
        // If the first location update has not yet been recieved, then jump to that
        // location.
        firstLocationUpdate_ = YES;
        CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
        _mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                         zoom:14];
    }
}


-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [clusterManager_ removeItems];
    [[Pins sharedInstance] fetchPinsFromCoreData];
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self createClusterItems];
}
- (void)viewWillLayoutSubviews {
    CGRect f=self.view.bounds;
//    f.size.height-=44.f;
//    f.origin.y+=44.f;
    self.mapView.frame=f;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    _moved=NO;    //still weird
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_mapView clear];
    [self refresh];
    if(!_pins)  [self refresh];
}

#pragma mark - Helpers

- (GMSCameraPosition*)cameraPosition {
    return [GMSCameraPosition cameraWithLatitude:_location.coordinate.latitude
                                       longitude:_location.coordinate.longitude
                                            zoom:21];
}

- (UIImage*)iconForPin:(Pin*)pin {
    if(!_icons[pin.status]){
        _icons[pin.status]=[GMSMarker markerImageWithColor:[[Pins sharedInstance] colorForStatus:pin.status]];
    }
    return _icons[pin.status];
}

- (GMSMarker*)markerForPin:(Pin*)pin {
    CLLocationCoordinate2D position=CLLocationCoordinate2DMake([pin.latitude doubleValue], [pin.longitude doubleValue]);
    
    GMSMarker *marker=[GMSMarker markerWithPosition:position];
    marker.userData=pin;
    marker.title=[NSString stringWithFormat:@"%@ %@",pin.location.streetNumber, pin.location.streetName];
    marker.icon=[self iconForPin:pin];
    [marker setAppearAnimation:kGMSMarkerAnimationPop];
    marker.map=_mapView;
    return marker;
}

- (void)filterArray {
    if(!_searchText || [_searchText isEqualToString:@""]){
        self.filtered=_pins;
        [self refreshMarkers];
        return;
    }
    self.filtered=[_pins grepWith:^BOOL(NSObject *o) {
        Pin *p=(Pin*)o;
        return ([p.status rangeOfString:_searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
        || ([p.address rangeOfString:_searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
        || ([p.address2 rangeOfString:_searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
    }];
    [self refreshMarkers];
}

- (void)refreshMarkers {
    for(GMSMarker *m in [_markers allValues]){
//        [clusterManager_ removeItems];
        m.map=nil;
    }
    [_markers removeAllObjects];
    
    for(Pin *pin in _filtered)
    {
        GMSMarker *marker=[self markerForPin:pin];
        [marker appearAnimation];

//        [clusterManager_ addItem:marker];
        self.markers[pin.ident]=marker;
    }
}



- (void)viewOnMap:(Pin*)pin {
    if(_markers[pin.ident]){
        self.mapView.selectedMarker=_markers[pin.ident];
    }
}

- (void)clear {
    [clusterManager_ removeItems];
    [self.mapView clear];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)cameraPosition
{
//    _mapView.selectedMarker?:[_mapView clear];

    [mapView clear];
    [self refresh];
}

- (GMSMarker*)clusterItem:(Pin*)pin {
    CLLocationCoordinate2D position=CLLocationCoordinate2DMake([pin.latitude doubleValue], [pin.longitude doubleValue]);
    
    GMSMarker *marker=[GMSMarker markerWithPosition:position];
    return marker;
}


- (void)createClusterItems
{
    for (Pin *pin in [[Pins sharedInstance]pins])
    {
        GMSMarker *marker=[self clusterItem:pin];
        [clusterManager_ addItem:marker];
    }
}

- (void)refresh {
    NSLog(@"%s",__FUNCTION__);
    __weak typeof(self) weakSelf = self;
    GMSVisibleRegion myRegion = _mapView.projection.visibleRegion;
    [[Pins sharedInstance] sendPinsTo:^(NSArray *a) {
        NSString *s=[Pins sharedInstance].searchText;
        if(s && ![s isEqualToString:@""]){
            weakSelf.pins=[a grepWith:^BOOL(NSObject *o) {
                Pin *p=(Pin*)o;
                return ([p.status rangeOfString:s options:NSCaseInsensitiveSearch].location != NSNotFound)
                || ([p.address rangeOfString:s options:NSCaseInsensitiveSearch].location != NSNotFound)
                || ([p.address2 rangeOfString:s options:NSCaseInsensitiveSearch].location != NSNotFound);
            }];
        }
        else
        {
            weakSelf.pins=a;
        }
        double maxLatitude = MAX(MAX(myRegion.farRight.latitude,myRegion.nearRight.latitude),MAX(myRegion.farLeft.latitude,myRegion.farRight.latitude));
        double maxLongitude = MAX(MAX(myRegion.farRight.longitude,myRegion.nearRight.longitude),MAX(myRegion.farLeft.longitude,myRegion.farRight.longitude));
        double minLatitude = MIN(MIN(myRegion.farRight.latitude,myRegion.nearRight.latitude),MIN(myRegion.farLeft.latitude,myRegion.farRight.latitude));
        double minLongitude = MIN(MIN(myRegion.farRight.longitude,myRegion.nearRight.longitude),MIN(myRegion.farLeft.longitude,myRegion.farRight.longitude));


        NSPredicate* predicateForRegion = [NSPredicate predicateWithFormat:@"SELF.latitude <= %f+0.009 AND SELF.longitude<= %f+0.009 AND self.latitude >= %f-0.009 AND SELF.longitude>= %f-0.009",maxLatitude,maxLongitude,minLatitude,minLongitude];
        weakSelf.filtered=_pins;
       self.filtered =  [weakSelf.filtered filteredArrayUsingPredicate:predicateForRegion];
        
        
        [weakSelf refreshMarkers];
    }];
}

#pragma mark - Notifications

- (void)colorsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [_icons removeAllObjects];
    [self refresh];
}
- (void)searchChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    self.mapView.selectedMarker=nil;
    [self refresh];
}

- (void)pinsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    self.mapView.selectedMarker=nil;
    [self refresh];
}

- (void)userLoggedOut:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [self clear];
}

- (void)mapSettingsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    BOOL satellite=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
    _mapView.mapType=satellite?kGMSTypeSatellite:kGMSTypeNormal;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView*)mapView willMove:(BOOL)gesture {
    if(gesture) {
        self.moved=YES;
    }
    if (_selectedMarker) {
        [self showInfoMarker];
    }

    
}

- (BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView {
    _moved=NO;
    return NO;
}

- (void)mapView:(GMSMapView*)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if(!mapView.selectedMarker){
        [_delegate mapController:self didSelectBuildingAtCoordinate:coordinate];
    }
    else
    {
        _mapView.selectedMarker = nil;
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    _selectedMarker = marker;
    //Pin *pin=marker.userData;
    //[self performSegueWithIdentifier:@"MapViewPin" sender:pin];
    return YES;
}
-(void) showInfoMarker
{
    [self mapView:_mapView markerInfoWindow:_mapView.selectedMarker];
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
    Pin *pin=_mapView.selectedMarker.userData;
    UIView *view=[[[NSBundle mainBundle] loadNibNamed:@"InfoView" owner:nil options:nil] lastObject];
    UIView *icon=[view viewWithTag:7];
    icon.backgroundColor=[[Pins sharedInstance] colorForStatus:pin.status];
    icon.layer.borderColor=[UIColor darkGrayColor].CGColor;
    icon.layer.borderWidth=1.f;
    UIView *bg=view;//[view viewWithTag:9];
    bg.layer.masksToBounds = NO;
    bg.layer.shadowOffset = CGSizeMake(-5, 5);
    bg.layer.shadowRadius = 3;
    bg.layer.shadowOpacity = 0.8;
    bg.layer.borderWidth = 1.f;
    bg.layer.borderColor = [UIColor darkGrayColor].CGColor;
    UILabel *l=(UILabel*)[view viewWithTag:1];
    l.text=pin.status;
    l=(UILabel*)[view viewWithTag:2];
//    l.text=pin.user;
    l.text=[[Users sharedInstance] fullNameForUserName:pin.user];
    l=(UILabel*)[view viewWithTag:3];
    l.text=[Pin formatDate:pin.updateDate];
    l=(UILabel*)[view viewWithTag:4];
    l.text=pin.address;
    l=(UILabel*)[view viewWithTag:5];
    l.text=pin.address2;
    //view.backgroundColor=[UIColor whiteColor];
    return view;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    Pin *pin=_selectedMarker.userData;
    [self performSegueWithIdentifier:@"MapViewPin" sender:pin];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchText=searchText;
    [self filterArray];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    //self.searchText=nil;
    //[self filterArray];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    self.searchText=nil;
    [self filterArray];
    [searchBar resignFirstResponder];
}

#pragma mark - API

- (void)setLocation:(CLLocation *)location {
    NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
    _location=location;
    if(!_moved) {
        [_mapView animateToCameraPosition:[self cameraPosition]];
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    DetailsViewController *dc=(DetailsViewController*)[segue destinationViewController];
    dc.pin=sender;
}

@end
