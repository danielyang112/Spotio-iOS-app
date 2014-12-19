//
//  
//    ___  _____   ______  __ _   _________ 
//   / _ \/ __/ | / / __ \/ /| | / / __/ _ \
//  / , _/ _/ | |/ / /_/ / /_| |/ / _// , _/
// /_/|_/___/ |___/\____/____/___/___/_/|_| 
//
//  Created by Bart Claessens. bart (at) revolver . be
//

#import "REVClusterAnnotationView.h"


@implementation REVClusterAnnotationView

@synthesize coordinate;

- (id) initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if ( self )
    {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
        [self addSubview:label];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:18];
        label.textAlignment = UITextAlignmentCenter;
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0,-1);
    }
    return self;
}

- (void) setClusterText:(NSString *)text
{
    label.text = text;
}

- (void) dealloc
{
    [label release], label = nil;
    [super dealloc];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
	UIView* hitView = [super hitTest:point withEvent:event];
	if (hitView != nil) {
		[self.superview bringSubviewToFront:self];
	}
	return hitView;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
	CGRect rect = self.bounds;
	BOOL isInside = CGRectContainsPoint(rect, point);
	if(!isInside) {
		for (UIView *view in self.subviews) {
			isInside = CGRectContainsPoint(view.frame, point);
			if(isInside)
				break;
		}
	}
	return isInside;
}
@end
