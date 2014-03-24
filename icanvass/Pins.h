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
- (void)sendStatusesTo:(void (^)(NSArray *a))block;
- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block;
- (UIColor*)colorForStatus:(NSString*)status;
- (void)clear;
@end
