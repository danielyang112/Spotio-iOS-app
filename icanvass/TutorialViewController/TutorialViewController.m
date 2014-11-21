//
//  TutorialViewController.m
//  icanvass
//

#import "TutorialViewController.h"
#import "TutorialFirstPageViewController.h"
#import <MDCFocusView.h>
#import <MDCSpotlightView.h>
#import "FingerAnimation.h"

__weak static TutorialViewController *shared = nil;

@protocol TutorialWindowDelegate <NSObject>

- (BOOL)canHitPoint:(CGPoint)point;

@end

@interface TutorialWindow : UIWindow

@property (nonatomic, weak) id<TutorialWindowDelegate> tutorialDelegate;

@end

@implementation TutorialWindow

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	if (self.tutorialDelegate) {
		return [self.tutorialDelegate canHitPoint:point] ? [super hitTest:point withEvent:event] : nil;
	}
	return [super hitTest:point withEvent:event];
}

@end

@interface TutorialViewController ()<TutorialWindowDelegate>

@property (strong, nonatomic) TutorialWindow *parentWindow;
@property (strong, nonatomic) TutorialFirstPageViewController *firstPage;
@property (strong, nonatomic) MDCFocusView *focusView;
@property (weak, nonatomic) IBOutlet UIView *mapFocusedView;
@property (weak, nonatomic) IBOutlet UIView *selectStatusView;
@property (weak, nonatomic) IBOutlet UIView *actionSheetView;
@property (weak, nonatomic) IBOutlet UIView *doneView;
@property (assign, nonatomic) BOOL isShowTips;
@property (weak, nonatomic) UIView *lastFocusView;
@property (weak, nonatomic) IBOutlet UIButton *skipBtn;

@property (weak, nonatomic) IBOutlet UILabel *tapToAddYourFirstPin;
@property (weak, nonatomic) IBOutlet UILabel *setStatusOfProspect;
@property (weak, nonatomic) IBOutlet UILabel *congratulations;
@property (weak, nonatomic) IBOutlet UILabel *youJustCreatedYourFirstPin;
@property (weak, nonatomic) IBOutlet UILabel *createYourFirstPin;
@property (weak, nonatomic) IBOutlet UILabel *tapToSetYourProspect;

@property (weak, nonatomic) UILabel *currentTappedLabel;
@property (weak, nonatomic) UIView *fingerAnimation;

@property (assign, nonatomic) BOOL skipInProgress;

@end

@implementation TutorialViewController

+ (void)showTutorial {
	TutorialWindow *parentWindow = [[TutorialWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	parentWindow.windowLevel = UIWindowLevelAlert + 150;
	parentWindow.backgroundColor = [UIColor clearColor];
	[parentWindow makeKeyAndVisible];
	parentWindow.userInteractionEnabled = YES;
	TutorialViewController *tutorial = [self new];
	shared = tutorial;
	parentWindow.rootViewController = tutorial;
	tutorial.parentWindow = parentWindow;
	parentWindow.tutorialDelegate = tutorial;

	if (IS_OS_8_OR_LATER) {
		TutorialFirstPageViewController *firstPage = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TutorialFirstPageViewController"];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[tutorial presentViewController:firstPage animated:YES completion:nil];
		});
		tutorial.firstPage = firstPage;
		__weak typeof(tutorial) tutorialWeak = tutorial;
		firstPage.onContinue = ^{
			[tutorialWeak dissmissFirstPage];
		};
	} else {

		[tutorial dissmissFirstPage];
	}

}

+ (instancetype)shared {
	return shared;
}

- (void)showMapTip {
	self.focusView.focalPointViewClass = [MDCSpotlightView class];
	[self.focusView focus:self.mapFocusedView, nil];
	self.fingerAnimation = [FingerAnimation addAnimationToView:self.view atPosition:self.mapFocusedView.center];
	self.lastFocusView = self.mapFocusedView;
	[self.parentWindow bringSubviewToFront:self.view];

	self.currentTappedLabel = self.tapToAddYourFirstPin;
}

- (void)showSelectStatusTip {
	self.focusView.focalPointViewClass = [MDCFocalPointView class];
	[self.focusView focus:self.selectStatusView, nil];
	self.fingerAnimation = [FingerAnimation addAnimationToView:self.view atPosition:self.selectStatusView.center];

	self.lastFocusView = self.selectStatusView;

	[self.parentWindow bringSubviewToFront:self.view];
	self.currentTappedLabel = self.tapToSetYourProspect;
}

