//
//  EFRdioRequestDelegate.m
//  AlbumShuffle
//
//  Created by Eric Fikus on 4/24/14.
//  Copyright (c) 2014 Eric Fikus. All rights reserved.
//

#import "EFRdioRequestDelegate.h"

@interface EFRdioRequestDelegate ()
{
    LoadedHandler load_;
    FailedHandler fail_;
}

@end

@implementation EFRdioRequestDelegate

- (id)initWithLoadedHandler:(LoadedHandler)loadedHandler failedHandler:(FailedHandler)failedHandler
{
    self = [self init];
    if (self) {
        load_ = loadedHandler;
        fail_ = failedHandler;
    }
    return self;
}

+ (EFRdioRequestDelegate *)delegateWithLoadedHandler:(LoadedHandler)loadedHandler failedHandler:(FailedHandler)failedHandler
{
    return [[EFRdioRequestDelegate alloc] initWithLoadedHandler:loadedHandler failedHandler:failedHandler];
}

- (void)rdioRequest:(RDAPIRequest *)request didFailWithError:(NSError *)error
{
    fail_(request, error);
}

- (void)rdioRequest:(RDAPIRequest *)request didLoadData:(id)data
{
    load_(request, data);
}

@end
