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
    _field.hidden=!editing;
    _top.hidden=editing;
    _bottom.hidden=editing;
}

@end

@implementation DetailsNotesCell

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    _note.hidden=!editing;
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
    self.field.text=[NSString stringWithFormat:@"%.0f",sender.value];
}

@end

@implementation DetailsDateCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    self.top.hidden=NO;
    self.bottom.hidden=NO;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.editingAccessoryType=enabled?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
//    self.accessoryType=enabled?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
}

@end

@implementation DetailsDropDownCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    self.top.hidden=NO;
    self.bottom.hidden=NO;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.editingAccessoryType=enabled?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
//    self.accessoryType=enabled?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
}

@end

