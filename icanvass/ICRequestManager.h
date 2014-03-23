//
//  ICRequestManager.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#define kUserNameKey @"UserName"

#import "AFHTTPRequestOperationManager.h"

@interface ICRequestManager : AFHTTPRequestOperationManager
+ (ICRequestManager*)sharedManager;
- (void)loginUserName:(NSString*)userName password:(NSString*)password
              company:(NSString*)company cb:(void(^)(BOOL success))cb;
- (void)registerWithDictionary:(NSDictionary*)d cb:(void(^)(BOOL success))cb;
@end
