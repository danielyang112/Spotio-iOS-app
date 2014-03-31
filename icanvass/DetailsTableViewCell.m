//
//  DetailsTableViewCell.m
//  icanvass
//
//  Created by Roman Kot on 30.03.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "DetailsTableViewCell.h"

@implementation DetailsTableViewCell

- (void)setEnabled:(BOOL)enabled {
    _enabled=enabled;
    _field.enabled=enabled;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    _field.enabled=editing;
    _field.borderStyle=editing?UITextBorderStyleRoundedRect:UITextBorderStyleNone;
}

@end

@implementation DetailsStreetNumberCell

- (void)awakeFromNib {
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    _stepper.hidden=!editing;
}

- (IBAction)textFieldDidChange:(UITextField*)sender {
///    NSInteger number=[sender.text doubleValue];
    _stepper.value=[sender.text doubleValue];
}

- (IBAction)stepperChanged:(UIStepper*)sender {
    //[self.field endEditing:YES];
    self.field.text=[NSString stringWithFormat:@"%.0f",sender.value];
}

@end

@implementation DetailsDateCell

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.editingAccessoryType=enabled?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
    self.accessoryType=enabled?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
}

@end