- (void)showActionSheetTip {
	self.focusView.focalPointViewClass = [MDCFocalPointView class];
	[self.focusView focus:self.actionSheetView, nil];
	self.fingerAnimation = [FingerAnimation addAnimationToView:self.view atPosition:self.actionSheetView.center];
	self.lastFocusView = self.actionSheetView;
	[self.parentWindow bringSubviewToFront:self.view];
	self.currentTappedLabel = self.setStatusOfProspect;
}

- (void)showDoneTip {
	self.focusView.focalPointViewClass = [MDCSpotlightView class];
	[self.focusView focus:self.doneView, nil];
	self.fingerAnimation = [FingerAnimation addAnimationToView:self.view atPosition:self.doneView.center reflected:YES];
	self.lastFocusView = self.doneView;
	[self.parentWindow bringSubviewToFront:self.view];
	self.currentTappedLabel = self.createYourFirstPin;
}

- (void)showFinalTip {
	self.focusView.focalPointViewClass = [MDCSpotlightView class];
	[self.focusView focus:self.mapFocusedView, nil];
	self.lastFocusView = nil;

	[self.parentWindow bringSubviewToFront:self.view];
	self.congratulations.hidden = NO;
	self.youJustCreatedYourFirstPin.hidden = NO;
	__weak typeof(self) weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[weakSelf skipTips];
	});
}

-(void)setCurrentTappedLabel:(UILabel *)currentTappedLabel {
	_currentTappedLabel = currentTappedLabel;
	_currentTappedLabel.hidden = NO;
}

- (void)dismissCurrentTip {
	[self.focusView removeFromSuperview];
	self.focusView = nil;
	self.currentTappedLabel.hidden = YES;
	[self.fingerAnimation removeFromSuperview];
	[UIView animateWithDuration:0.2 animations:^{
		self.lastFocusView.alpha = 0.0;
	}];
}

- (void)setLastFocusView:(UIView *)lastFocusView {
	_lastFocusView = lastFocusView;
	[UIView animateWithDuration:0.2 animations:^{
		_lastFocusView.alpha = 1.0;
	}];
}

- (void)dismissCurrentTipCompletion:(void(^)())completion {
	if (!self.focusView.focused) {
		return;
	}
	[self.focusView dismiss:^{
		if (completion != nil) {
			completion();
		}
	}];
}

- (MDCFocusView *)focusView {
	if (_focusView == nil) {
		_focusView = [MDCFocusView new];
		_focusView.backgroundColor = [UIColor colorWithRed:0.0078f green:0.0078f blue:0.0078f alpha:0.8];
		_focusView.userInteractionEnabled = NO;
	}
	return _focusView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dissmissFirstPage {
	if (self.firstPage) {
		[self.firstPage dismissViewControllerAnimated:YES completion:^{
			self.firstPage = nil;
			[self showMapTip];
			self.isShowTips = YES;
		}];
	} else {
		[self showMapTip];
		self.isShowTips = YES;
	}
}

- (void)skipTips {
	if (self.skipInProgress) {
		return;
	}
	self.skipInProgress = YES;
	if([self.focusView isFocused]) {
		[self.focusView dismiss:^{
			self.parentWindow.rootViewController = nil;
			self.parentWindow = nil;
		}];
	} else {
		self.parentWindow.rootViewController = nil;
		self.parentWindow = nil;
	}
	shared = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TutorialViewSkipTips" object:nil];
}

- (IBAction)skip:(id)sender {
	[self skipTips];
}

- (BOOL)canHitPoint:(CGPoint)point {
	if (self.isShowTips) {
		if (CGRectContainsPoint(self.skipBtn.frame, point)) {
			return YES;
		}
		if (CGRectContainsPoint(self.lastFocusView.frame, point)) {
			return NO;
		}
	}
	return YES;
}

- (void)hide {
	self.parentWindow.alpha = 0.0;
	self.parentWindow.userInteractionEnabled = NO;
}

- (void)showFromPrevious {
	self.parentWindow.alpha = 1.0;
	self.parentWindow.userInteractionEnabled = YES;
}

@end
