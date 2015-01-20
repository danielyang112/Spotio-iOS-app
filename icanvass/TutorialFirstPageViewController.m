//
//  TutorialFirstPageViewController.m
//  icanvass
//
//  Created by mobidevM199 on 16.11.14.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "TutorialFirstPageViewController.h"
#import "TutorialSecondPageViewController.h"
//#import "FingerAnimation.h"

@interface TutorialFirstPageViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *smallWhiteViews;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *icons;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *internalBorderedViews;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *topLabels;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *bottomLabels;
@end

@implementation TutorialFirstPageViewController

#pragma mark - lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background_texture"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self runAnimation];
}

-(void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self initializeViews];
}

#pragma mark - initialize

- (void)initializeViews {
	for (UIView *smallView in self.smallWhiteViews) {
		smallView.layer.cornerRadius = smallView.frame.size.height /  2.0;
		smallView.hidden = YES;
	}

	for (UIView *iconView in self.icons) {
		iconView.layer.cornerRadius = iconView.frame.size.height / 2.0;
		iconView.hidden = YES;
	}

	for (UIView *borderedView in self.internalBorderedViews) {
		borderedView.layer.borderWidth = 1.0;
		borderedView.layer.borderColor = [UIColor whiteColor].CGColor;
		borderedView.layer.cornerRadius = borderedView.frame.size.height / 2.0;
		borderedView.hidden = YES;
	}

	for (UIView *topLabel in self.topLabels) {
		topLabel.alpha = 0.0;
		topLabel.transform = CGAffineTransformMakeTranslation(-10.0, 0.0);
	}

	for (UIView *bottomLabel in self.bottomLabels) {
		bottomLabel.alpha = 0.0;
		bottomLabel.transform = CGAffineTransformMakeTranslation(-15.0, 0.0);
	}
}

#pragma mark - animations

- (void)runAnimation {
	__weak typeof(self) weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[weakSelf run];
	});

}

- (void)run {
	for (NSInteger i=0; i < 3; i++) {
		__weak typeof(self) weakSelf = self;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i*0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[weakSelf runAnimationAtIndex:i];
		});
	}
}

- (void)runAnimationAtIndex:(NSInteger)index {
	[self runFirstPathAnimationAtIndex:index withCompletion:^(BOOL finished) {
		const UIView *icon = [self iconAtIndex:index];
		icon.hidden = NO;
		const UIView *borderedView = [self internalBorderedViewAtIndex:index];
		borderedView.hidden = NO;
		[self runSecondPathAnimationAtIndex:index];
		[self runTopLabelAnimationAtIndex:index];
		[self runBottomLabelAnimationAtIndex:index];
	}];
}

- (void)runFirstPathAnimationAtIndex:(NSInteger)index withCompletion:(void(^)(BOOL finished))completion {
	const UIView *smallView = [self smallWhiteViewWithIndex:index];
	smallView.transform = CGAffineTransformMakeScale(0.0, 0.0);
	smallView.hidden = NO;
	[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		smallView.transform = CGAffineTransformIdentity;
	} completion:completion];
}

- (void)runSecondPathAnimationAtIndex:(NSInteger)index {
	const UIView *smallView = [self smallWhiteViewWithIndex:index];
	[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		smallView.alpha = 0.0;
		smallView.transform = CGAffineTransformMakeScale(0.1, 0.1);
	} completion:^(BOOL finished) {
		smallView.transform = CGAffineTransformIdentity;
		smallView.alpha = 1.0;
		smallView.hidden = YES;
	}];
}

- (void)runTopLabelAnimationAtIndex:(NSInteger)index {
	const UIView *topLabel = [self topLabelAtIndex:index];
	[UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		topLabel.transform = CGAffineTransformIdentity;
		topLabel.alpha = 1.0;
	} completion:nil];
}

- (void)runBottomLabelAnimationAtIndex:(NSInteger)index {
	const UIView *bottomLabel = [self bottomLabelAtIndex:index];
	[UIView animateWithDuration:0.8 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		bottomLabel.alpha = 1.0;
		bottomLabel.transform = CGAffineTransformIdentity;
	} completion:nil];
}

#pragma mark - helpers

- (UIView*)smallWhiteViewWithIndex:(NSInteger) index {
	return [self viewFromArray:self.smallWhiteViews tag:index];
}

- (UIView*)iconAtIndex:(NSInteger)index {
	return [self viewFromArray:self.icons tag:index];
}

- (UIView*)internalBorderedViewAtIndex:(NSInteger)index {
	return [self viewFromArray:self.internalBorderedViews tag:index];
}

- (UIView*)topLabelAtIndex:(NSInteger)index {
	return [self viewFromArray:self.topLabels tag:index];
}

- (UIView*)bottomLabelAtIndex:(NSInteger)index {
	return [self viewFromArray:self.bottomLabels tag:index];
}

- (UIView*)viewFromArray:(NSArray*)array tag:(NSInteger)tag {
	for (UIView *view in array) {
		if (view.tag == tag) {
			return view;
		}
	}
	return nil;
}

#pragma mark - handle user actions

- (IBAction)onNext:(id)sender {
	if (self.onContinue) {
		self.onContinue();
	}
}

@end
