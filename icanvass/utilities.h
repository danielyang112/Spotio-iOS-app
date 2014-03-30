//
//  utilities.h
//  icanvass
//
//  Created by Roman Kot on 16.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>

#define nilIfNull(foo) ((foo == [NSNull null]) ? nil : foo)

@interface NSArray (RKFunctional)
- (NSMutableArray*)mapWith:(NSObject*(^)(NSObject*))f;
- (NSMutableArray*)grepWith:(BOOL(^)(NSObject*))f;
@end
