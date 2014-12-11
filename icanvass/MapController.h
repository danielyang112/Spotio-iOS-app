//
//  MapController.h
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeViewController.h"
#import "Clustering/GClusterManager.h"

#import "REVClusterMapView.h"

@class Pin;

@class MapController;
@protocol MapControllerDelegate <NSObject>
- (void)mapController:(MapController*)map didSelectBuildingAtCoordinate:(CLLocationCoordinate2D)coordinate;
@end

@interface MapController : UIViewController<UISearchBarDelegate,MKMapViewDelegate>{
    
    REVClusterMapView *_mapview;
    UITouch *anntouch;
}
@property (nonatomic,strong) CLLocation *location;
@property (nonatomic,weak) id<MapControllerDelegate> delegate;
@property (nonatomic,strong) NSArray *pins;
@property (nonatomic,strong) NSArray *filtered;
@property (nonatomic) BOOL moved;
@property (nonatomic,strong) UIToolbar *toolBar;

- (void)viewOnMap:(Pin*)pin;
- (void)setLocation:(CLLocation *)location;
- (void)setCenterLocation:(CLLocationCoordinate2D)location zoomLavel:(double)zoomLavel;
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view1;

@end
