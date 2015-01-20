//
//  InfoView.h
//  icanvass
//

#import <UIKit/UIKit.h>
@class REVClusterPin;

@interface InfoView : UIView

+ (instancetype)loadInfoView;

@property (nonatomic, strong) REVClusterPin *pin;

@end
