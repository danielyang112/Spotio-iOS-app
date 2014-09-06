//
//  Pin.h
//  icanvass
//
//  Created by Roman Kot on 19.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Location.h"
#import "CustomValue.h"

@class CustomValue, Location;

@interface Pin : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * ident;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSDate * updateDate;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSNumber * userLatitude;
@property (nonatomic, retain) NSNumber * userLongitude;
@property (nonatomic, retain) NSOrderedSet *customValues;
@property (nonatomic, retain) Location *location;


@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *sortAddress;
@property (nonatomic, strong) NSString *address2;

- (void)updateWithDictionary:(NSDictionary*)dic;
+ (NSString*)formatDate:(NSDate*)date;

- (NSArray*)customValuesOld;
@end

@interface Pin (CoreDataGeneratedAccessors)

- (void)insertObject:(CustomValue *)value inCustomValuesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCustomValuesAtIndex:(NSUInteger)idx;
- (void)insertCustomValues:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCustomValuesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCustomValuesAtIndex:(NSUInteger)idx withObject:(CustomValue *)value;
- (void)replaceCustomValuesAtIndexes:(NSIndexSet *)indexes withCustomValues:(NSArray *)values;
- (void)addCustomValuesObject:(CustomValue *)value;
- (void)removeCustomValuesObject:(CustomValue *)value;
- (void)addCustomValues:(NSOrderedSet *)values;
- (void)removeCustomValues:(NSOrderedSet *)values;
@end
