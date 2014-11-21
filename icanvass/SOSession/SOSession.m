//
//  SOSession.m
//  icanvass
//

#import "SOSession.h"

@implementation SOSession

+ (BOOL)isHasBeenLoggedIn {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"isHasBeenLoggedIn"];
}

+ (void)setIsHasBeenLoggedIn:(BOOL)isHasBeenLoggedIn {
	[[NSUserDefaults standardUserDefaults] setBool:isHasBeenLoggedIn forKey:@"isHasBeenLoggedIn"];
}

@end
