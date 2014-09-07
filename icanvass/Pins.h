//
//  Pins.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import <Foundation/Foundation.h>
#import "Pin.h"

@interface Pins : NSObject
@property (nonatomic,strong) NSArray *pins;
@property (nonatomic,strong) NSDate *oldest;
@property (nonatomic,strong) NSDate *newest;
@property (nonatomic,strong) NSDictionary *filter;
@property (nonatomic,strong) NSString *searchText;
+ (Pins*)sharedInstance;
- (void)sendPinsTo:(void (^)(NSArray *a))block;
- (void)sendStatusesTo:(void (^)(NSArray *a))block;
- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block;
- (void)editPin:(Pin*)pin withDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block;
- (UIColor*)colorForStatus:(NSString*)status;
- (void)clear;
- (void)fetchPinsWithBlock:(void (^)(NSArray *a))block;
@end
