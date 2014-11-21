//
//  Users.h
//  icanvass
//
//  Created by Roman Kot on 14.04.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserTemp : NSObject
@property (nonatomic,strong) NSString *userName;
@property (nonatomic,strong) NSString *firstName;
@property (nonatomic,strong) NSString *lastName;
@property (nonatomic,strong) NSString *fullName;
@end

@interface Users : NSObject

+ (Users*)sharedInstance;
- (void)sendUsersTo:(void (^)(NSArray *a))block;
- (NSString*)fullNameForUserName:(NSString*)userName;
@end
