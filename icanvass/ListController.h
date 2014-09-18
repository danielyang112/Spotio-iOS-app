//
//  ListController.h
//  icanvass
//
//  Created by Roman Kot on 08.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pin.h"

@interface ListController : UITableViewController<UISearchBarDelegate,NSFetchedResultsControllerDelegate>


@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end
