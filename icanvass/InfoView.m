//
//  InfoView.m
//
//

#import "InfoView.h"
#import "myButton.h"
#import "Pin.h"
#import "Pins.h"
#import "Users.h"
#import "REVClusterPin.h"

@interface InfoView ()

@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *address2;
@property (weak, nonatomic) IBOutlet UIView *statusView;

@end

@implementation InfoView

+ (instancetype)loadInfoView {
	UINib *nib = [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
	InfoView *infoView = [nib instantiateWithOwner:self options:nil].firstObject;
	return infoView;
}

-(void)awakeFromNib {
	self.statusView.layer.borderColor = [UIColor darkGrayColor].CGColor;
	self.statusView.layer.borderWidth = 1.f;

	self.layer.masksToBounds = NO;
	self.layer.shadowOffset = CGSizeMake(-5, 5);
	self.layer.shadowRadius = 3;
	self.layer.shadowOpacity = 0.8;
	self.layer.borderWidth = 1.f;
	self.layer.borderColor = [UIColor darkGrayColor].CGColor;
}

- (void)setPin:(REVClusterPin*)pin {
	_pin = pin;
	Pin *pinData = pin.userData;
	self.status.text = pinData.status;
	self.userName.text = [[Users sharedInstance] fullNameForUserName:pinData.user];
	self.date.text = [Pin formatDate:pinData.updateDate];
	self.address.text = pinData.address;
	self.address2.text = pinData.address2;
	self.statusView.backgroundColor = [[Pins sharedInstance] colorForStatus:pinData.status];
}

@end
