//
//  ICRequestManager.m
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import "ICRequestManager.h"

#define kBaseUrl @"http://login.icanvassapp.com/"

@implementation ICRequestManager

+ (ICRequestManager*)sharedManager {
    static ICRequestManager *sharedManager;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedManager=[[ICRequestManager alloc] initWithBaseURL:[NSURL URLWithString:kBaseUrl]];
        [sharedManager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    });
    return sharedManager;
}

- (void)loginUserName:(NSString*)userName password:(NSString*)password
              company:(NSString*)company cb:(void(^)(BOOL success))cb {
    
    NSString *u=[NSString stringWithFormat:@"%@||%@",company, userName];
    self.requestSerializer=[AFHTTPRequestSerializer serializer];
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:u password:password];
    [self GET:@"PinService.svc/Pins?$format=json&$top=0" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        cb(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.requestSerializer=[AFHTTPRequestSerializer new];
        cb(NO);
    }];
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    void(^f)(AFHTTPRequestOperation *operation, NSError *error)=^(AFHTTPRequestOperation *operation, NSError *error) {
        if(operation.response.statusCode==403){
            NSLog(@"403");
        }
        failure(operation,error);
    };
    
    return [super HTTPRequestOperationWithRequest:request success:success failure:f];
}

@end
