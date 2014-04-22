//
//  EFAlbumShuffleViewController.m
//  AlbumShuffle
//
//  Created by Eric Fikus on 4/21/14.
//  Copyright (c) 2014 Eric Fikus. All rights reserved.
//

#import "EFAlbumShuffleViewController.h"

@interface EFAlbumShuffleViewController ()

@end

@implementation EFAlbumShuffleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, self.view.bounds.size.width, 40)];
    label.text = @"Album Shuffle";
    label.textColor = [UIColor darkTextColor];
    
    [self.view addSubview:label];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
}

@end
