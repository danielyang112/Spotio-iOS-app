//
//  Pin.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Pin : NSManagedObject

@property (nonatomic, retain) NSString * ident;
@property (nonatomic, retain) id clientData;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * userLatitude;
@property (nonatomic, retain) NSNumber * userLongitude;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSDate * dateTimeInputted;
@property (nonatomic, retain) NSManagedObject *location;
@property (nonatomic, retain) NSManagedObject *user;
@property (nonatomic, retain) NSManagedObject *status;

@end
