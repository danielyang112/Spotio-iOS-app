//
//  CustomValue.h
//  icanvass
//
//  Created by Roman Kot on 20.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Pin;

@interface CustomValue : NSManagedObject

@property (nonatomic, retain) NSString * dateTimeValue;
@property (nonatomic, retain) NSString * decimalValue;
@property (nonatomic, retain) NSNumber * definitionId;
@property (nonatomic, retain) NSNumber * ident;
@property (nonatomic, retain) NSNumber * intValue;
@property (nonatomic, retain) NSString * stringValue;
@property (nonatomic, retain) NSString * json;
@property (nonatomic, retain) Pin *pin;

- (void)updateWithDictionary:(NSDictionary*)dic;
- (NSDictionary*)dict;

@end
