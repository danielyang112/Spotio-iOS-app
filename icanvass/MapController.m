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
#import "InfoView.h"
#import "TutorialViewController.h"
//#import <sys/utsname.h>

#import "REVClusterMap.h"
#import "REVClusterAnnotationView.h"
#import "myButton.h"
#import "Territories.h"

#define BASE_RADIUS .5 // = 1 mile
#define MINIMUM_LATITUDE_DELTA 0.20
#define BLOCKS 4

#define MINIMUM_ZOOM_LEVEL 100000

@implementation MKMapView (ZoomLevel)

- (void)setZoomLevel:(double)zoomLevel {
	[self setCenterCoordinate:self.centerCoordinate zoomLevel:zoomLevel animated:NO];
}

- (CGFloat)zoomLevel {
	return log2(360 * ((self.frame.size.width/256) / self.region.span.longitudeDelta)) + 1;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
				  zoomLevel:(double)zoomLevel animated:(BOOL)animated {
	MKCoordinateSpan span = MKCoordinateSpanMake(0, 360/pow(2, zoomLevel)*self.frame.size.width/256);
	[self setRegion:MKCoordinateRegionMake(centerCoordinate, span) animated:animated];
}

@end

@interface MapController () <GMSMapViewDelegate,NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate>
{
    CustomClusterManager *clusterManager_;
    BOOL firstLocationUpdate_;
    GMSCameraPosition *previousCameraPosition;

    
}
@property (nonatomic,strong) NSMutableDictionary *markers;
@property (nonatomic, weak) InfoView *selectedInfoView;
@property (nonatomic,strong) NSMutableDictionary *icons;
@property (nonatomic,strong) NSMutableDictionary *colorsForOverlays;
@property (nonatomic,strong) NSString *searchText;
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
        self.colorsForOverlays=[[NSMutableDictionary alloc] initWithCapacity:5];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinsChanged:) name:@"ICPinsChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchChanged:) name:@"ICSearch" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsChanged:) name:@"ICPinColors" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapSettingsChanged:) name:@"ICMapSettings" object:nil];
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(territoriesChanged:) name:@"ICTerritories" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:@"ICLogOut" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setMapPositionAfterAddPin:) name:@"SetMapPositionAfterAddPin" object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect f=self.view.bounds;
    
    _mapview = [[REVClusterMapView alloc] initWithFrame:f];
    _mapview.delegate = self;
    BOOL satellite=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
    _mapview.mapType=satellite?MKMapTypeSatellite:MKMapTypeStandard;
    _mapview.showsUserLocation = YES;
    [self.view addSubview:_mapview];
    
    [_mapview addAnnotations:nil];
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
																		  action:@selector(tapOnMapView:)];
	tap.numberOfTapsRequired = 1;
	tap.numberOfTouchesRequired = 1;
	[_mapview addGestureRecognizer:tap];
	tap.delegate = self;
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
		[_mapview setCenterCoordinate:location.coordinate zoomLevel:14 animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self refresh];
    [self refreshTerritories];
}

