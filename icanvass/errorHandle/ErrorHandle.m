//
//  ErrorHandle.m
//  icanvass
//

#import "ErrorHandle.h"
#import <CoreLocation/CoreLocation.h>

@implementation ErrorHandle

+ (NSString*)descriptionForError:(NSError*)error {

	return error.localizedDescription;
}


+ (BOOL)isInternetConnectionError:(NSError*)error {
	if ([error.domain isEqualToString:kCLErrorDomain]) {
		if (error.code >= 2 && error.code <= 9) {
			return YES;
		}
	}
	if ([error.domain isEqualToString:NSURLErrorDomain]) {
		if (error.code == NSURLErrorTimedOut) {
			return YES;
		}
		if (error.code == NSURLErrorNetworkConnectionLost) {
			return YES;
		}
		if (error.code == NSURLErrorNotConnectedToInternet) {
			return YES;
		}

		if (error.code == NSURLErrorCannotConnectToHost) {
			return YES;
		}

	}
	return NO;
}

@end
