//
//  DetailsViewController.h
//  icanvass
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import <MapKit/MapKit.h>
#import "Pin.h"

@interface DetailsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationCoordinate2D userCoordinate;
@property (nonatomic) BOOL adding;
@property (nonatomic) BOOL isAddEmpty;
@property (nonatomic,strong) Pin *pin;
@property (weak, nonatomic) IBOutlet UIStepper *numberStepper;
@property (weak, nonatomic) IBOutlet UITextField *cityStateZipTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)status:(id)sender;
- (IBAction)viewOnMap:(id)sender;
- (IBAction)edit:(id)sender;

@end
