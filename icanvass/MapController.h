//
//  MapController.h
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "Clustering/GClusterManager.h"



@class Pin;

@class MapController;
@protocol MapControllerDelegate <NSObject>
- (void)mapController:(MapController*)map didSelectBuildingAtCoordinate:(CLLocationCoordinate2D)coordinate;
@end

@interface MapController : UIViewController<UISearchBarDelegate>
@property (nonatomic,strong) CLLocation *location;
@property (nonatomic,weak) id<MapControllerDelegate> delegate;
@property (nonatomic,strong) NSArray *pins;
@property (nonatomic,strong) NSArray *filtered;
@property (nonatomic,strong) GMSMapView *mapView;
@property (nonatomic) BOOL moved;

- (GMSMarker*)markerForPin:(Pin*)pin;
- (void)viewOnMap:(Pin*)pin;
- (void)setLocation:(CLLocation *)location;

@end
