//
//  TutorialViewController.h
//  icanvass
//

#import <UIKit/UIKit.h>

@interface TutorialViewController : UIViewController

+ (void)showTutorialWithDidShowCompletion:(void(^)())completion;

+ (instancetype)shared;

- (void)showMapTip;
- (void)showSelectStatusTip;
- (void)showActionSheetTip;
- (void)showDoneTip;
- (void)showFinalTip;

- (void)dismissCurrentTip;

- (void)skipTips;

- (void)hide;
- (void)showFromPrevious;

@end
