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
    id target_;
    SEL load_;
    SEL fail_;
}

@end

@implementation EFRdioRequestDelegate

- (id)initWithTarget:(id)target loadSelector:(SEL)load failSelector:(SEL)fail
{
    self = [self init];
    if (self) {
        target_ = target;
        load_ = load;
        fail_ = fail;
    }
    return self;
}

+ (EFRdioRequestDelegate *)delegateWithTarget:(id)target loadSelector:(SEL)load failSelector:(SEL)fail
{
    return [[EFRdioRequestDelegate alloc] initWithTarget:target loadSelector:load failSelector:fail];
}

- (void)rdioRequest:(RDAPIRequest *)request didFailWithError:(NSError *)error
{
    [target_ performSelector:fail_ withObject:request withObject:error];
}

- (void)rdioRequest:(RDAPIRequest *)request didLoadData:(id)data
{
    [target_ performSelector:load_ withObject:request withObject:data];
}

@end
