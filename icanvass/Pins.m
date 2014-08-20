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
#import "AppDelegate.h"
#import "Location.h"


@interface Pins () {
}
@property (nonatomic,strong) NSMutableArray *filteredPins;
@property (nonatomic,strong) NSArray *statuses;
@property (nonatomic,strong) NSDictionary *colors;
@property (nonatomic,strong) NSSortDescriptor *descriptor;
@property (nonatomic) BOOL sendingStatuses;
@property (nonatomic) BOOL gettingPins;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@end

@implementation Pins

- (Pins*)init {
    self=[super init];
    if(self) {
        self.colors=@{};
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:@"ICUserLoggedInn" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:@"ICLogOut" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterChanged:) name:@"ICFilter" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
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

- (NSArray*)pinsArrayFromArray:(NSArray*)a {
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    self.managedObjectContext = appDelegate.managedObjectContext;
    [_managedObjectContext setUndoManager:nil];
    NSString *date=[[NSUserDefaults standardUserDefaults] objectForKey:kRefreshDate];
    for(NSDictionary *dic in a){
        
        Pin *newPin;
        if(date){
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:
             [NSEntityDescription entityForName:@"Pin" inManagedObjectContext:_managedObjectContext]];
            [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(ident == %@)", dic[@"Id"]]];
            NSError *error;
            NSArray *pinsmatching = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
            newPin=pinsmatching.firstObject;
        }
        if(!newPin)
            newPin = [NSEntityDescription insertNewObjectForEntityForName:@"Pin"
                                                          inManagedObjectContext:_managedObjectContext];
        [newPin updateWithDictionary:dic];
        
        Location *loc=[NSEntityDescription insertNewObjectForEntityForName:@"Location"
                                                    inManagedObjectContext:_managedObjectContext];
        NSDictionary *ld=dic[@"Location"];
        loc.streetNumber=[NSNumber numberWithInt:[ld[@"HouseNumber"] integerValue]];
        loc.streetName=ld[@"Street"];
        loc.city=nilIfNull(ld[@"City"]);
        NSObject *u=nilIfNull(ld[@"Unit"]);
        if([u isKindOfClass:[NSNumber class]]){
            u=[(NSNumber*)u stringValue];
        }
        loc.unit=(NSString*)u;
        loc.zip=nilIfNull(ld[@"Zip"]);
        loc.state=nilIfNull(ld[@"State"]);
        newPin.location=loc;
        
        if(nilIfNull(dic[@"CustomValues"])){
            NSMutableOrderedSet *os=[NSMutableOrderedSet orderedSet];
            for(NSDictionary *d in dic[@"CustomValues"]){
                CustomValue *cv = [NSEntityDescription insertNewObjectForEntityForName:@"CustomValue"
                                                                inManagedObjectContext:_managedObjectContext];
                [cv updateWithDictionary:d];
                [os addObject:cv];
            }
    //        [newPin addCustomValues:[NSOrderedSet orderedSetWithOrderedSet:os]];
            newPin.customValues=os;
        }
    }
    
    NSError *error=nil;
    [_managedObjectContext save:&error];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pin"
                                              inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    // Query on managedObjectContext With Generated fetchRequest
    NSArray *fetchedRecords = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    
//    NSMutableArray *ma=[NSMutableArray arrayWithCapacity:[a count]];
//    if(_pins){
//        ma=[_pins mutableCopy];
//    }
//    for(NSDictionary *dic in a){
//        [ma addObject:[[PinTemp alloc] initWithDictionary:dic]];
//    }
//    self.descriptor=[[NSSortDescriptor alloc] initWithKey:@"updateDate" ascending:NO];
//    ma=[[ma sortedArrayUsingDescriptors:@[_descriptor]] mutableCopy];
    
    return fetchedRecords;
//    return [a mapWith:^NSObject *(NSObject *o) {
//        NSDictionary *dic=(NSDictionary*)o;
//        return [[PinTemp alloc] initWithDictionary:dic];
//    }];
}

- (NSArray*)statusesArrayFromArray:(NSArray*)a {
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"Order" ascending:YES];
    a=[a sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    NSMutableArray *ma=[[NSMutableArray alloc] initWithCapacity:[a count]];
    for(NSDictionary *dic in a) {
        if([dic[@"IsActive"] boolValue])
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

- (void)fetchPinsWithBlock:(void (^)(NSArray *a))block {
    [self fetchPinsFrom:0 withBlock:block];
}

- (void)fetchPinsFrom:(int)skip withBlock:(void (^)(NSArray *a))block {
    NSLog(@"%s",__FUNCTION__);
    if(![[ICRequestManager sharedManager] isUserLoggedIn]) {
        if(block) block(nil);
        return;
    }
    self.gettingPins=YES;
    static NSDateFormatter *nozoneFormatter;
    if(!nozoneFormatter) {
        nozoneFormatter=[[NSDateFormatter alloc] init];
        nozoneFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [nozoneFormatter setTimeZone:gmt];
    }
    NSString *date=[[NSUserDefaults standardUserDefaults] objectForKey:kRefreshDate];
    
    ICRequestManager *manager=[ICRequestManager sharedManager];
//    NSString *u=@"PinService.svc/Pins?$format=json&$orderby=CreationDate desc&$expand=CustomValues";
    NSString *u=[NSString stringWithFormat:@"PinService.svc/Pins?$format=json&$skip=%d&$top=500&$select=CustomValues,Id,Status,Location,UserName,Latitude,Longitude,CreationDate,UpdateDate&$orderby=CreationDate desc&$expand=CustomValues",skip];
    if(date){
        u=[NSString stringWithFormat:@"%@&$filter=CreationDate ge datetime'%@' or UpdateDate ge datetime'%@'",u,date,date];
    }
    NSLog(@"%@",u);
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    u=[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(!date){
        [appDelegate showLoading:YES];
    }
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.pins=[self pinsArrayFromArray:responseObject[@"value"]];
        self.oldest=[[_pins lastObject] updateDate];
        self.newest=[[_pins firstObject] updateDate];
        if(block) block(_pins);
        [[NSUserDefaults standardUserDefaults] setObject:[nozoneFormatter stringFromDate:[NSDate date]] forKey:kRefreshDate];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.gettingPins=NO;
        [appDelegate showLoading:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.gettingPins=NO;
        [appDelegate showLoading:NO];
        NSLog(@"Error: %@", error);
    }];
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
    if(_gettingPins) {
        return;
    }
    [self fetchPinsWithBlock:block];
}

- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block {
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/Pins?$format=json&$expand=CustomValues";
    [manager POST:u parameters:dictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
//        PinTemp *p=[[PinTemp alloc] initWithDictionary:responseObject];
//        [_pins insertObject:p atIndex:0];
//        p.customValues=dictionary[@"CustomValues"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
        [self fetchPinsWithBlock:^(NSArray *a) {
            block(YES);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        block(NO);
    }];
}

- (void)editPin:(Pin*)pin withDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block {
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/Pins?$format=json&$expand=CustomValues";
    [manager POST:u parameters:dictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
//        PinTemp *p=[_pins grepWith:^BOOL(NSObject *o) {
//            PinTemp *_p=(PinTemp*)o;
//            return [pin.ident isEqual:_p.ident];
//        }][0];
//        //NSArray *c=p.customValues;
////        [p updateWithDictionary:dictionary];
//        [p updateWithDictionary:responseObject];
////        p.customValues=dictionary[@"CustomValues"];
//        //NSInteger idx=[_pins indexOfObject:p];
//        //[_pins replaceObjectAtIndex:idx withObject:[[PinTemp alloc] initWithDictionary:dictionary]];
////        p.status=dictionary[@"Status"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
        [self fetchPinsWithBlock:^(NSArray *a) {
            block(YES);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        block(NO);
    }];
}

- (void)fetchStatusesWithBlock:(void (^)(NSArray *a))block {
    self.sendingStatuses=YES;
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/PinStatus?$format=json";
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.statuses=[self statusesArrayFromArray:responseObject[@"value"]];
        if(block) block(_statuses);
        self.colors=[self colorsFromStatuses:responseObject[@"value"]];
        self.sendingStatuses=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinColors" object:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        self.sendingStatuses=NO;
    }];
}

- (void)sendStatusesTo:(void (^)(NSArray *a))block {
    if(_statuses){
        block(_statuses);
        return;
    }
    [self fetchStatusesWithBlock:block];
}

- (void)clearPins {
    NSFetchRequest * allCars = [[NSFetchRequest alloc] init];
    [allCars setEntity:[NSEntityDescription entityForName:@"Pin" inManagedObjectContext:_managedObjectContext]];
    [allCars setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * ps = [_managedObjectContext executeFetchRequest:allCars error:&error];
    //error handling goes here
    for (NSManagedObject * p in ps) {
        [_managedObjectContext deleteObject:p];
    }
    NSError *saveError = nil;
    [_managedObjectContext save:&saveError];
}

- (void)clear {
    [self clearPins];
    self.pins=nil;
    self.filteredPins=nil;
    self.statuses=nil;
    self.colors=nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
}

- (void)userLoggedIn:(NSNotification*)notification {
    [self clear];
}

- (void)userLoggedOut:(NSNotification*)notification {
    [self clear];
}

- (void)appDidBecomeActive:(NSNotification*)notification {
    [self fetchStatusesWithBlock:nil];
    if(!_gettingPins) {
        [self fetchPinsWithBlock:nil];
    }
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
    NSArray *u=d[@"users"];
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
        Pin *p=(Pin*)o;
        if(cf){
            NSDateComponents *components = [calendar components:comps
                                                         fromDate:p.updateDate];
            NSDate *date=[calendar dateFromComponents:components];
            ret=ret&&([cf compare:date]!=NSOrderedDescending);
            ret=ret&&([date compare:ct]!=NSOrderedDescending);
        }
        if(s){
            ret=ret&&([s containsObject:p.status]);
        }
        if(u){
            ret=ret&&([u containsObject:p.user]);
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
