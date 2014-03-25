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

- (PinTemp*)initWithDictionary:(NSDictionary*)dic {
    self=[super init];
    if(self) {
        self.ident=dic[@"Id"];
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
        NSArray *a=[ld[@"Address"] componentsSeparatedByString:@"\n"];
        loc.streetNumber=a[0];
        loc.streetName=a[1];
        loc.city=ld[@"City"];
        loc.unit=ld[@"Unit"];
        loc.zip=ld[@"Zip"];
        loc.state=ld[@"State"];
        self.location=loc;
    }
    return self;
}

- (NSString*)address {
    if(!_address) {
        _address=[NSString stringWithFormat:@"%@ %@",self.location.streetNumber, self.location.streetName];
    }
    return _address;
}

@end
