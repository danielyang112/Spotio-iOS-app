//
//  ICRequestManager.h
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#define kUserNameKey @"UserName"
#define kCompanyNameKey @"CompanyName"
#define kBaseUrl @"http://services.spotio.com:888/"
//#define kBaseUrl @"http://services.spotio.com:8080/"
//#define kBaseUrl @"http://app.spotio.com/"
#define kPasswordKey @"Password"
#define kRefreshDate @"refreshdate"

#import "AFHTTPRequestOperationManager.h"

@interface ICRequestManager : AFHTTPRequestOperationManager
+ (ICRequestManager*)sharedManager;
- (void)loginUserName:(NSString*)userName password:(NSString*)password
              company:(NSString*)company cb:(void(^)(BOOL success))cb;
- (void)registerWithDictionary:(NSDictionary*)d cb:(void(^)(BOOL success, id response))cb;
- (void)logoutWithCb:(void(^)(BOOL success))cb;
- (BOOL)isUserLoggedIn;
@end
