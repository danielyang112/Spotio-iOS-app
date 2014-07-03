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

@class PinTemp;

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

- (GMSMarker*)markerForPin:(PinTemp*)pin;
- (void)setLocation:(CLLocation *)location;

@end
