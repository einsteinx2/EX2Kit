//
//  NSArray+Plist.m
//  EX2Kit
//
//  Created by Benjamin Baron on 6/19/13.
//
//

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#import "NSArray+Plist.h"

@implementation NSArray (Plist)

- (BOOL)writeToPlist:(NSString *)path
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    if (data)
    {
        return [data writeToFile:path atomically:YES];;
    }
    else
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error)
        {
            DDLogError(@"[NSArray] error writing plist to path: %@  error: %@", path, error);
        }
    }
    return NO;
}

+ (id)readFromPlist:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data)
    {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([array isKindOfClass:[NSArray class]])
        {
            if (self == [NSMutableArray class])
            {
                // We're calling this method on NSMutableArray, so return a mutable array
                return [array mutableCopy];
            }
            else
            {
                // Just return the array
                return array;
            }
        }
    }
    return nil;
}

@end

@implementation NSSet (Plist)

- (BOOL)writeToPlist:(NSString *)path
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    if (data)
    {
        return [data writeToFile:path atomically:YES];;
    }
    else
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error)
        {
            DDLogError(@"[NSArray] error writing plist to path: %@  error: %@", path, error);
        }
    }
    return NO;
}

+ (id)readFromPlist:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data)
    {
        id set = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (data && !set) {
            // In case it was saved as an array but we're trying to read it as a set
            set = [NSArray arrayWithContentsOfFile:path];
        }
        if ([set isKindOfClass:[NSArray class]]) {
            set = [NSSet setWithArray:set];
        }
        if ([set isKindOfClass:[NSSet class]])
        {
            if (self == [NSMutableSet class])
            {
                // We're calling this method on NSMutableSet, so return a mutable set
                return [set mutableCopy];
            }
            else
            {
                // Just return the set
                return set;
            }
        }
    }
    return nil;
}

@end
