//
//  utilities.h
//  icanvass
//
//  Created by Roman Kot on 16.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (RKFunctional)
- (NSMutableArray*)mapWith:(NSObject*(^)(NSObject*))f;
@end
