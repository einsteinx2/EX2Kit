//
//  NSString+URLEncode.m
//  EX2Kit
//
//  Created by Benjamin Baron on 10/31/11.
//  Copyright (c) 2011 Ben Baron. All rights reserved.
//

#import "NSString+URLEncode.h"
#import <Foundation/NSURL.h>

@implementation NSString (URLEncode)

+ (NSString *)URLEncodeString:(NSString *)string 
{
    NSString * legalString = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:legalString]];
}

- (NSString *)URLEncodeString 
{ 
    return [NSString URLEncodeString:self]; 
}

- (NSString *)URLDecode
{
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, CFSTR(""));
}

@end
