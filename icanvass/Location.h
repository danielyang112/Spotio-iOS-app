//
//  Location.h
//  icanvass
//
//  Created by Roman Kot on 19.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Pin;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * streetName;
@property (nonatomic, retain) NSNumber * streetNumber;
@property (nonatomic, retain) NSString * unit;
@property (nonatomic, retain) NSString * zip;
@property (nonatomic, retain) Pin *pin;

@end
