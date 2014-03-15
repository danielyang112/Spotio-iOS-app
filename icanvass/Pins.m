//
//  Pins.m
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import "Pins.h"
#import "ICRequestManager.h"

@interface Pins ()
@property (nonatomic,strong) NSArray *pins;
@end

@implementation Pins

+ (Pins *)sharedInstance {
    static Pins *sharedInstance=nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedInstance=[Pins new];
    });
    return sharedInstance;
}

- (void)sendPinsTo:(void (^)(NSArray *a))block {
    if(_pins){
        block(_pins);
        return;
    }
    ICRequestManager *manager=[ICRequestManager sharedManager];
    [manager GET:@"Pins?$format=json" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.pins=responseObject[@"value"];
        block(_pins);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
