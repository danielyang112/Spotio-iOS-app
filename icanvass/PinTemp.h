//
//  PinTemp.h
//  icanvass
//
//  Created by Roman Kot on 17.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationTemp : NSObject

@property (nonatomic, retain) NSString *streetName;
@property (nonatomic, retain) NSString *streetNumber;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *unit;
@property (nonatomic, retain) NSString *zip;

@end

@interface PinTemp : NSObject

- (PinTemp*)initWithDictionary:(NSDictionary*)dic;

@property (nonatomic, retain) NSString *ident;
@property (nonatomic, retain) NSDictionary *clientData;
@property (nonatomic, retain) NSString *notes;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSDate *creationDate;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) LocationTemp *location;
@property (nonatomic, retain) NSString *address;

@end
