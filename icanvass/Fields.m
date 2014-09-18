//
//  Fields.m
//  icanvass
//
//  Created by Roman Kot on 29.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "Fields.h"
#import "ICRequestManager.h"
#import "utilities.h"

@implementation Field

- (id)initWithDictionary:(NSDictionary*)d {
    self=[super init];
    if(self) {
        self.ident=[d[@"Id"] integerValue];
        self.disabled=[d[@"IsDisabled"] boolValue];
        self.required=[d[@"IsRequired"] boolValue];
        self.name=d[@"Name"];
        self.order=[d[@"Order"] integerValue];
        self.section=[d[@"SectionId"] integerValue];
        self.settings=[nilIfNull(d[@"Settings"]) componentsSeparatedByString:@"\n"];
        self.type=[self typeFromString:d[@"Type"]];
    }
    return self;
}

- (FieldType)typeFromString:(NSString*)type {
    FieldType t=FieldTextBox;
    if([type isEqualToString:@"PhoneNumber"])
        t=FieldPhoneNumber;
    else if([type isEqualToString:@"EmailAddress"])
        t=FieldEmailAddress;
    else if([type isEqualToString:@"NoteBox"])
        t=FieldNoteBox;
    else if([type isEqualToString:@"DateTime"])
        t=FieldDateTime;
    else if([type isEqualToString:@"DropDown"])
        t=FieldDropDown;
    else if([type isEqualToString:@"Money"])
        t=FieldMoney;
    else if([type isEqualToString:@"Number"])
        t=FieldNumber;
    return t;
}

@end

@interface Fields ()
@property (nonatomic,strong) NSArray *fields;
@end

@implementation Fields

- (id)init {
    self=[super init];
    if(self) {
        self.fieldById=[[NSMutableDictionary alloc] initWithCapacity:5];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:@"ICUserLoggedInn" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(answeredQuestions:) name:@"ICQuestions" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

+ (Fields*)sharedInstance {
    static Fields *sharedInstance=nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken, ^{
        sharedInstance=[Fields new];
    });
    return sharedInstance;
}

- (NSArray*)fieldsArrayFromArray:(NSArray*)a {
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"Order" ascending:YES];
    a=[a sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    NSMutableArray *ma=[[NSMutableArray alloc] initWithCapacity:[a count]];
    for(NSDictionary *dic in a) {
        if(![dic[@"IsDisabled"] boolValue]) {
            Field *f=[[Field alloc] initWithDictionary:dic];
            [ma addObject:f];
        }
    }
    return ma;
}

- (void)updateDictionary {
    for(Field *f in _fields){
        _fieldById[[@(f.ident) stringValue]]=f;
    }
}

#pragma mark - API

- (void)sendFieldsTo:(void (^)(NSArray *a))block {
    block(_fields);
    if(_fields){
        return;
    }
    ICRequestManager *manager=[ICRequestManager sharedManager];
    NSString *u=@"PinService.svc/FieldDefinitions?$format=json";
    u=[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    __weak typeof(self) weakSelf = self;
    [manager GET:u parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        weakSelf.fields=[weakSelf fieldsArrayFromArray:responseObject[@"value"]];
        [weakSelf updateDictionary];
        block(_fields);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ICFields" object:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)userLoggedIn:(NSNotification*)notification {
    self.fields=nil;
}

- (void)answeredQuestions:(NSNotification*)notification {
    self.fields=nil;
}

- (void)appDidBecomeActive:(NSNotification*)notification {
    self.fields=nil;
}

@end