- (UIImage*)iconForPin:(Pin*)pin {

    if(!_icons[pin.status]){
        _icons[pin.status]=[GMSMarker markerImageWithColor:[[Pins sharedInstance] colorForStatus:pin.status]];
    }
    return _icons[pin.status];
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

- (void)drawPolygonsWith:(NSArray*)polygons {
    [_mapview removeOverlays:_mapview.overlays];
    [self.colorsForOverlays removeAllObjects];
    for(Area *a in polygons){
        NSInteger l=[a.vertices count];
        CLLocationCoordinate2D *coords=malloc(sizeof(CLLocationCoordinate2D)*l);
        for(int i=0; i<l; ++i){
            coords[i]=CLLocationCoordinate2DMake([a.vertices[i][@"Latitude"] doubleValue],[a.vertices[i][@"Longitude"] doubleValue]);
        }
        MKPolygon *polygon=[MKPolygon polygonWithCoordinates:coords count:l];
        polygon.title=[a.ident stringValue];
        self.colorsForOverlays[polygon.title]=a.color;
        [_mapview addOverlay:polygon];
        free(coords);
    }
}

- (void)refreshMarkers {
    
    [_markers removeAllObjects];
    
    NSMutableArray *tempPlaces=[[NSMutableArray alloc] initWithCapacity:0];
    for(Pin *pin in _filtered) {
        
        REVClusterPin *place = [[REVClusterPin alloc] init];
        place.userData = pin;
        place.title = [NSString stringWithFormat:@"%@ %@",pin.location.streetNumber, pin.location.streetName];
        place.subtitle = @"";
        place.coordinate = CLLocationCoordinate2DMake([pin.latitude doubleValue], [pin.longitude doubleValue]);
        place.image = [self iconForPin:pin];
        [tempPlaces addObject:place];
        
        self.markers[pin.ident]=place;
    }

    [_mapview addAnnotations:tempPlaces];
    
}

- (void)viewOnMap:(Pin*)pin {
    
    [self performSelector:@selector(openCallout:)
               withObject:_markers[pin.ident]
               afterDelay:0.5];
    
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
        } else {
            weakSelf.pins=a;
        }
		
        weakSelf.filtered=_pins;
        [weakSelf refreshMarkers];
    }];
}

- (void)refreshTerritories {
    NSLog(@"%s",__FUNCTION__);
    __weak typeof(self) weakSelf = self;
    [[Territories sharedInstance] sendTerritoriesTo:^(NSArray *a) {
        [weakSelf drawPolygonsWith:a];
    }];
}

#pragma mark - Notifications
- (void)setMapPositionAfterAddPin:(NSNotification*)notification {
	NSNumber *lonNumber = [notification.userInfo objectForKey:@"lon"];
	NSNumber *latNumber = [notification.userInfo objectForKey:@"lat"];
	double lon = [lonNumber doubleValue];
	double lat = [latNumber doubleValue];
	CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat,lon);
	[_mapview setCenterCoordinate:coordinate animated:YES];
}

- (void)colorsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [_icons removeAllObjects];
    [self refresh];
}
- (void)searchChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [self refresh];
}

- (void)pinsChanged:(NSNotification*)notification {
	NSLog(@"%s",__FUNCTION__);
	[self refresh];
}

- (void)userLoggedOut:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
}

- (void)mapSettingsChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    BOOL satellite=[[[NSUserDefaults standardUserDefaults] objectForKey:@"Satellite"] boolValue];
    _mapview.mapType=satellite?MKMapTypeSatellite:MKMapTypeStandard;
}

- (void)territoriesChanged:(NSNotification*)notification {
    NSLog(@"%s",__FUNCTION__);
    [self refreshTerritories];
}

