//
//  CustomClusterManager.m
//  icanvass
//
//  Created by Dmitriy on 23.09.14.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "CustomClusterManager.h"


@implementation CustomClusterManager


- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self.trueDelegate mapView:mapView didTapAtCoordinate:coordinate];
}

-(void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
    [self.trueDelegate mapView:mapView didTapInfoWindowOfMarker:marker];
}
-(BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    if (mapView.camera.zoom>12)
    {
        [self.trueDelegate mapView:mapView didTapMarker:marker];
    }
    return NO;
}

-(UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker
{
    if (mapView.camera.zoom>12)
    {
        return [self.trueDelegate mapView:mapView markerInfoWindow:marker];
        
    }
    else return nil;

}

-(void)mapView:(GMSMapView*)mapView willMove:(BOOL)gesture {
    [self.trueDelegate mapView:mapView willMove:gesture];
}
- (BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView {
    return [self.trueDelegate didTapMyLocationButtonForMapView:mapView];
    
}
- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)cameraPosition
{
    if (cameraPosition.zoom<16)
    {
        _clustered = YES;
        [super mapView:mapView idleAtCameraPosition:cameraPosition];
        return;
    }else
    {
        _clustered = NO;
        [self.trueDelegate mapView:mapView idleAtCameraPosition:cameraPosition];
        return;
    }
}


@end
