//
//  MapController.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "MapController.h"
#import "DetailsViewController.h"
#import "Pins.h"
#import "Pin.h"
#import "Mixpanel.h"
#import "Users.h"
#import "utilities.h"

@interface MapController () <GMSMapViewDelegate>
@property (nonatomic,strong) NSMutableDictionary *markers;
@property (nonatomic,strong) NSMutableDictionary *icons;
@property (nonatomic,strong) NSString *searchText;
@property (nonatomic,strong) UISearchBar *searchBar;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinsChanged:) name:@"ICPinsChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchChanged:) name:@"ICSearch" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsChanged:) name:@"ICPinColors" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapSettingsChanged:) name:@"ICMapSettings" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:@"ICLogOut" object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect f=self.view.bounds;
    self.mapView=[GMSMapView mapWithFrame:f camera:[self cameraPosition]];
    _mapView.delegate=self;
    _mapView.myLocationEnabled=YES;
    _mapView.settings.myLocationButton=YES;
    _mapView.settings.compassButton=YES;
    BOOL satellite=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
    _mapView.mapType=satellite?kGMSTypeSatellite:kGMSTypeNormal;
    [self.view insertSubview:_mapView atIndex:0];
//    self.searchBar=[[UISearchBar alloc] initWithFrame:CGRectMake(0.f,0.f,320.f,44.f)];
//    _searchBar.delegate=self;
//    _searchBar.showsCancelButton=YES;
    [self.view addSubview:_searchBar];
    [self.view layoutIfNeeded];
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
        m.map=nil;
    }
    [_markers removeAllObjects];
    for(Pin *pin in _filtered){
        GMSMarker *marker=[self markerForPin:pin];
        self.markers[pin.ident]=marker;
    }
}

- (void)viewOnMap:(Pin*)pin {
    if(_markers[pin.ident]){
        self.mapView.selectedMarker=_markers[pin.ident];
    }
}

- (void)clear {
    [self.mapView clear];
}

- (void)refresh {
    NSLog(@"%s",__FUNCTION__);
    __weak typeof(self) weakSelf = self;
    [[Pins sharedInstance] sendPinsTo:^(NSArray *a) {
        NSString *s=[Pins sharedInstance].searchText;
        if(s && ![s isEqualToString:@""]){
            weakSelf.pins=[a grepWith:^BOOL(NSObject *o) {
                Pin *p=(Pin*)o;
                return ([p.status rangeOfString:s options:NSCaseInsensitiveSearch].location != NSNotFound)
                || ([p.address rangeOfString:s options:NSCaseInsensitiveSearch].location != NSNotFound)
                || ([p.address2 rangeOfString:s options:NSCaseInsensitiveSearch].location != NSNotFound);
            }];
        }else{
            weakSelf.pins=a;
        }
        weakSelf.filtered=_pins;
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
}

- (BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView {
    _moved=NO;
    return NO;
}

- (void)mapView:(GMSMapView*)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if(!mapView.selectedMarker){
        [_delegate mapController:self didSelectBuildingAtCoordinate:coordinate];
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    //Pin *pin=marker.userData;
    //[self performSegueWithIdentifier:@"MapViewPin" sender:pin];
    return NO;
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
    Pin *pin=marker.userData;
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
    l.text=[Pin formatDate:pin.creationDate];
    l=(UILabel*)[view viewWithTag:4];
    l.text=pin.address;
    l=(UILabel*)[view viewWithTag:5];
    l.text=pin.address2;
    //view.backgroundColor=[UIColor whiteColor];
    return view;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    Pin *pin=marker.userData;
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
