//
//  HilightedButton.m
//  icanvass
//
//  Created by Roman Kot on 22.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "HilightedButton.h"

@implementation HilightedButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha=highlighted?0.5f:1.f;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
