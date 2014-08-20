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

- (NSString*)address2 {
    if(!address2) {
        address2=[NSString stringWithFormat:@"%@, %@, %@",self.location.city, self.location.state, self.location.zip];
    }
    return address2;
}

+ (NSString*)formatDate:(NSDate*)date {
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat=@"MM/dd/yy";
    }
    return [dateFormatter stringFromDate:date];
}

- (NSArray*)customValuesOld {
    NSMutableArray *ma=[NSMutableArray arrayWithCapacity:[self.customValues count]];
    for(CustomValue *cv in self.customValues){
        [ma addObject:[cv dict]];
    }
    return [NSArray arrayWithArray:ma];
}

@end
