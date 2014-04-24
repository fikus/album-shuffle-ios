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

- (id)initWithTarget:(id)target loadSelector:(SEL)load failSelector:(SEL)fail;

+ (EFRdioRequestDelegate *)delegateWithTarget:(id)target loadSelector:(SEL)load failSelector:(SEL)fail;

@end
