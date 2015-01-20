//
//  Territories.h
//  icanvass
//
//  Created by Roman Kot on 07.12.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Area : NSObject
@property (nonatomic,strong) NSNumber *ident;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) UIColor *color;
@property (nonatomic,strong) NSArray *vertices;
+ (Area*)areaWithJSON:(NSDictionary*)json;
@end

@interface Territories : NSObject
+ (Territories*)sharedInstance;
- (void)sendTerritoriesTo:(void (^)(NSArray *a))block;
@end
