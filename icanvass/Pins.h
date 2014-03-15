//
//  Pins.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import <Foundation/Foundation.h>

@interface Pins : NSObject
+ (Pins*)sharedInstance;
- (void)sendPinsTo:(void (^)(NSArray *a))block;
@end
