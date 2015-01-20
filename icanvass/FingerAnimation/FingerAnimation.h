//
//  FingerAnimation.h
//  icanvass
//

#import <UIKit/UIKit.h>

@interface FingerAnimation : UIView

+ (instancetype)addAnimationToView:(UIView*)view atPosition:(CGPoint)position;

+ (instancetype)addAnimationToView:(UIView*)view
						atPosition:(CGPoint)position
						 reflected:(BOOL)reflected;
@end
