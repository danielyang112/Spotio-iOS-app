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
#import "SVProgressHUD/SVProgressHUD.h"
#import "SyncPinsOperation.h"

@interface Pins () {
}
@property (nonatomic,strong) NSMutableArray *filteredPins;
@property (nonatomic,strong) NSArray *mapFilteredPins;
@property (nonatomic,strong) NSArray *statuses;
@property (nonatomic,strong) NSDictionary *colors;
@property (nonatomic,strong) NSSortDescriptor *descriptor;
@property (nonatomic) BOOL sendingStatuses;
@property (nonatomic) BOOL gettingPins;
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fanOut:) name:@"FanOutPin" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fanOutStatuses:) name:@"FanOutStatuses" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:@"UpdatePinFields" object:nil];
		
		[self sendStatusesTo:nil failure:nil];
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

- (void)fetchPinsFromCoreDataWithPredicate:(NSPredicate*)predicate
{
	AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
	NSManagedObjectContext *managedObjectContext= appDelegate.managedObjectContext;
	[managedObjectContext setUndoManager:nil];
	NSError *error=nil;
	//    [appDelegate.managedObjectContext save:&error];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pin"
											  inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:predicate];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc]
							  initWithKey:@"updateDate" ascending:NO];
	// Query on managedObjectContext With Generated fetchRequest
	fetchRequest.sortDescriptors=@[sort];
	NSArray *fetchedRecords = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if(!_fetchController)
	{
		_fetchController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	
	//    self.oldest=[[fetchedRecords lastObject] updateDate];
	//    self.newest=[[fetchedRecords firstObject] updateDate];
	self.filteredPins = [fetchedRecords copy];
	
}
- (void)fetchPinsFromCoreData
{
	AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
	NSManagedObjectContext *managedObjectContext= appDelegate.managedObjectContext;
	[managedObjectContext setUndoManager:nil];
	
	NSError *error=nil;
	//    [appDelegate.managedObjectContext save:&error];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pin"
											  inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc]
							  initWithKey:@"updateDate" ascending:NO];
	// Query on managedObjectContext With Generated fetchRequest
	fetchRequest.sortDescriptors=@[sort];
	NSArray *fetchedRecords = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if(!_fetchController)
	{
		_fetchController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	}
	
	self.oldest=[[fetchedRecords lastObject] updateDate];
	self.newest=[[fetchedRecords firstObject] updateDate];
	self.pins = [fetchedRecords copy];
	
	NSLog( @"4444 %d", [self.pins count]);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
	
	
	//    NSMutableArray *ma=[NSMutableArray arrayWithCapacity:[a count]];
	//    if(_pins){
	//        ma=[_pins mutableCopy];
	//    }
	//    for(NSDictionary *dic in a){
	//        [ma addObject:[[PinTemp alloc] initWithDictionary:dic]];
	//    }
	//    self.descriptor=[[NSSortDescriptor alloc] initWithKey:@"updateDate" ascending:NO];
	//    ma=[[ma sortedArrayUsingDescriptors:@[_descriptor]] mutableCopy];
	
	//    self.pins = fetchedRecords;
}

- (NSArray*)pinsArrayFromArray:(NSArray*)a {
	AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
	NSManagedObjectContext *managedObjectContext= appDelegate.managedObjectContext;
	[managedObjectContext setUndoManager:nil];
	
	NSString *date=[[NSUserDefaults standardUserDefaults] objectForKey:kRefreshDate];
	for(NSDictionary *dic in a){
		Pin *newPin;
		if(date){
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:
			 [NSEntityDescription entityForName:@"Pin" inManagedObjectContext:managedObjectContext]];
			[fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(ident == %@)", dic[@"Id"]]];
			NSError *error;
			NSArray *pinsmatching = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
			newPin=pinsmatching.firstObject;
		}
		if(!newPin)
			newPin = [NSEntityDescription insertNewObjectForEntityForName:@"Pin"
												   inManagedObjectContext:managedObjectContext];
		[newPin updateWithDictionary:dic];
		
		Location *loc=[NSEntityDescription insertNewObjectForEntityForName:@"Location"
													inManagedObjectContext:managedObjectContext];
		NSDictionary *ld=dic[@"Location"];
		loc.streetNumber=[NSNumber numberWithInt:[ld[@"HouseNumber"] integerValue]];
		loc.streetName=nilIfNull(ld[@"Street"]);
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
																inManagedObjectContext:managedObjectContext];
				[cv updateWithDictionary:d];
				[os addObject:cv];
			}
			//        [newPin addCustomValues:[NSOrderedSet orderedSetWithOrderedSet:os]];
			newPin.customValues=os;
		}
	}
	//    if (![a count]) {
	//        a = [self fetchPinsFromCoreData];
	//    }
	[appDelegate.managedObjectContext save:nil];
	
	return a;
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

