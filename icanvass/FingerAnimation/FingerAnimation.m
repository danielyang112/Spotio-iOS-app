//
//  FingerAnimation.m
//  icanvass
//

#import "FingerAnimation.h"

@interface FingerAnimation()

@property (weak, nonatomic) IBOutlet UIImageView *fingerView;
@property (assign, nonatomic) CGFloat centerShift;

@end

@implementation FingerAnimation

+ (instancetype)addAnimationToView:(UIView*)view
						atPosition:(CGPoint)position {
	return [self addAnimationToView:view atPosition:position reflected:NO];
}

+ (instancetype)addAnimationToView:(UIView*)view
						atPosition:(CGPoint)position
						 reflected:(BOOL)reflected {
	const UINib *fingerNib = [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
	FingerAnimation *fingerView = (FingerAnimation*)[fingerNib instantiateWithOwner:nil options:nil].firstObject;
	[view addSubview:fingerView];

	fingerView.centerShift = 40;
	fingerView.center = CGPointMake(position.x + (reflected ? -fingerView.centerShift : fingerView.centerShift), position.y + fingerView.centerShift);
	[fingerView startAnimation];
	if (reflected) {
		fingerView.transform = CGAffineTransformMakeScale(-1, 1);
	}
	return fingerView;
}

- (void)startAnimation {
	__weak typeof(self) weakSelf = self;
	[self tapFingerAnimationWithCompletion:^{
		for (int i=0; i<3; i++) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[weakSelf startShapesAnimation];
			});
		}
		[UIView animateWithDuration:0.4 animations:^{
			weakSelf.fingerView.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
			if (finished) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					[weakSelf startAnimation];
				});
			}
		}];
	}];
}


- (void)tapFingerAnimationWithCompletion:(void(^)())completion {
	[UIView animateWithDuration:1.0
					 animations:^{
		 CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.9, 0.9);
		 CGAffineTransform rotationTransform = CGAffineTransformConcat(scaleTransform, CGAffineTransformMakeRotation(-M_PI/10.0));
		 self.fingerView.transform = CGAffineTransformTranslate(rotationTransform, -60.0, -90.0);
	 } completion:
	 ^(BOOL finished) {
		if (completion && finished) {
			completion();
		}
	}];
}

- (void)startShapesAnimation {
	UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
	[self addSubview:blueView];
	blueView.backgroundColor = [UIColor colorWithRed:63./255. green:170./255. blue:240./255. alpha:0.5];
	blueView.layer.cornerRadius = blueView.frame.size.height / 2.0 ;
	blueView.center = CGPointMake(self.frame.size.width / 2.0 - self.centerShift, self.frame.size.height / 2.0 - self.centerShift);
	blueView.transform = CGAffineTransformMakeScale(0.3, 0.3);
	blueView.alpha = 0.5;
	[UIView animateWithDuration:0.2 animations:^{
		blueView.alpha = 1.0;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.4 delay:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
			blueView.alpha = 0.0;
		} completion:^(BOOL finished) {
			[blueView removeFromSuperview];
		}];
		[UIView animateWithDuration:0.5 animations:^{
			blueView.transform = CGAffineTransformIdentity;
		} completion:nil];
	}];
}

@end
