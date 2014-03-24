//
//  MapController.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "MapController.h"
#import "Pins.h"
#import "PinTemp.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MapController () <GMSMapViewDelegate>
@property (nonatomic,strong) GMSMapView *mapView;
@property (nonatomic) BOOL moved;
@property (nonatomic) BOOL satellite;
@property (nonatomic,strong) NSMutableDictionary *markers;
@property (nonatomic,strong) NSMutableDictionary *icons;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsChanged:) name:@"ICPinColors" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapSettingsChanged:) name:@"ICMapSettings" object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView=[GMSMapView mapWithFrame:CGRectZero camera:[self cameraPosition]];
    _mapView.delegate=self;
    _mapView.myLocationEnabled=YES;
    _mapView.settings.myLocationButton=YES;
    _mapView.settings.compassButton=YES;
    _mapView.mapType=_satellite?kGMSTypeSatellite:kGMSTypeNormal;
    self.view=_mapView;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //_moved=NO;    //still weird
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

#pragma mark - Helpers

- (GMSCameraPosition*)cameraPosition {
    return [GMSCameraPosition cameraWithLatitude:_location.coordinate.latitude
                                       longitude:_location.coordinate.longitude
                                            zoom:18];
}

- (UIImage*)iconForPin:(PinTemp*)pin {
    if(!_icons[pin.status]){
        _icons[pin.status]=[GMSMarker markerImageWithColor:[[Pins sharedInstance] colorForStatus:pin.status]];
    }
    return _icons[pin.status];
}

- (GMSMarker*)markerForPin:(PinTemp*)pin {
    CLLocationCoordinate2D position=CLLocationCoordinate2DMake([pin.latitude doubleValue], [pin.longitude doubleValue]);
    GMSMarker *marker=[GMSMarker markerWithPosition:position];
    marker.title=[NSString stringWithFormat:@"%@ %@",pin.location.streetNumber, pin.location.streetName];
    marker.icon=[self iconForPin:pin];
    marker.map=_mapView;
    return marker;
}

- (void)refresh {
    [[Pins sharedInstance] sendPinsTo:^(NSArray *a) {
        for(GMSMarker *m in _markers.allValues){
            m.map=nil;
        }
        [_markers removeAllObjects];
        for(PinTemp *pin in a){
            GMSMarker *marker=[self markerForPin:pin];
            self.markers[pin.ident]=marker;
        }
    }];
}

#pragma mark - Notifications

- (void)colorsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [_icons removeAllObjects];
    [self refresh];
}

- (void)pinsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [self refresh];
}

- (void)mapSettingsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    self.satellite=[notification.userInfo[@"satellite"] boolValue];
    _mapView.mapType=_satellite?kGMSTypeSatellite:kGMSTypeNormal;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView*)mapView willMove:(BOOL)gesture {
    if(gesture) {
        self.moved=YES;
    }
}

- (void)mapView:(GMSMapView*)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [_delegate mapController:self didSelectBuildingAtCoordinate:coordinate];
}

#pragma mark - API

- (void)setLocation:(CLLocation *)location {
    _location=location;
    if(!_moved) {
        [_mapView animateToCameraPosition:[self cameraPosition]];
    }
}

@end
