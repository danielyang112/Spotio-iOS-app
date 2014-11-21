//
//  Status.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Pin;

@interface Status : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * color;
@property (nonatomic, retain) NSSet *pins;
@end

@interface Status (CoreDataGeneratedAccessors)

- (void)addPinsObject:(Pin *)value;
- (void)removePinsObject:(Pin *)value;
- (void)addPins:(NSSet *)values;
- (void)removePins:(NSSet *)values;

@end
