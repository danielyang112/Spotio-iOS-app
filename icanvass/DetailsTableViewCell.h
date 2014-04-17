//
//  DetailsTableViewCell.h
//  icanvass
//
//  Created by Roman Kot on 30.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsTableViewCell : UITableViewCell
@property (nonatomic,weak) IBOutlet UITextField *field;
@property (nonatomic) BOOL enabled;
@property (weak, nonatomic) IBOutlet UILabel *top;
@property (weak, nonatomic) IBOutlet UITextView *bottom;
@end

@interface DetailsStreetNumberCell : DetailsTableViewCell
@property (nonatomic,weak) IBOutlet UIStepper *stepper;
- (IBAction)textFieldDidChange:(UITextField*)sender;
- (IBAction)stepperChanged:(UIStepper*)sender;
@end

@interface DetailsDateCell : DetailsTableViewCell

@end

@interface DetailsDropDownCell : DetailsTableViewCell

@end