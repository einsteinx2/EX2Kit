//
//  UIImage+Cropping.m
//  EX2Kit
//
//  Created by Benjamin Baron on 10/27/12.
//
//

#import "UIImage+Cropping.h"

@implementation UIImage (Cropping)

// Thanks to this SO answer: http://stackoverflow.com/a/712553/299262
- (UIImage *)croppedImage:(CGRect)cropFrame
{
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, cropFrame);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return croppedImage;
}

@end
