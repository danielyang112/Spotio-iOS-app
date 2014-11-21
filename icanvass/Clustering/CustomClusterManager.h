//
//  CustomClusterManager.h
//  icanvass
//
//  Created by Dmitriy on 23.09.14.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "GClusterManager.h"

@interface CustomClusterManager : GClusterManager

@property (nonatomic, weak) id <GMSMapViewDelegate> trueDelegate;
@property (nonatomic, assign) BOOL clustered;

@end
