//
//  PinTemp.h
//  icanvass
//
//  Created by Roman Kot on 17.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationTemp : NSObject

@property (nonatomic, strong) NSString *streetName;
@property (nonatomic, strong) NSString *streetNumber;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic, strong) NSString *zip;

@end

@interface PinTemp : NSObject

- (void)updateWithDictionary:(NSDictionary*)dic;
- (PinTemp*)initWithDictionary:(NSDictionary*)dic;

@property (nonatomic, strong) NSString *ident;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSDictionary *clientData;
@property (nonatomic, strong) NSString *notes;
@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *updateDate;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) LocationTemp *location;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *address2;
@property (nonatomic, strong) NSArray *customValues;
+ (NSString*)formatDate:(NSDate*)date;

@end
