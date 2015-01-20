//
//  myButton.h
//  icanvass
//
//  Created by rakesh on 11/3/14.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface myButton : UIButton{
    
    id userData;
}

@property (nonatomic, readwrite, retain) id userData;

@end
