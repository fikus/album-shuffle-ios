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
    int albumIndex_;
}

@property (nonatomic, strong) Rdio* rdio;
@property (nonatomic, strong) UIButton *signInButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, copy) NSArray *albums;

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
        self.rdio = [[Rdio alloc] initWithConsumerKey:RDIO_APP_KEY andSecret:RDIO_APP_SECRET delegate:self];
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
    button.frame = CGRectMake(self.view.bounds.size.width-margin-button.bounds.size.width, 40, button.bounds.size.width, button.bounds.size.height);
    [button addTarget:self action:@selector(signInActivated:) forControlEvents:UIControlEventTouchUpInside];
    self.signInButton = button;

    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Next Album" forState:UIControlStateNormal];
    [button sizeToFit];
    CGRect frame = button.frame;
    frame.origin.x = margin;
    frame.origin.y = 100;
    button.frame = frame;
    [button addTarget:self action:@selector(nextAlbumActivated:) forControlEvents:UIControlEventTouchUpInside];
    self.nextButton = button;

    [self.view addSubview:label];
    [self.view addSubview:self.signInButton];
    [self.view addSubview:self.nextButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"rdioAccessToken"];
    if (token) {
        [self.rdio authorizeUsingAccessToken:token fromController:self];
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
    [self.signInButton setTitle:title forState:UIControlStateNormal];
    CGFloat right = self.signInButton.frame.origin.x + self.signInButton.bounds.size.width;
    [self.signInButton sizeToFit];
    self.signInButton.frame = CGRectMake(right-self.signInButton.bounds.size.width, self.signInButton.frame.origin.y, self.signInButton.bounds.size.width, self.signInButton.bounds.size.height);
    self.signInButton.enabled = NO;
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
    self.albums = [(NSArray *)data filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *dict) {
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
    [self.rdio authorizeFromController:self];
}

- (void)nextAlbumActivated:(id)sender
{
    albumIndex_ = (albumIndex_+1) % self.albums.count;
    [self.rdio.player playSource:self.albums[albumIndex_][@"key"]];
}

- (void)loadAlbums
{
    id params = @{@"extras": @"-*,key,canStream"};
    // TODO: Write a new API wrapper with blocks
    [self.rdio callAPIMethod:@"getAlbumsInCollection" withParameters:params delegate:self];
}

- (void)shuffleAlbums
{
    NSMutableArray *ma = [self.albums mutableCopy];
    for (int j = ma.count-1; j > 0; j--) {
        int i = arc4random() % j;
        [ma exchangeObjectAtIndex:j withObjectAtIndex:i];
    }
    self.albums = ma;
}

- (void)playFirstAlbum
{
    if (self.albums.count > 0) {
        [self.rdio.player playSource:self.albums[0][@"key"]];
    }
}

@end
