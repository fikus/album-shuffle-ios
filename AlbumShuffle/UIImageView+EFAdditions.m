//
//  UIImageView+EFExtensions.m
//  AlbumShuffle
//
//  Created by Eric Fikus on 4/24/14.
//  Copyright (c) 2014 Eric Fikus. All rights reserved.
//

#import "UIImageView+EFAdditions.h"

@implementation UIImageView (EFAdditions)

- (void)applyBlurFromImage:(UIImage *)image
{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputCGImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputCGImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:20.0f] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGRect extent = [result extent];
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    self.image = [UIImage imageWithCGImage:cgImage];
}

@end
