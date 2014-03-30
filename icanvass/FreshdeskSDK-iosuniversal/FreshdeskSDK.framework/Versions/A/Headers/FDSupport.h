//
//  FDSupport.h
//  FDSupport
//
//  Created by Freshdesk (support[at]freshdesk.com)
//  Copyright (c) 2012 Freshdesk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDSupport : NSObject

extern NSString* const FD_NAVBAR_COLOR;

@property (nonatomic, copy) NSString *supportSite;
@property (nonatomic, copy) NSString *apiKey;
@property (assign) BOOL enableSSL;
@property (nonatomic, copy) NSString *userEmail;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *userUID;
@property (nonatomic, copy) NSDictionary *colorCodes;

// setup freshdesk support site with API key
+ (void) setUpWithSite:(NSString *)supportSite andApikey:(NSString *)apikey;

//setup freshdesk support site with API Key and enableSSL
+ (void) setUpWithSite:(NSString *)supportSite andApikey:(NSString *)apikey enableSSL:(BOOL)sslEnable;

//optional configurations
+ (void) setUsername:(NSString *)userName;
+ (void) setUseremail:(NSString *)userEmail;
+ (void) setUserUID:(NSString *) userUID;
+ (void) setUpColor:(NSDictionary *)colorCodes;

// freshdesk support instance
+ (id) sharedInstance;

// show the freshdesk support interface
- (void) presentSupport:(UIViewController *) parentViewController;

// show the freshdesk feedback interface
- (void) presentFeedback:(UIViewController *) parentViewController;

@end