- (NSDictionary*)colorsFromStatuses:(NSArray *)a {
	NSMutableDictionary *md=[[NSMutableDictionary alloc] initWithCapacity:[a count]];
	for(NSDictionary *dic in a) {
		md[dic[@"Name"]]=colorFromHexString(dic[@"Color"]);
	}
	return md;
}

+ (NSOperationQueue*)operationQueue
{
	static NSOperationQueue *opQueue;
	if (!opQueue)
	{
		opQueue = [NSOperationQueue new];
	}
	return opQueue;
}


- (void)fetchPinsWithBlock:(void (^)(NSArray *a))block {
	if (![[ICRequestManager sharedManager] isUserLoggedIn])
	{
		if (block) block(nil);
		return;
	}
	NSDictionary* parameteres = @{@"$top":@500, @"$skip":@0};
	SyncPinsOperation* operation = [[SyncPinsOperation alloc]initWithParameters:parameteres];
	[[Pins operationQueue] addOperation:operation];
	[operation setCompletionBlock:^{
		NSLog(@"Finished!");
		
		NSLog(@"----___________ %d", [_pins count]);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self fetchPinsFromCoreData];
			
			NSLog(@"----___________ %d", [_pins count]);
			
			static NSDateFormatter *nozoneFormatter;
			if(!nozoneFormatter) {
				nozoneFormatter=[[NSDateFormatter alloc] init];
				nozoneFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
				NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
				[nozoneFormatter setTimeZone:gmt];
			}
			[[NSUserDefaults standardUserDefaults] setObject:[nozoneFormatter stringFromDate:[NSDate date]] forKey:kRefreshDate];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			if(block) {
				block(_pins);
			}
			
		});
		
	}];
	
}

- (void)fetchPinsWithParameteres:(NSDictionary *)parameteres block:(void (^)(NSArray *))block
{
	__weak typeof(self) weakSelf = self;
	NSLog(@"%s",__FUNCTION__);
	if(![[ICRequestManager sharedManager] isUserLoggedIn]) {
		if(block) block(nil);
		return;
	}
	weakSelf.gettingPins=YES;
	NSString *date=[[NSUserDefaults standardUserDefaults] objectForKey:kRefreshDate];
	
	ICRequestManager *manager=[ICRequestManager sharedManager];
	//    NSString *u=@"PinService.svc/Pins?$format=json&$orderby=CreationDate desc&$expand=CustomValues";
	NSString *u=[NSString stringWithFormat:@"PinService.svc/Pins?$format=json&$select=CustomValues,Id,Status,Location,UserName,Latitude,Longitude,CreationDate,UpdateDate&$orderby=CreationDate desc&$expand=CustomValues&$top=%d&$skip=%d&$inlinecount=allpages",[parameteres[@"$top"] integerValue],[parameteres[@"$skip"] integerValue]] ;
	
	if(date){
		u=[NSString stringWithFormat:@"%@&$filter=CreationDate ge datetime'%@' or UpdateDate ge datetime'%@'",u,date,date];
	}
	NSLog(@"[fetchPinsWithParameteres] >>> %@",u);
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	u=[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	    if(!date && ![self.pins count]){
	        [appDelegate showLoading:YES];
	    }
	[manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		//        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
		//Background Thread
		//            NSLog(@"JSON: %@", responseObject);
		
		
		if(!weakSelf.pins)
		{
			weakSelf.pins = [NSMutableArray new];
		}
		
		[self pinsArrayFromArray:responseObject[@"value"]];
		
		//            self.oldest=[[_pins lastObject] updateDate];
		//            self.newest=[[_pins firstObject] updateDate];
		
		weakSelf.gettingPins=NO;
		//            dispatch_async(dispatch_get_main_queue(), ^(void){
		//Run UI UpdatesNSError *error=nil;
		if(block) block(responseObject[@"value"]);
		
		NSLog( @"responseObject[value] $$$$$$$$$$ %@", responseObject[@"value"]);
		
		//        if(block) block(_pins);
		        [appDelegate showLoading:NO];
		//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
		//            });
		//        });
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		weakSelf.gettingPins=NO;
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

- (void)deletePin:(Pin*)pin block:(void (^)(BOOL success))block {
	ICRequestManager *manager=[ICRequestManager sharedManager];
	NSString *u = [NSString stringWithFormat:@"PinService.svc/Pins(guid'%@')", pin.ident];
	[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
	[manager DELETE:u
		 parameters:@{}
			success:^(AFHTTPRequestOperation *operation, id responseObject) {
				[SVProgressHUD showSuccessWithStatus:@"Success"];
				block(YES);
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				[SVProgressHUD showErrorWithStatus:error.localizedDescription];
				block(NO);
				
			}];
}

- (void)addPinWithDictionary:(NSDictionary*)dictionary block:(void (^)(NSError *error))block {
	ICRequestManager *manager=[ICRequestManager sharedManager];
	[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
	NSString *u=@"PinService.svc/Pins?$format=json&$expand=CustomValues";
	[manager POST:u parameters:dictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"JSON: %@", responseObject);
		//        PinTemp *p=[[PinTemp alloc] initWithDictionary:responseObject];
		//        [_pins insertObject:p atIndex:0];
		//        p.customValues=dictionary[@"CustomValues"];
		//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
		//        [self fetchPinsWithBlock:^(NSArray *a) {
		[SVProgressHUD showSuccessWithStatus:@"Success"];
		block(nil);
		//        }];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Error: %@", error);
		block(error);
	}];
}

- (void)editPin:(Pin*)pin withDictionary:(NSDictionary*)dictionary block:(void (^)(BOOL success))block {
	ICRequestManager *manager=[ICRequestManager sharedManager];
	NSString *u=@"PinService.svc/Pins?$format=json&$expand=CustomValues";
	[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
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
		//        [self fetchPinsWithBlock:^(NSArray *a) {
		//            block(NO);
		[SVProgressHUD showSuccessWithStatus:@"Success"];
		block(YES);
		
		//        }];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Error: %@", error);
		[SVProgressHUD showErrorWithStatus:error.localizedDescription];
		block(NO);
		
	}];
}

- (void)fetchStatusesWithBlock:(void (^)(NSArray *a))block failure:(void (^)(NSError *error))failure {
	NSLog(@"%s",__FUNCTION__);
	if(![[ICRequestManager sharedManager] isUserLoggedIn]) {
		if(block) block(nil);
		return;
	}
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
		if (failure) {
			failure(error);
		}
		self.sendingStatuses=NO;
	}];
}

