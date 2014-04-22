//
//  EFAlbumShuffleViewController.m
//  AlbumShuffle
//
//  Created by Eric Fikus on 4/21/14.
//  Copyright (c) 2014 Eric Fikus. All rights reserved.
//

#import <Rdio/Rdio.h>

#import "EFAlbumShuffleViewController.h"
#import "EFRdioSettings.h"

@interface EFAlbumShuffleViewController () <RdioDelegate>
{
    Rdio *rdio;
}

@end

@implementation EFAlbumShuffleViewController

#pragma mark -
#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        rdio = [[Rdio alloc] initWithConsumerKey:RDIO_APP_KEY andSecret:RDIO_APP_SECRET delegate:self];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    CGFloat margin = 20;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(margin, 60, self.view.bounds.size.width-2*margin, 40)];
    label.text = @"Album Shuffle";
    label.textColor = [UIColor darkTextColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Sign In" forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(self.view.bounds.size.width-margin-button.bounds.size.width, 60, button.bounds.size.width, button.bounds.size.height);
    [button addTarget:self action:@selector(signInActivated:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:label];
    [self.view addSubview:button];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark RdioDelegate

- (void)rdioAuthorizationFailed:(NSString *)error
{
    NSLog(@"rdioAuthorizationFailed: %@", error);
}

- (void)rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken
{
    NSLog(@"rdioDidAuthorizeUser: %@", [user objectForKey:@"firstName"]);
}

#pragma mark -

- (void)signInActivated:(id)sender
{
    [rdio authorizeFromController:self];
}

@end
