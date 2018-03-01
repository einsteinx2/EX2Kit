//
//  EX2ANGLogger.h
//  EX2Kit
//
//  Created by Apple on 3/1/18.
//

#import <Foundation/Foundation.h>

#define kNotificationLogRequest @"kNotificationLogRequest"

@interface EX2ANGLogger : NSObject

+ (void)log:(NSString *)format, ...;
+ (void)logError:(NSString *)format, ...;
+ (void)logInfo:(NSString *)format, ...;

@end
