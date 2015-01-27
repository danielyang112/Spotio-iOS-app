//
//  LayerView.m
//  icanvass
//
//  Created by Alex on 1/26/15.
//  Copyright (c) 2015 Roman Kot. All rights reserved.
//

#import "LayerView.h"

@implementation LayerView

+ (instancetype)loadLayerView {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
    LayerView *layerView = [nib instantiateWithOwner:self options:nil].firstObject;
    return layerView;
}

- (IBAction)onShowSatelliteClicked:(id)sender {
    _satelliteSelected = !_satelliteSelected;
    if (_satelliteSelected) {
        self.imageSatellite.image = [UIImage imageNamed:@"filter_checked"];
    } else {
        self.imageSatellite.image = [UIImage imageNamed:@"filter_unchecked"];
    }
    NSInteger on=_satelliteSelected?1:0;
    [[NSUserDefaults standardUserDefaults] setObject:@(on) forKey:@"Satellite"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICMapSettings" object:nil userInfo:nil];
}

- (IBAction)onShowTerritoryClicked:(id)sender {
    _territorySelected = !_territorySelected;
    if (_territorySelected) {
        self.imageTerritory.image = [UIImage imageNamed:@"filter_checked"];
    } else {
        self.imageTerritory.image = [UIImage imageNamed:@"filter_unchecked"];
    }
    NSInteger on=_territorySelected?1:0;
    [[NSUserDefaults standardUserDefaults] setObject:@(on) forKey:@"Territory"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ICTerritories" object:nil];
}

- (IBAction)onCloseClicked:(id)sender {
    [self removeFromSuperview];
}

- (void)setSatelliteSelected:(BOOL)satelliteSelected {
    _satelliteSelected = satelliteSelected;
    if (_satelliteSelected) {
        self.imageSatellite.image = [UIImage imageNamed:@"filter_checked"];
    } else {
        self.imageSatellite.image = [UIImage imageNamed:@"filter_unchecked"];
    }
}

- (void)setTerritorySelected:(BOOL)territorySelected {
    _territorySelected = territorySelected;
    if (_territorySelected) {
        self.imageTerritory.image = [UIImage imageNamed:@"filter_checked"];
    } else {
        self.imageTerritory.image = [UIImage imageNamed:@"filter_unchecked"];
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
