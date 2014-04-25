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
#import "EFRdioRequestDelegate.h"

#import "UIKit+AFNetworking.h"

@interface EFAlbumShuffleViewController () <RdioDelegate, RDPlayerDelegate>
{
    int albumIndex_;

    EFRdioRequestDelegate *collectionDelegate_;
    EFRdioRequestDelegate *trackRequestDelegate_;
}

@property (nonatomic, strong) Rdio *rdio;
@property (nonatomic, strong) UIButton *signInButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *nextTrackButton;
@property (nonatomic, strong) UIButton *previousTrackButton;
@property (nonatomic, strong) UIButton *nowPlayingButton;
@property (nonatomic, copy) NSArray *albums;
@property (nonatomic, strong) NSDictionary *currentTrack;
@property (nonatomic, strong) UIImageView *backgroundImage;
@property (nonatomic, strong) UIImageView *albumImage;
@property (nonatomic, copy) NSString *albumImageUrlString;

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

    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor whiteColor];

    CGFloat margin = 20;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(margin, 60, self.view.bounds.size.width-2*margin, 40)];
    label.text = @"Album Shuffle";
    label.textColor = self.view.tintColor;

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

    CGFloat buttonTop = 500;

    button = [self createControlButtonWithTitle:@" " action:@selector(playPauseActivated:)];
    CGFloat left = (floor)(self.view.bounds.size.width/2 - button.bounds.size.width/2);
    button.frame = CGRectMake(left, buttonTop, button.bounds.size.width, button.bounds.size.height);
    self.playPauseButton = button;

    button = [self createControlButtonWithTitle:@"<<" action:@selector(previousTrackActivated:)];
    button.frame = CGRectMake(margin, buttonTop, button.bounds.size.width, button.bounds.size.height);
    self.previousTrackButton = button;

    button = [self createControlButtonWithTitle:@">>" action:@selector(nextTrackActivated:)];
    button.frame = CGRectMake(self.view.bounds.size.width-margin-button.bounds.size.width, buttonTop, button.bounds.size.width, button.bounds.size.height);
    self.nextTrackButton = button;

    CGFloat imageSize = self.view.bounds.size.width - 2*margin;
    self.albumImage = [[UIImageView alloc] initWithFrame:CGRectMake(margin, 200, imageSize, imageSize)];

    CGFloat bgImageSize = self.view.bounds.size.height + 100;
    self.backgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, bgImageSize, bgImageSize)];
    self.backgroundImage.center = self.view.center;

    UIView *shade = [[UIView alloc] initWithFrame:self.backgroundImage.bounds];
    shade.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.backgroundImage addSubview:shade];

    [self.view addSubview:self.backgroundImage];
    [self.view addSubview:label];
    [self.view addSubview:self.signInButton];
    [self.view addSubview:self.nextButton];
    [self.view addSubview:self.nowPlayingButton];
    [self.view addSubview:self.playPauseButton];
    [self.view addSubview:self.previousTrackButton];
    [self.view addSubview:self.nextTrackButton];
    [self.view addSubview:self.albumImage];
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
#pragma mark API Request Handlers

- (void)albumsInCollectionRequest:(RDAPIRequest *)request didLoad:(id)data
{
    // Get the streamable albums from the collection
    self.albums = [(NSArray *)data filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *dict) {
        return [[obj valueForKey:@"canStream"] boolValue];
    }]];

    [self shuffleAlbums];
    [self playFirstAlbum];
}

- (void)trackRequest:(RDAPIRequest *)request didLoad:(id)data
{
    NSDictionary *response = data;
    NSString *currentTrack = [self.rdio.player currentTrack];

    NSDictionary *responseTrack = response[currentTrack];
    if (responseTrack) {
        self.currentTrack = responseTrack;
        NSString *name = responseTrack[@"name"];
        NSString *buttonTitle = [NSString stringWithFormat:@"Now playing: %@", name];
        [self.nowPlayingButton setTitle:buttonTitle forState:UIControlStateNormal];
        [self.nowPlayingButton sizeToFit];

        NSString *iconUrlString = responseTrack[@"bigIcon"];
        if (iconUrlString != self.albumImageUrlString) {
            id url = [NSURL URLWithString:iconUrlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            __weak typeof(self) weakSelf = self;
            [self.albumImage setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                weakSelf.albumImage.image = image;
                // Update background image with blurred album art
                [weakSelf updateBackgroundImageFromImage:image];
            } failure:NULL];
            self.albumImageUrlString = iconUrlString;
        }
    }
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
    collectionDelegate_ = [EFRdioRequestDelegate delegateWithTarget:self
                                               loadSelector:@selector(albumsInCollectionRequest:didLoad:)
                                               failSelector:@selector(rdioRequest:didFailWithError:)];
    [self.rdio callAPIMethod:@"getAlbumsInCollection" withParameters:params delegate:collectionDelegate_];
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
    NSString *urlString;
    if ((urlString = self.currentTrack[@"shortUrl"])) {
        NSURL *url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.rdio.player) {
        if ([keyPath isEqualToString:@"currentTrack"]) {
            NSString *track = self.rdio.player.currentTrack;
            if (!track) {
                return;
            }
            if (!trackRequestDelegate_) {
                trackRequestDelegate_ = [EFRdioRequestDelegate delegateWithTarget:self
                                                                     loadSelector:@selector(trackRequest:didLoad:)
                                                                     failSelector:@selector(rdioRequest:didFailWithError:)];
            }
            id params = @{@"keys": track, @"extras": @"-*,name,shortUrl,bigIcon"};
            [self.rdio callAPIMethod:@"get" withParameters:params delegate:trackRequestDelegate_];
        }
    }
}

- (void)updateBackgroundImageFromImage:(UIImage *)image
{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputCGImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputCGImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:20.0f] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGRect extent = [result extent];
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    self.backgroundImage.image = [UIImage imageWithCGImage:cgImage];
}

@end
