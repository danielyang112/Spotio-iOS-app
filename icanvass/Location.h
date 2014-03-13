//
//  Location.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Pin;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSString * streetName;
@property (nonatomic, retain) NSNumber * streetNumber;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * unit;
@property (nonatomic, retain) NSString * zip;
@property (nonatomic, retain) Pin *pin;

@end
