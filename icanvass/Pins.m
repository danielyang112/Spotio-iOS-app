//
//  Pins.m
//  workbench
//
//  Created by Roman Kot on 09.03.2014.
//
//

#import "Pins.h"
#import "ICRequestManager.h"
#import "utilities.h"
#import "Pin.h"
#import "PinTemp.h"

@interface Pins ()
@property (nonatomic,strong) NSArray *pins;
@property (nonatomic,strong) NSArray *statuses;
@property (nonatomic,strong) NSDictionary *colors;
@end

@implementation Pins

- (Pins*)init {
    self=[super init];
    if(self) {
        self.colors=@{@"Not Home":[UIColor blueColor],
                      @"Not Interested":[UIColor darkGrayColor],
                      @"Not Qualified":[UIColor lightGrayColor],
                      @"Lead":[UIColor greenColor],
                      @"Sold":[UIColor redColor]};
    }
    return self;
}

+ (Pins *)sharedInstance {
    static Pins *sharedInstance=nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedInstance=[Pins new];
    });
    return sharedInstance;
}

- (NSArray*)pinsArrayFromArray:(NSArray*)a {
    return [a mapWith:^NSObject *(NSObject *o) {
        NSDictionary *dic=(NSDictionary*)o;
        return [[PinTemp alloc] initWithDictionary:dic];
    }];
}

- (NSArray*)statusesArrayFromArray:(NSArray*)a {
    NSMutableArray *ma=[[NSMutableArray alloc] initWithCapacity:[a count]];
//    NSMutableDictionary *c=[[NSMutableDictionary alloc] initWithCapacity:5];
    for(NSDictionary *dic in a) {
        [ma addObject:dic[@"Name"]];
    }
    return ma;
}

- (void)sendPinsTo:(void (^)(NSArray *a))block {
    if(_pins){
        block(_pins);
        return;
    }
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/Pins?$format=json&$orderby=CreationDate desc&$select=CreationDate,Id,Latitude,Location,Longitude,Status";
    u=[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.pins=[self pinsArrayFromArray:responseObject[@"value"]];
        block(_pins);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block {
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/Pins?$format=json";
    [manager POST:u parameters:dictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        block(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        block(NO);
    }];
}

- (void)sendStatusesTo:(void (^)(NSArray *a))block {
    if(_statuses){
        block(_statuses);
        return;
    }
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/PinStatus?$format=json";
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.statuses=[self statusesArrayFromArray:responseObject[@"value"]];
        block(_statuses);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinColors" object:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (UIColor*)colorForStatus:(NSString*)status {
    UIColor *c=_colors[status];
    if(!c){
        c=[UIColor whiteColor];
    }
    return c;
}

@end
