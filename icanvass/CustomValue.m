//
//  CustomValue.m
//  icanvass
//
//  Created by Roman Kot on 20.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "CustomValue.h"
#import "Pin.h"
#import "utilities.h"

@implementation CustomValue

@dynamic dateTimeValue;
@dynamic decimalValue;
@dynamic definitionId;
@dynamic ident;
@dynamic intValue;
@dynamic stringValue;
@dynamic json;
@dynamic pin;

- (void)updateWithDictionary:(NSDictionary*)dic {
    self.dateTimeValue=nilIfNull(dic[@"DateTimeValue"]);
    self.decimalValue=nilIfNull(dic[@"DecimalValue"]);
    self.definitionId=nilIfNull(dic[@"DefinitionId"]);
    self.ident=nilIfNull(dic[@"Id"]);
    self.intValue=nilIfNull(dic[@"IntValue"]);
    self.stringValue=nilIfNull(dic[@"StringValue"]);
}

- (NSDictionary*)dict {
    NSMutableDictionary *md=[NSMutableDictionary dictionary];
    if(self.dateTimeValue)
        md[@"DateTimeValue"]=self.dateTimeValue;
    if(self.decimalValue)
        md[@"DecimalValue"]=self.decimalValue;
    md[@"DefinitionId"]=self.definitionId;
    md[@"Id"]=self.ident;
    if(self.intValue)
        md[@"IntValue"]=self.intValue;
    if(self.stringValue)
        md[@"StringValue"]=self.stringValue;
    return md;
}

@end
