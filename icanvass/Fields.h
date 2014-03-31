//
//  Fields.h
//  icanvass
//
//  Created by Roman Kot on 29.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum FieldType : NSUInteger {
    FieldTextBox,
    FieldPhoneNumber,
    FieldEmailAddress,
    FieldNoteBox,
    FieldDateTime,
    FieldDropDown,
    FieldMoney,
    FieldNumber
} FieldType;

@interface Field : NSObject
@property (nonatomic) NSInteger ident;
@property (nonatomic) BOOL disabled;
@property (nonatomic) BOOL required;
@property (nonatomic,strong) NSString *name;
@property (nonatomic) NSInteger order;
@property (nonatomic) NSInteger section;
@property (nonatomic,strong) NSArray *settings;
@property (nonatomic) FieldType type;
//@property (nonatomic,strong) id clientData;
@end

@interface Fields : NSObject
+ (Fields*)sharedInstance;
- (void)sendFieldsTo:(void (^)(NSArray *a))block;
@property (nonatomic,strong) NSMutableDictionary *fieldById;
@end
