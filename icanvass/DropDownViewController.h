//
//  DropDownViewController.h
//  icanvass
//
//  Created by Roman Kot on 31.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DropDownViewController;
@protocol DropDownDelegate <NSObject>
- (void)dropDown:(DropDownViewController*)dropDown changedTo:(NSString*)value;
@end

@interface DropDownViewController : UITableViewController
@property (nonatomic,weak) id<DropDownDelegate> delegate;
@property (nonatomic,strong) NSArray *options;
@property (nonatomic,strong) NSIndexPath *indexPath;
@end
