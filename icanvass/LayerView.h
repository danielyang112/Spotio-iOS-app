//
//  LayerView.h
//  icanvass
//
//  Created by Alex on 1/26/15.
//  Copyright (c) 2015 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LayerView : UIView

+ (instancetype)loadLayerView;

@property (weak, nonatomic) IBOutlet UIImageView *imageSatellite;
@property (weak, nonatomic) IBOutlet UIImageView *imageTerritory;

@property (nonatomic, assign) BOOL satelliteSelected;
@property (nonatomic, assign) BOOL territorySelected;

- (IBAction)onShowSatelliteClicked:(id)sender;
- (IBAction)onShowTerritoryClicked:(id)sender;
- (IBAction)onCloseClicked:(id)sender;

@end
