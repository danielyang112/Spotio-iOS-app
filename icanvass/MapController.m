//
//  MapController.m
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "MapController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MapController () <GMSMapViewDelegate>
@property (nonatomic,strong) GMSMapView *mapView;
@property (nonatomic) BOOL located;
@end

@implementation MapController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (GMSCameraPosition*)cameraPosition {
    return [GMSCameraPosition cameraWithLatitude:_location.coordinate.latitude
                                       longitude:_location.coordinate.longitude
                                            zoom:20];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView=[GMSMapView mapWithFrame:CGRectZero camera:[self cameraPosition]];
    _mapView.delegate=self;
    _mapView.myLocationEnabled=YES;
    _mapView.settings.myLocationButton=YES;
    _mapView.settings.compassButton=YES;
    self.view=_mapView;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView*)mapView willMove:(BOOL)gesture {
    
}

- (void)mapView:(GMSMapView*)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [_delegate mapController:self didSelectBuildingAtCoordinate:coordinate];
}

#pragma mark - API

- (void)setLocation:(CLLocation *)location {
    _location=location;
    [_mapView animateToCameraPosition:[self cameraPosition]];
}

@end
