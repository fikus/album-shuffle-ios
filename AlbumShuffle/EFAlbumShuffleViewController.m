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

@interface EFAlbumShuffleViewController () <RdioDelegate, RDAPIRequestDelegate>
{
    Rdio *rdio;
    
    UIButton *sign_in_button;
    
    UIButton *next_button;
    
    NSArray *albums;
    
    int album_index;
}

- (void)loadAlbums;
- (void)shuffleAlbums;
- (void)playFirstAlbum;

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
    
    sign_in_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sign_in_button setTitle:@"Sign In" forState:UIControlStateNormal];
    [sign_in_button sizeToFit];
    sign_in_button.frame = CGRectMake(self.view.bounds.size.width-margin-sign_in_button.bounds.size.width, 40, sign_in_button.bounds.size.width, sign_in_button.bounds.size.height);
    [sign_in_button addTarget:self action:@selector(signInActivated:) forControlEvents:UIControlEventTouchUpInside];
    
    next_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [next_button setTitle:@"Next Album" forState:UIControlStateNormal];
    [next_button sizeToFit];
    CGRect frame = next_button.frame;
    frame.origin.x = margin;
    frame.origin.y = 100;
    next_button.frame = frame;
    [next_button addTarget:self action:@selector(nextAlbumActivated:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:label];
    [self.view addSubview:sign_in_button];
    [self.view addSubview:next_button];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"rdioAccessToken"];
    if (token) {
        [rdio authorizeUsingAccessToken:token fromController:self];
    }
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
    NSLog(@"rdioDidAuthorizeUser: %@", user[@"firstName"]);
    
    NSString *title = [NSString stringWithFormat:@"Signed in as %@ %@", user[@"firstName"], user[@"lastName"]];
    [sign_in_button setTitle:title forState:UIControlStateNormal];
    CGFloat right = sign_in_button.frame.origin.x + sign_in_button.bounds.size.width;
    [sign_in_button sizeToFit];
    sign_in_button.frame = CGRectMake(right-sign_in_button.bounds.size.width, sign_in_button.frame.origin.y, sign_in_button.bounds.size.width, sign_in_button.bounds.size.height);
    sign_in_button.enabled = NO;
    [self loadAlbums];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:@"rdioAccessToken"];
    [defaults synchronize];
}

#pragma mark -
#pragma mark RDAPIRequestDelegate

- (void)rdioRequest:(RDAPIRequest *)request didLoadData:(id)data
{
    // This is the response from getAlbumsInCollection

    // Get the streamable albums from the collection
    albums = [(NSArray *)data filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *dict) {
        return [[obj valueForKey:@"canStream"] boolValue];
    }]];
    
    [self shuffleAlbums];
    [self playFirstAlbum];
}

- (void)rdioRequest:(RDAPIRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Request failed: %@", error.description);
}

#pragma mark -

- (void)signInActivated:(id)sender
{
    [rdio authorizeFromController:self];
}

- (void)nextAlbumActivated:(id)sender
{
    album_index = (album_index+1) % albums.count;
    [rdio.player playSource:albums[album_index][@"key"]];
}

- (void)loadAlbums
{
    id params = @{@"extras": @"-*,key,canStream"};
    // TODO: Write a new API wrapper with blocks
    [rdio callAPIMethod:@"getAlbumsInCollection" withParameters:params delegate:self];
}

- (void)shuffleAlbums
{
    NSMutableArray *ma = [albums mutableCopy];
    for (int j = ma.count-1; j > 0; j--) {
        int i = arc4random() % j;
        [ma exchangeObjectAtIndex:j withObjectAtIndex:i];
    }
    albums = ma;
}

- (void)playFirstAlbum
{
    if (albums.count > 0) {
        [rdio.player playSource:albums[0][@"key"]];
    }
}

@end
