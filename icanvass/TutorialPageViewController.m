//
//  TutorialPageViewController.m
//  icanvass
//
//  Created by Roman Kot on 11.08.2014.
//  Copyright (c) 2014 Roman Kot. All rights reserved.
//

#import "TutorialPageViewController.h"

@interface TutorialPageViewController ()
@property (nonatomic,strong) NSArray *images;
@end

@implementation TutorialPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _imageView.image=[UIImage imageNamed:_images[_page]];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setPage:(NSUInteger)page {
    if(!_images){
        _images=@[@"tutorial1",@"tutorial2",@"tutorial3",@"tutorial4"];
    }
    _page=page;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
