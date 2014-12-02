//
//  Pin.m
//  icanvass
//
//  Created by Roman Kot on 19.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "Pin.h"
#import "CustomValue.h"
#import "Location.h"
#import "utilities.h"
#import "Fields.h"


@implementation Pin

@dynamic creationDate;
@dynamic ident;
@dynamic latitude;
@dynamic longitude;
@dynamic status;
@dynamic updateDate;
@dynamic user;
@dynamic userLatitude;
@dynamic userLongitude;
@dynamic customValues;
@dynamic location;

@synthesize address;
@synthesize address2;
@synthesize sortAddress;

- (void)updateWithDictionary:(NSDictionary*)dic {
    self.ident=dic[@"Id"];
    self.user=dic[@"UserName"];
    self.status=nilIfNull(dic[@"Status"]);
    NSString *noMilliseconds=[dic[@"CreationDate"] componentsSeparatedByString:@"."][0];
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [dateFormatter setTimeZone:gmt];
    }
    self.creationDate=[dateFormatter dateFromString:noMilliseconds];
    if(nilIfNull(dic[@"UpdateDate"])){
        noMilliseconds=[dic[@"UpdateDate"] componentsSeparatedByString:@"."][0];
    }
    self.updateDate=[dateFormatter dateFromString:noMilliseconds];
    NSNumber *lat=[NSNumber numberWithDouble:[nilIfNull(dic[@"Latitude"]) doubleValue]];
    self.latitude=lat;
    NSNumber *lon=[NSNumber numberWithDouble:[nilIfNull(dic[@"Longitude"]) doubleValue]];
    self.longitude=lon;
}

- (NSString*)address {
    if(!address) {
        address=[NSString stringWithFormat:@"%@ %@",self.location.streetNumber, self.location.streetName];
    }
    return address;
}

- (NSString*)sortAddress {
    if(!sortAddress) {
        sortAddress=[NSString stringWithFormat:@"%@ %@",self.location.streetName,self.location.streetNumber];
    }
    return sortAddress;
}

- (NSString*)address2 {
    if(!address2) {
        NSMutableArray *parts=[@[] mutableCopy];
        if(self.location.city) [parts addObject:self.location.city];
        if(self.location.state) [parts addObject:self.location.state];
        if(self.location.zip) [parts addObject:self.location.zip];
        address2=[parts componentsJoinedByString:@", "];
    }
    return address2;
}

+ (NSString*)formatDate:(NSDate*)date {
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter)
    {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat=@"MM/dd/yy\nhh:mm a";
    }
    return [dateFormatter stringFromDate:date];
}

- (NSArray*)customValuesOld {
    NSMutableArray *ma=[NSMutableArray arrayWithCapacity:[self.customValues count]];
    for(CustomValue *cv in self.customValues)
    {
        [ma addObject:[cv dict]];
    }
	
	[ma sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSDictionary *a=(NSDictionary*)obj1;
		NSDictionary *b=(NSDictionary*)obj2;
		
		int idA = [a[@"DefinitionId"] integerValue];
		int idB = [b[@"DefinitionId"] integerValue];
		
		if(idA > idB){
			return NSOrderedDescending;
		}
		return NSOrderedAscending;
	}];
	
    return [NSArray arrayWithArray:ma];
}

@end
