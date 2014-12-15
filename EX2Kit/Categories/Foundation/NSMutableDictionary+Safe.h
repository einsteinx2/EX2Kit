//
//  NSMutableDictionary+Safe.h
//  EX2Kit
//
//  Created by Ben Baron on 9/15/12.
//  Copyright (c) 2012 Anghami. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Safe)

- (void)setObjectSafe:(id)object forKey:(id)key;

@end
