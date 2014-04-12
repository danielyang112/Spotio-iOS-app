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

@interface Pins () {
    BOOL _sendingStatuses;
}
@property (nonatomic,strong) NSMutableArray *filteredPins;
@property (nonatomic,strong) NSArray *statuses;
@property (nonatomic,strong) NSDictionary *colors;
@end

@implementation Pins

- (Pins*)init {
    self=[super init];
    if(self) {
        self.colors=@{};
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:@"ICUserLoggedInn" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterChanged:) name:@"ICFilter" object:nil];
        [self sendStatusesTo:nil];
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

- (NSMutableArray*)pinsArrayFromArray:(NSArray*)a {
    return [a mapWith:^NSObject *(NSObject *o) {
        NSDictionary *dic=(NSDictionary*)o;
        return [[PinTemp alloc] initWithDictionary:dic];
    }];
}

- (NSArray*)statusesArrayFromArray:(NSArray*)a {
    NSMutableArray *ma=[[NSMutableArray alloc] initWithCapacity:[a count]];
    for(NSDictionary *dic in a) {
        [ma addObject:dic[@"Name"]];
    }
    return ma;
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (NSDictionary*)colorsFromStatuses:(NSArray *)a {
    NSMutableDictionary *md=[[NSMutableDictionary alloc] initWithCapacity:[a count]];
    for(NSDictionary *dic in a) {
        md[dic[@"Name"]]=[Pins colorFromHexString:dic[@"Color"]];
    }
    return md;
}

- (void)sendPinsTo:(void (^)(NSArray *a))block {
    if(_filteredPins){
        block(_filteredPins);
        return;
    }
    if(_pins){
        block(_pins);
        return;
    }
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/Pins?$format=json&$orderby=CreationDate desc&$expand=CustomValues";
    u=[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.pins=[self pinsArrayFromArray:responseObject[@"value"]];
        self.oldest=[[_pins lastObject] creationDate];
        self.newest=[[_pins firstObject] creationDate];
        block(_pins);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block {
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/Pins?$format=json&$expand=CustomValues";
    [manager POST:u parameters:dictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        PinTemp *p=[[PinTemp alloc] initWithDictionary:responseObject];
        [_pins insertObject:p atIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
        block(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        block(NO);
    }];
}

- (void)editPin:(PinTemp*)pin withDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block {
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=[NSString stringWithFormat:@"PinService.svc/Pins(guid'%@')?$format=json",dictionary[@"Id"]];
    [manager PATCH:u parameters:dictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        PinTemp *p=[_pins grepWith:^BOOL(NSObject *o) {
            PinTemp *_p=(PinTemp*)o;
            return [pin.ident isEqual:_p.ident];
        }][0];
        NSArray *c=p.customValues;
        [p updateWithDictionary:dictionary];
        p.customValues=c;
        //NSInteger idx=[_pins indexOfObject:p];
        //[_pins replaceObjectAtIndex:idx withObject:[[PinTemp alloc] initWithDictionary:dictionary]];
//        p.status=dictionary[@"Status"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
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
    _sendingStatuses=YES;
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/PinStatus?$format=json";
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.statuses=[self statusesArrayFromArray:responseObject[@"value"]];
        if(block) block(_statuses);
        self.colors=[self colorsFromStatuses:responseObject[@"value"]];
        _sendingStatuses=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinColors" object:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        _sendingStatuses=NO;
    }];
}

- (void)clear {
    self.pins=nil;
    self.filteredPins=nil;
    self.statuses=nil;
    self.colors=nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
}

- (void)userLoggedIn:(NSNotification*)notification {
    [self clear];
    
}

- (void)filterChanged:(NSNotification*)notification {
    NSDictionary *d=notification.userInfo;
    self.filter=d;
    if(!d || ![d count]){
        self.filteredPins=nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
        return;
    }
    NSArray *s=d[@"statuses"];
    NSDate *cf=d[@"createdFrom"];
    NSDate *ct=d[@"createdTo"];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger comps = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    if(cf){
        NSDateComponents *cfComponents = [calendar components:comps fromDate: cf];
        NSDateComponents *ctComponents = [calendar components:comps fromDate: ct];
        cf = [calendar dateFromComponents:cfComponents];
        ct = [calendar dateFromComponents:ctComponents];
    }
    
    self.filteredPins=[_pins grepWith:^BOOL(NSObject *o) {
        BOOL ret=YES;
        PinTemp *p=(PinTemp*)o;
        if(cf){
            NSDateComponents *components = [calendar components:comps
                                                         fromDate:p.creationDate];
            NSDate *date=[calendar dateFromComponents:components];
            ret=ret&&([cf compare:date]!=NSOrderedDescending);
            ret=ret&&([date compare:ct]!=NSOrderedDescending);
        }
        if(s){
            ret=ret&&([s containsObject:p.status]);
        }
        return ret;
    }];
}

- (UIColor*)colorForStatus:(NSString*)status {
    if(!_colors&&!_sendingStatuses) {
        [self sendStatusesTo:nil];
    }
    UIColor *c=_colors[status];
    if(!c){
        c=[UIColor whiteColor];
    }
    return c;
}

@end
