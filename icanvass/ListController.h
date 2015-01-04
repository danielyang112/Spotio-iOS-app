//
//  ListController.h
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pin.h"

@protocol ListControllerDelegate <NSObject>
- (CLLocation*)userLocation;
@end

@interface ListController : UITableViewController<UISearchBarDelegate,NSFetchedResultsControllerDelegate>

@property (nonatomic,weak) id<ListControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end
