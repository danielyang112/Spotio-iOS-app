//
//  SyncPinsOperation.m
//  icanvass
//
//  Created by Dmitriy on 30.09.14.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "SyncPinsOperation.h"
#import "Pins.h"

@interface SyncPinsOperation ()
{
    BOOL _finished;
}

@property (nonatomic, strong) NSMutableDictionary *parameters;

@end

@implementation SyncPinsOperation

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isFinished
{
    return _finished;
}

- (instancetype)initWithParameters:(NSDictionary*)parameters
{
    self = [super init];
    if (self)
    {
        self.parameters = [parameters mutableCopy];
    }
    return self;
}

- (void)start
{
    [self getPinsWithLimit:20 offset:0];
}

- (void)getPinsWithLimit:(NSUInteger)limit offset:(NSUInteger)offset
{
    [self.parameters setObject:@(limit) forKey:@"$top"];
    [self.parameters setObject:@(offset) forKey:@"$skip"];
    [[Pins sharedInstance] fetchPinsWithParameteres:self.parameters block:^(NSArray *a) {
        if ([a count]) {
            [self getPinsWithLimit:[self.parameters[@"$top"] unsignedLongValue]
                            offset:([self.parameters[@"$skip"] unsignedIntegerValue] + [self.parameters[@"$top"] unsignedIntegerValue])];
             
        }
        else
        {
            [self willChangeValueForKey:@"isFinished"];
            _finished = YES;
            [self didChangeValueForKey:@"isFinished"];

        }
    }];
    }



@end
