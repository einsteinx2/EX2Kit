//
//  EX2GlowButton.m
//  EX2Kit
//
//  Created by Benjamin Baron on 5/21/13.
//
//

#import "EX2GlowButton.h"

#import "UIView+Glow.h"

@implementation EX2GlowButton

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [self startGlowingWithColor:UIColor.whiteColor fromIntensity:1. toIntensity:1. radius:20. overdub:2 animated:NO repeat:NO];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    [self stopGlowingAnimated:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    [self stopGlowingAnimated:YES];
}

@end
