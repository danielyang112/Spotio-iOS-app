//
//  FanOut.h
//  icanvass
//
//  Created by Roman Kot on 21.09.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FanOut : NSObject <UIWebViewDelegate>
+ (FanOut*)sharedInstance;
- (void)subscribe:(NSString*)channel realm:(NSString*)realm;
@end
