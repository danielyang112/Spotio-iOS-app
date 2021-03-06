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
@property (nonatomic,strong) NSMutableArray *pins;
@property (nonatomic,strong) NSDate *oldest;
@property (nonatomic,strong) NSDate *newest;
@property (nonatomic,strong) NSDictionary *filter;
@property (nonatomic,strong) NSString *searchText;
@property (nonatomic,strong) NSFetchedResultsController* fetchController;

+ (Pins*)sharedInstance;
- (void)sendPinsTo:(void (^)(NSArray *a))block;
- (void)sendStatusesTo:(void (^)(NSArray *a))block failure:(void (^)(NSError *error))failure;
- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(NSError *error))block;
- (void)editPin:(Pin*)pin withDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block;
- (void)deletePin:(Pin*)pin block:(void (^)(BOOL success))block;
- (UIColor*)colorForStatus:(NSString*)status;
- (void)clear;
- (void)fetchPinsWithBlock:(void (^)(NSArray *a))block;
- (void)fetchPinsWithParameteres:(NSDictionary*)parameteres block:(void (^)(NSArray *a))block;
- (void)fetchPinsFromCoreDataWithPredicate:(NSPredicate*)predicate;
- (void)fetchPinsFromCoreData;
+ (NSOperationQueue*)operationQueue;
-(void) filteredPinsWithArray:(NSArray*) filteredPins;
-(NSArray*) filteredPinsArray;
@end