- (void)sendStatusesTo:(void (^)(NSArray *a))block failure:(void (^)(NSError *error))failure {
	if(_statuses){
		block(_statuses);
		return;
	}
	[self fetchStatusesWithBlock:block failure:failure];
}

- (void)clearPins {
	AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
	NSManagedObjectContext *managedObjectContext= appDelegate.managedObjectContext;
	[managedObjectContext setUndoManager:nil];
	NSFetchRequest * allPins = [[NSFetchRequest alloc] init];
	[allPins setEntity:[NSEntityDescription entityForName:@"Pin" inManagedObjectContext:managedObjectContext]];
	[allPins setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	
	NSError * error = nil;
	NSArray * ps = [managedObjectContext executeFetchRequest:allPins error:&error];
	//error handling goes here
	for (NSManagedObject * p in ps) {
		[managedObjectContext deleteObject:p];
	}
	NSError *saveError = nil;
	[managedObjectContext save:&saveError];
}

- (void)clear {
	[self clearPins];
	self.pins=nil;
	self.filteredPins=nil;
	self.statuses=nil;
	self.colors=nil;
	//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
}

- (void)userLoggedIn:(NSNotification*)notification {
	[self clear];
	[self fetchStatusesWithBlock:nil failure:nil];
}

- (void)userLoggedOut:(NSNotification*)notification {
	[self clear];
}

- (void)appDidBecomeActive:(NSNotification*)notification {
	[self fetchStatusesWithBlock:nil failure:nil];
	if(!_gettingPins) {
		[self fetchPinsWithBlock:nil];
	}
}

- (void)fanOut:(NSNotification*)notification {
	if(!_gettingPins) {
		[self fetchPinsWithBlock:nil];
	}
}

- (void)fanOutStatuses:(NSNotification*)notification {
    [self fetchStatusesWithBlock:nil failure:nil];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ICPinsChanged" object:nil];
}


- (UIColor*)colorForStatus:(NSString*)status {
	if(!_colors&&!_sendingStatuses) {
		[self sendStatusesTo:nil failure:nil];
	}
	UIColor *c=_colors[status];
	if(!c){
		c=[UIColor whiteColor];
	}
	return c;
}

-(void) filteredPinsWithArray:(NSArray*) filteredPins {
	self.mapFilteredPins = filteredPins;
}

-(NSArray*) filteredPinsArray {
	return self.mapFilteredPins;
}

@end
