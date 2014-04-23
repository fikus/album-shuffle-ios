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

@interface EFAlbumShuffleViewController () <RdioDelegate, RDAPIRequestDelegate, RDPlayerDelegate>
{
    int albumIndex_;
}

@property (nonatomic, strong) Rdio* rdio;
@property (nonatomic, strong) UIButton *signInButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *nextTrackButton;
@property (nonatomic, strong) UIButton *previousTrackButton;
@property (nonatomic, strong) UIButton *nowPlayingButton;
@property (nonatomic, copy) NSArray *albums;

- (void)loadAlbums;
- (void)shuffleAlbums;
- (void)playFirstAlbum;
- (UIButton *)createControlButtonWithTitle:(NSString *)title action:(SEL)action;

@end

@implementation EFAlbumShuffleViewController

#pragma mark -
#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.rdio = [[Rdio alloc] initWithConsumerKey:RDIO_APP_KEY andSecret:RDIO_APP_SECRET delegate:self];
        self.rdio.player.delegate = self;

        [self.rdio.player addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [self.rdio.player removeObserver:self forKeyPath:@"currentTrack"];
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
    [button setTitle:@"Now playing: " forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(margin, 140, button.bounds.size.width, button.bounds.size.height);
    [button addTarget:self action:@selector(nowPlayingActivated:) forControlEvents:UIControlEventTouchUpInside];
    self.nowPlayingButton = button;

    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Next Album" forState:UIControlStateNormal];
    [button sizeToFit];
    CGRect frame = button.frame;
    frame.origin.x = margin;
    frame.origin.y = 100;
    button.frame = frame;
    [button addTarget:self action:@selector(nextAlbumActivated:) forControlEvents:UIControlEventTouchUpInside];
    self.nextButton = button;

    button = [self createControlButtonWithTitle:@" " action:@selector(playPauseActivated:)];
    CGFloat left = (floor)(self.view.bounds.size.width/2 - button.bounds.size.width/2);
    button.frame = CGRectMake(left, 400, button.bounds.size.width, button.bounds.size.height);
    self.playPauseButton = button;

    button = [self createControlButtonWithTitle:@"<<" action:@selector(previousTrackActivated:)];
    button.frame = CGRectMake(margin, 400, button.bounds.size.width, button.bounds.size.height);
    self.previousTrackButton = button;

    button = [self createControlButtonWithTitle:@">>" action:@selector(nextTrackActivated:)];
    button.frame = CGRectMake(self.view.bounds.size.width-margin-button.bounds.size.width, 400, button.bounds.size.width, button.bounds.size.height);
    self.nextTrackButton = button;

    [self.view addSubview:label];
    [self.view addSubview:self.signInButton];
    [self.view addSubview:self.nextButton];
    [self.view addSubview:self.nowPlayingButton];
    [self.view addSubview:self.playPauseButton];
    [self.view addSubview:self.previousTrackButton];
    [self.view addSubview:self.nextTrackButton];
}

- (UIButton *)createControlButtonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:40];
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

    return button;
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
#pragma mark RDPlayerDelegate

- (void)rdioPlayerChangedFromState:(RDPlayerState)oldState toState:(RDPlayerState)newState
{
    NSString *title;
    if (newState == RDPlayerStatePlaying) {
        title = @"||";
    } else if (newState == RDPlayerStateInitializing || newState == RDPlayerStateStopped) {
        title = @" ";
    } else {
        title = @">";
    }
    [self.playPauseButton setTitle:title forState:UIControlStateNormal];
}

- (BOOL)rdioIsPlayingElsewhere
{
    return NO;
}


#pragma mark -
#pragma mark Player control

- (void)playPauseActivated:(id)sender
{
    [self.rdio.player togglePause];
}

- (void)previousTrackActivated:(id)sender
{
    [self.rdio.player previous];
}

- (void)nextTrackActivated:(id)sender
{
    [self.rdio.player next];
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

- (void)nowPlayingActivated:(id)sender
{
    NSString *track = self.rdio.player.currentTrack;
    if (track.length) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://m.rdio.com/api/json/get/?keys=%@", track]];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.rdio.player) {
        if ([keyPath isEqualToString:@"currentTrack"]) {
            NSString *track = self.rdio.player.currentTrack;
            NSString *title = [NSString stringWithFormat:@"Now playing: %@", track];
            [self.nowPlayingButton setTitle:title forState:UIControlStateNormal];
            [self.nowPlayingButton sizeToFit];
        }
    }
}

@end
