//
//  Territories.m
//  icanvass
//
//  Created by Roman Kot on 07.12.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "Territories.h"
#import "ICRequestManager.h"
#import "utilities.h"

@implementation Area

- (id)initWithJSON:(NSDictionary*)json {
    self=[super init];
    if(self){
        _ident=json[@"Id"];
        _name=json[@"Name"];
        _color=colorFromHexString(json[@"Color"]);
        NSArray *arr=json[@"Polygon"];
        NSSortDescriptor *descriptor=[[NSSortDescriptor alloc] initWithKey:@"Order" ascending:YES];
        arr=[arr sortedArrayUsingDescriptors:@[descriptor]];
        _vertices=[arr mapWith:^NSObject *(NSObject *o) {
            NSDictionary *dic=(NSDictionary*)o;
            NSNumber *lat=@([dic[@"Latitude"] doubleValue]);
            NSNumber *lon=@([dic[@"Longitude"] doubleValue]);
            NSDictionary *d=@{@"Latitude":lat,@"Longitude":lon};
            return d;
        }];
    }
    return self;
}

+ (Area*)areaWithJSON:(NSDictionary*)json {
    return [[Area alloc] initWithJSON:json];
}

@end

@interface Territories ()
@property (nonatomic) BOOL getting;
@property (nonatomic,strong) NSArray *areas;
@end

@implementation Territories

- (id)init {
    self=[super init];
    if(self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fanOut:) name:@"FanOutTerritories" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:@"ICUserLoggedInn" object:nil];
    }
    return self;
}

+ (Territories*)sharedInstance {
    static Territories *sharedInstance=nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedInstance=[Territories new];
    });
    return sharedInstance;
}

- (NSArray*)areasFromJSONArray:(NSArray*)json {
    NSArray *arr;
    arr=[json mapWith:^NSObject *(NSObject *o) {
        Area *a=[Area areaWithJSON:(NSDictionary*)o];
        return a;
    }];
    
    return arr;
}

- (void)fetchTerritoriesWithBlock:(void (^)(NSArray *a))block {
    self.getting=YES;
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/Territories?$format=json&$expand=Polygon";
    u=[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.areas=[self areasFromJSONArray:responseObject[@"value"]];
        if(block) block(self.areas);
        
        self.getting=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICTerritories" object:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.getting=NO;
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark API

- (void)sendTerritoriesTo:(void (^)(NSArray *a))block {
    if(self.areas){
        block(self.areas);
        return;
    }
    if(self.getting){
        return;
    }
    [self fetchTerritoriesWithBlock:block];
}

#pragma mark Notifications

- (void)appDidBecomeActive:(NSNotification*)notification {
    [self fetchTerritoriesWithBlock:nil];
}

- (void)fanOut:(NSNotification*)notification {
    [self fetchTerritoriesWithBlock:nil];
}

- (void)userLoggedIn:(NSNotification*)notification {
    [self fetchTerritoriesWithBlock:nil];
}

@end