#pragma mark -
#pragma mark Map view delegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolygon class]]){
        MKPolygon *p=(MKPolygon*)overlay;
        MKPolygonRenderer *renderer=[[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon*)overlay];
        renderer.fillColor=[self.colorsForOverlays[p.title] colorWithAlphaComponent:0.2];
        renderer.strokeColor=[self.colorsForOverlays[p.title] colorWithAlphaComponent:0.7];
        renderer.lineWidth=2;
        return renderer;
    }
    
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if([annotation class] == MKUserLocation.class) {

		return nil;
	}
    
    REVClusterPin *pin = (REVClusterPin *)annotation;
    
    MKAnnotationView *annView;
    
    if( [pin nodeCount] > 0 ){
        pin.title = @"___";
        
        annView = (REVClusterAnnotationView*)
        [mapView dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
        
        if( !annView )
            annView = (REVClusterAnnotationView*)
            [[REVClusterAnnotationView alloc] initWithAnnotation:annotation
                                                  reuseIdentifier:@"cluster"];
        
        annView.image = [UIImage imageNamed:@"cluster"];
        
        [(REVClusterAnnotationView*)annView setClusterText:
         [NSString stringWithFormat:@"%i",[pin nodeCount]]];
        
        annView.canShowCallout = NO;
    } else {
		annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
		
        annView.image = pin.image;
        annView.canShowCallout = NO;
        [annView setSelected:YES animated:YES];
        annView.calloutOffset = CGPointMake(-6.0, 0.0);
    }
    return annView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(REVClusterAnnotationView *)view1 {
	
    NSLog(@"REVMapViewController mapView didSelectAnnotationView:");
    
	if ([view1 isKindOfClass:[REVClusterAnnotationView class]]) {
        return;
	}
	if ([view1.annotation isKindOfClass:[MKUserLocation class]]) {
		return;
	}
	[self closeCalloutView];
    REVClusterPin *pin1 = (REVClusterPin *)view1.annotation;
    
	InfoView *infoView = [InfoView loadInfoView];
	[infoView setPin:pin1];
    CGRect calloutViewFrame = infoView.frame;
    calloutViewFrame.origin = CGPointMake(-calloutViewFrame.size.width/2 + 15, -calloutViewFrame.size.height);
    infoView.frame = calloutViewFrame;
    [view1 addSubview:infoView];
	self.selectedInfoView = infoView;
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    
    CGPoint touchLocation = [anntouch locationInView:view];
    
    for (UIView *subview in view.subviews ){
		if ([subview isKindOfClass:[InfoView class]] && CGRectContainsPoint(subview.frame, touchLocation)) {
			Pin *pin= ((InfoView*)subview).pin.userData;
			[self performSegueWithIdentifier:@"MapViewPin" sender:pin];
			[[TutorialViewController shared] dismissCurrentTip];
		}
        [subview removeFromSuperview];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    anntouch = [touches anyObject];
}


- (void) openPinDetail:(myButton *)sender {
    
    Pin *pin=sender.userData;
    [self performSegueWithIdentifier:@"MapViewPin" sender:pin];
}

- (void)openCallout:(id <MKAnnotation>)annotation {
    
    CLLocationDistance distance = 1.0;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, distance, distance);
    [_mapview setRegion:region animated:YES];
    [_mapview deselectAnnotation:annotation
                               animated:NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [_mapview selectAnnotation:annotation animated:YES];
    });
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchText=searchText;
    [self filterArray];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    self.searchText=nil;
    [self filterArray];
    [searchBar resignFirstResponder];
}

#pragma mark - API
-(void)closeCalloutView {
	if (self.selectedInfoView) {
		[self.selectedInfoView removeFromSuperview];
	}
}

-(void)setFiltered:(NSArray *)filtered {
	[[Pins sharedInstance] filteredPinsWithArray: filtered];
	_filtered = filtered;
}

- (void)setLocation:(CLLocation *)location {
    NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
    _location=location;
	MKMapCamera *camera = _mapview.camera;
	camera.centerCoordinate = location.coordinate;
	_mapview.camera = camera;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailsViewController *dc=(DetailsViewController*)[segue destinationViewController];
    dc.pin=sender;
}


- (void)tapOnMapView:(UITapGestureRecognizer*)tap {
	if (self.selectedInfoView) {
		CGPoint touchPointInInfoView = [tap locationInView:self.selectedInfoView];
		if (CGRectContainsPoint(self.selectedInfoView.bounds, touchPointInInfoView)) {
			Pin *pin = self.selectedInfoView.pin.userData;
			[self performSegueWithIdentifier:@"MapViewPin" sender:pin];
			return;
		}
	}
	CGPoint touchPoint = [tap locationInView:_mapview];
	CLLocationCoordinate2D touchMapCoordinate =
	[_mapview convertPoint:touchPoint toCoordinateFromView:_mapview];
	if ([self.delegate respondsToSelector:@selector(mapController:didSelectBuildingAtCoordinate:)]) {
		[self.delegate mapController:self didSelectBuildingAtCoordinate:touchMapCoordinate];
	}
	[self closeCalloutView];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
		&& [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
		return YES;
	}
	return NO;
}

- (void)setCenterLocation:(CLLocationCoordinate2D)location zoomLavel:(double)zoomLavel {
	[_mapview setCenterCoordinate:location zoomLevel:zoomLavel animated:NO];
}

@end
