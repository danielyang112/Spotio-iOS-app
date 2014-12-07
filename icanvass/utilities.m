//
//  utilities.m
//  icanvass
//
//  Created by Roman Kot on 16.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "utilities.h"

@implementation NSArray (RKFunctional)

- (NSMutableArray*)mapWith:(NSObject*(^)(NSObject*))f {
    NSMutableArray *a=[[NSMutableArray alloc] initWithCapacity:[self count]];
    for(NSObject *o in self) {
        [a addObject:f(o)];
    }
    return a;
}

- (NSMutableArray*)grepWith:(BOOL(^)(NSObject*))f {
    NSMutableArray *a=[[NSMutableArray alloc] initWithCapacity:[self count]];
    for(NSObject *o in self) {
        if(f(o)) [a addObject:o];
    }
    return a;
}

UIColor *colorFromHexString(NSString *hexString) {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
