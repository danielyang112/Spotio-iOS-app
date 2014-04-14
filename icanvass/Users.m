//
//  Users.m
//  icanvass
//
//  Created by Roman Kot on 14.04.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "Users.h"
#import "ICRequestManager.h"
#import "utilities.h"

@implementation UserTemp

- (id)initWithDictionary:(NSDictionary*)d {
    self=[super init];
    if(self) {
        self.userName=d[@"UserName"];
        self.firstName=d[@"FirstName"];
        self.lastName=d[@"LastName"];
        self.fullName=[NSString stringWithFormat:@"%@ %@",_firstName,_lastName];
    }
    return self;
}

@end

@interface Users () {
    BOOL _gettingUsers;
}
@property (nonatomic,strong) NSArray *users;
@property (nonatomic,strong) NSMutableDictionary *usersByUserName;

@end

@implementation Users

- (id)init {
    self=[super init];
    if(self) {
        self.usersByUserName=[[NSMutableDictionary alloc] initWithCapacity:5];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

+ (Users*)sharedInstance {
    static Users *sharedInstance=nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedInstance=[Users new];
    });
    return sharedInstance;
}

- (NSArray*)usersArrayFromArray:(NSArray*)a {
    return [a mapWith:^NSObject *(NSObject *o) {
        UserTemp *u=[[UserTemp alloc] initWithDictionary:(NSDictionary*)o];
        return u;
    }];
}

- (void)updateDictionary {
    [_usersByUserName removeAllObjects];
    for(UserTemp *u in _users){
        _usersByUserName[u.userName]=u;
    }
}

- (void)fetchUsersWithBlock:(void (^)(NSArray *a))block {
    _gettingUsers=YES;
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/UserProfileBasics?$format=json";
    u=[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.users=[self usersArrayFromArray:responseObject[@"value"]];
        [self updateDictionary];
        if(block) block(_users);
        _gettingUsers=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICUsers" object:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - API

- (void)sendUsersTo:(void (^)(NSArray *a))block {
    if(_users){
        block(_users);
        return;
    }
    if(_gettingUsers){
        return;
    }
    [self fetchUsersWithBlock:block];
}

- (NSString*)fullNameForUserName:(NSString*)userName {
    NSString *fullName=userName;
    if(_usersByUserName[userName]){
        fullName=[_usersByUserName[userName] fullName];
    }
    return fullName;
}

- (void)appDidBecomeActive:(NSNotification*)notification {
    [self fetchUsersWithBlock:nil];
}

@end
