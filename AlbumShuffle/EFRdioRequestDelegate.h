//
//  EFRdioRequestDelegate.h
//  AlbumShuffle
//
//  Created by Eric Fikus on 4/24/14.
//  Copyright (c) 2014 Eric Fikus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Rdio/Rdio.h>

@interface EFRdioRequestDelegate : NSObject <RDAPIRequestDelegate>

typedef void (^LoadedHandler)(RDAPIRequest *, id);
typedef void (^FailedHandler)(RDAPIRequest *, NSError *);

- (id)initWithLoadedHandler:(LoadedHandler)loadedHandler failedHandler:(FailedHandler)failedHandler;

+ (EFRdioRequestDelegate *)delegateWithLoadedHandler:(LoadedHandler)loadedHandler failedHandler:(FailedHandler)failedHandler;

@end
