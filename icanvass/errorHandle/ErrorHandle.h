//
//  ErrorHandle.h
//  icanvass
//

#import <Foundation/Foundation.h>

@interface ErrorHandle : NSObject

+ (NSString*)descriptionForError:(NSError*)error;

+ (BOOL)isInternetConnectionError:(NSError*)error;

@end
