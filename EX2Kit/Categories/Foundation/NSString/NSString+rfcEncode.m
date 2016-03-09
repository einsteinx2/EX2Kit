//
//  NSString-rfcEncode.m
//  EX2Kit
//
//  Created by Ben Baron on 12/7/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "NSString+rfcEncode.h"

// TODO: Fix __bridges

@implementation NSString (RFC3875)

- (NSString *)stringByAddingRFC3875PercentEscapes 
{
    // CFURLCreateStringByAddingPercentEscapes is now deprecated. We use stringByAddingPercentEncodingWithAllowedCharacters that always uses UTF8.
	return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@";/?:@&=$+{}<>,"]];
}

@end
