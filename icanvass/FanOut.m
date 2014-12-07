//
//  FanOut.m
//  icanvass
//
//  Created by Roman Kot on 21.09.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "FanOut.h"
#import "AppDelegate.h"

@interface FanOut ()
@property (nonatomic,strong) UIWebView *web;
@property (nonatomic,strong) NSString *channel;
@property (nonatomic,strong) NSString *realm;
@end

@implementation FanOut

- (id)init {
    self=[super init];
    if(self) {
        AppDelegate *del = (((AppDelegate*) [UIApplication sharedApplication].delegate));
        self.web=[[UIWebView alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 0.f)];
        _web.delegate=self;
        [del.window.rootViewController.view addSubview:_web];
    }
    return self;
}

+ (FanOut*)sharedInstance {
    static FanOut *sharedInstance=nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedInstance=[FanOut new];
    });
    return sharedInstance;
}

- (void)subscribe:(NSString*)channel realm:(NSString*)realm {
    self.channel=channel;
    self.realm=realm;
    [self loadPage];
}

- (void)loadPage {
    NSString *path=[[NSBundle mainBundle] pathForResource:@"fanout" ofType:@"html"];
    NSURL *url=[NSURL fileURLWithPath:path isDirectory:NO];
    NSString *u=[url absoluteString];
    u=[NSString stringWithFormat:@"%@?r=%@&c=%@",url,_realm,_channel];
    url=[NSURL URLWithString:u];
    [_web loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)notify:(NSString*)name {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"fanout: %@",request.URL);
    NSString *scheme=[request.URL.scheme lowercaseString];
    if([scheme isEqualToString:@"pin"]){
        [self notify:@"FanOutPin"];
        return NO;
    }else if([scheme isEqualToString:@"settingsuseradded"]){
        [self notify:@"FanOutUsers"];
        return NO;
    }else if([scheme isEqualToString:@"settingsrolechanged"]){
        [self notify:@"FanOutRoles"];
        return NO;
    }else if([scheme isEqualToString:@"settingspermissionschanged"]){
        [self notify:@"FanOutRoles"];
        return NO;
    }else if([scheme isEqualToString:@"settingsstatuseschanged"]){
        [self notify:@"FanOutStatuses"];
        return NO;
    }else if([scheme isEqualToString:@"settingsquestionschanged"]){
        [self notify:@"FanOutQuestions"];
        return NO;
    }else if([scheme isEqualToString:@"territory"]){
        [self notify:@"FanOutTerritories"];
        return NO;
    }else{
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"%s",__FUNCTION__);
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"%s",__FUNCTION__);
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%s",__FUNCTION__);
}


@end
