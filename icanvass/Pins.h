//
//  Pins.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import <Foundation/Foundation.h>
#import "PinTemp.h"

@interface Pins : NSObject
@property (nonatomic,strong) NSDate *oldest;
@property (nonatomic,strong) NSDate *newest;
@property (nonatomic,strong) NSDictionary *filter;
+ (Pins*)sharedInstance;
- (void)sendPinsTo:(void (^)(NSArray *a))block;
- (void)sendStatusesTo:(void (^)(NSArray *a))block;
- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block;
- (void)editPin:(PinTemp*)pin withDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block;
- (UIColor*)colorForStatus:(NSString*)status;
- (void)clear;
@end
