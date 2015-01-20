//
//  SOSession.h
//  icanvass
//

#import <Foundation/Foundation.h>

@interface SOSession : NSObject

+ (BOOL)isHasBeenLoggedIn;
+ (void)setIsHasBeenLoggedIn:(BOOL)isHasBeenLoggedIn;

@end
