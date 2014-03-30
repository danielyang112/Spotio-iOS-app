//
//  PinTemp.m
//  icanvass
//
//  Created by Roman Kot on 17.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "PinTemp.h"

@implementation LocationTemp

@end

@implementation PinTemp

- (void)updateWithDictionary:(NSDictionary*)dic {
    self.ident=dic[@"Id"];
    self.user=dic[@"UserName"];
    self.status=dic[@"Status"];
    NSString *noMilliseconds=[dic[@"CreationDate"] componentsSeparatedByString:@"."][0];
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    }
    self.creationDate=[dateFormatter dateFromString:noMilliseconds];
    self.latitude=dic[@"Latitude"];
    self.longitude=dic[@"Longitude"];
    LocationTemp *loc=[LocationTemp new];
    NSDictionary *ld=dic[@"Location"];
    NSArray *a=[self addressComponents:ld[@"Address"]];
    loc.streetNumber=a[0];
    loc.streetName=a[1];
    loc.city=ld[@"City"];
    loc.unit=ld[@"Unit"];
    loc.zip=ld[@"Zip"];
    loc.state=ld[@"State"];
    self.location=loc;
}

- (PinTemp*)initWithDictionary:(NSDictionary*)dic {
    self=[super init];
    if(self) {
        [self updateWithDictionary:dic];
    }
    return self;
}

- (NSArray*)addressComponents:(NSString*)address {
    NSArray *a=[address componentsSeparatedByString:@"\n"];
    if([a count]<2) {
        a=@[@"",a[0]];
    }
    return a;
}

- (NSString*)address {
    if(!_address) {
        _address=[NSString stringWithFormat:@"%@ %@",self.location.streetNumber, self.location.streetName];
    }
    return _address;
}

- (NSString*)address2 {
    if(!_address2) {
        _address2=[NSString stringWithFormat:@"%@ %@, %@",self.location.city, self.location.state, self.location.zip];
    }
    return _address2;
}

+ (NSString*)formatDate:(NSDate*)date {
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        dateFormatter.dateFormat=@"MM/dd/yy";
    }
    return [dateFormatter stringFromDate:date];
}

@end
