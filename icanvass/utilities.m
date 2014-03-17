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

@end
