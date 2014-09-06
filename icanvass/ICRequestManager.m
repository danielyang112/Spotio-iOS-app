//
//  ICRequestManager.m
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import "ICRequestManager.h"

@implementation ICRequestManager

+ (ICRequestManager*)sharedManager {
    static ICRequestManager *sharedManager;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedManager=[[ICRequestManager alloc] initWithBaseURL:[NSURL URLWithString:kBaseUrl]];
        [sharedManager setRequestSerializer:[AFJSONRequestSerializer serializer]];
        NSString *username=[[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey];
        NSString *company=[[NSUserDefaults standardUserDefaults] objectForKey:kCompanyNameKey];
        NSString *password=[[NSUserDefaults standardUserDefaults] objectForKey:kPasswordKey];
        if(username&&company&&password) {
            NSString *u=[NSString stringWithFormat:@"%@||%@",company, username];
            [sharedManager.requestSerializer setAuthorizationHeaderFieldWithUsername:u password:password];
        }
    });
    return sharedManager;
}

- (BOOL)isUserLoggedIn {
    return !![[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey];
}

- (void)loginUserName:(NSString*)userName password:(NSString*)password
              company:(NSString*)company cb:(void(^)(BOOL success))cb {
    
    NSString *u=[NSString stringWithFormat:@"%@||%@",company, userName];
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:u password:password];
    [self GET:@"PinService.svc/Pins?$format=json&$top=0" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSUserDefaults standardUserDefaults] setObject:userName forKey:kUserNameKey];
        [[NSUserDefaults standardUserDefaults] setObject:company  forKey:kCompanyNameKey];
        [[NSUserDefaults standardUserDefaults] setObject:password forKey:kPasswordKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICUserLoggedInn" object:nil];
        cb(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        cb(NO);
    }];
}

- (void)registerWithDictionary:(NSDictionary*)d cb:(void(^)(BOOL success, id response))cb {
    static NSDateFormatter *nozoneFormatter;
    if(!nozoneFormatter) {
        nozoneFormatter=[[NSDateFormatter alloc] init];
        nozoneFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [nozoneFormatter setTimeZone:gmt];
    }
    [[ICRequestManager sharedManager] POST:@"MobileApp/RegisterCompanyExtended" parameters:d success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dic=operation.responseObject;
        if(!dic[@"Message"]){
            [self loginUserName:d[@"EmailAddress"] password:d[@"Password"] company:dic[@"CompanyLogin"] cb:^(BOOL success) {
                [[NSUserDefaults standardUserDefaults] setObject:[nozoneFormatter stringFromDate:[NSDate date]] forKey:kRefreshDate];
                [[NSUserDefaults standardUserDefaults] synchronize];
                cb(YES,operation.responseObject);
            }];
        }else{
            cb(NO,operation.responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"registration failed");
        cb(NO,nil);
    }];
}

- (void)logoutWithCb:(void(^)(BOOL success))cb {
    [self.operationQueue cancelAllOperations];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCompanyNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPasswordKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRefreshDate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sharing"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICLogOut" object:nil userInfo:nil];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:@"" password:@""];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICNetFailed" object:nil userInfo:@{@"status":@(401)}];
    //[self loginUserName:@"" password:@"" company:@"" cb:^(BOOL success) {cb(success);}];
    cb(YES);
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    void(^f)(AFHTTPRequestOperation *operation, NSError *error)=^(AFHTTPRequestOperation *operation, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICNetFailed" object:nil userInfo:@{@"status":[NSNumber numberWithLong:operation.response.statusCode]}];
        NSLog(@"%@",operation.responseString);
        failure(operation,error);
    };
    
    return [super HTTPRequestOperationWithRequest:request success:success failure:f];
}

@end
