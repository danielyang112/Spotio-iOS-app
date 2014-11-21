//
//  PinCell.h
//  icanvass
//
//  Created by Roman Kot on 17.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PinCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *icon;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;

@end
