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
    [self startGlowingWithColor:UIColor.whiteColor fromIntensity:1. toIntensity:1. radius:20. overdub:3 animated:NO repeat:NO];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self stopGlowing];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self stopGlowing];
}

@end
