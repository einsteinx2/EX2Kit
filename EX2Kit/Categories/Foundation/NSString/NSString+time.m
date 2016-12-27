//
//  NSString-time.m
//  EX2Kit
//
//  Created by Benjamin Baron on 10/30/11.
//  Copyright (c) 2011 Ben Baron. All rights reserved.
//

#import "NSString+time.h"

@implementation NSString (time)

+ (NSString *)formatTime:(double)seconds
{	
	if (seconds <= 0)
		return @"0:00";

	NSUInteger roundedSeconds = floor(seconds);
	
	int mins = (int) roundedSeconds / 60;
	int secs = (int) roundedSeconds % 60;
	if (secs < 10)
		return [NSString stringWithFormat:@"%i:0%i", mins, secs];
	else
		return [NSString stringWithFormat:@"%i:%i", mins, secs];
}

+ (NSString *)formatTimeHoursMinutes:(double)seconds hideHoursIfZero:(BOOL)hideHoursIfZero
{
	if (seconds <= 0)
		return  hideHoursIfZero ? @"00m" : @"0h00m";
    
	NSUInteger roundedSeconds = floor(seconds);
	
    int hours = (int) roundedSeconds / 3600;
	int mins = (int) (roundedSeconds % 3600) / 60;
    if (hideHoursIfZero && hours == 0)
    {
        if (mins < 10)
            return [NSString stringWithFormat:@"0%im", mins];
        else
            return [NSString stringWithFormat:@"%im", mins];
    }
    else
    {
        if (mins < 10)
            return [NSString stringWithFormat:@"%ih0%im", hours, mins];
        else
            return [NSString stringWithFormat:@"%ih%im", hours, mins];
    }
}

+ (NSString *)formatTimeDecimalHours:(double)seconds
{
	if (seconds <= 0)
		return @"0:00";
    
    if (seconds < 3600.)
    {
        // For less than an hour, show 00:00 style
        return [self formatTime:seconds];
    }
	else
    {
        // For an hour or greater, show decimal format
        double hours = seconds / 60. / 60.;
        return [NSString stringWithFormat:@"%.1f %@", hours, NSLocalizedString(@"hrs", @"EX2Kit format time, hours string")];
    }
}

// Return the time since the date provided, formatted in English
+ (NSString *)relativeTime:(NSDate *)date
{
	NSTimeInterval timeSinceDate = [[NSDate date] timeIntervalSinceDate:date];
	NSInteger time;
	
	if ([date isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]])
	{
		return @"never";
	}
	if ([self timeIntervalLessThanOneMinute:timeSinceDate])
	{
		return @"just now";
	}
	else if ([self timeIntervalIsLessThanOneHour:timeSinceDate])
	{
		time = (NSInteger)(timeSinceDate / [self minuteInSeconds]);
		
		if (time == 1)
			return @"1 minute ago";
		else
			return [NSString stringWithFormat:@"%ld minutes ago", (long)time];
	}
	else if ([self timeIntervalIsLessThanOneDay:timeSinceDate])
	{
		time = (NSInteger)(timeSinceDate / [self hourInSeconds]);
		
		if (time == 1)
			return @"1 hour ago";
		else
			return [NSString stringWithFormat:@"%ld hours ago", (long)time];
	}	
	else if ([self timeIntervalIsLessThanOneWeek:timeSinceDate])
	{
		time = (NSInteger)(timeSinceDate / [self dayInSeconds]);
		
		if (time == 1)
			return @"1 day ago";
		else
			return [NSString stringWithFormat:@"%ld days ago", (long)time];
	}
	else if ([self timeIntervalIsLessThanOneMonth:timeSinceDate])
	{
		time = (NSInteger)(timeSinceDate / [self weekInSeconds]);
		
		if (time == 1)
			return @"1 week ago";
		else
			return [NSString stringWithFormat:@"%ld weeks ago", (long)time];
	}
	else
	{
		time = (NSInteger)(timeSinceDate / [self monthInSeconds]);
		
		if (time == 1)
			return @"1 month ago";
		else
			return [NSString stringWithFormat:@"%ld months ago", (long)time];
	}
	
	return @"";
}

+ (NSString *)shortRelativeDateFromDate:(NSDate *)date
{
    NSTimeInterval timeSinceDate = [[NSDate date] timeIntervalSinceDate:date];
    if ([self timeIntervalLessThanOneMinute:timeSinceDate])
    {
        return NSLocalizedString(@"now", nil);
    }
    else if ([self timeIntervalIsLessThanOneHour:timeSinceDate])
    {
        NSInteger time = (NSInteger)(timeSinceDate / [self minuteInSeconds]);
        return [NSString stringWithFormat:@"%ldm", (long)time];
    }
    else if ([self timeIntervalIsLessThanOneDay:timeSinceDate])
    {
        NSInteger time = (NSInteger)(timeSinceDate / [self hourInSeconds]);
        return [NSString stringWithFormat:@"%ldh", (long)time];
    }
    else if ([self timeIntervalIsLessThanOneWeek:timeSinceDate])
    {
        NSInteger time = (NSInteger)(timeSinceDate / [self dayInSeconds]);
        return [NSString stringWithFormat:@"%ldd", (long)time];
    }
    else if ([self timeIntervalIsLessThanOneYear:timeSinceDate])
    {
        NSInteger time = (NSInteger)(timeSinceDate / [self weekInSeconds]);
        return [NSString stringWithFormat:@"%ldw", (long)time];
    }
    else
    {
        NSInteger time = (NSInteger)(timeSinceDate / [self yearInSeconds]);
        return [NSString stringWithFormat:@"%ldy", (long)time];
    }
}

#pragma mark - Time relative time

+ (BOOL)timeIntervalLessThanOneMinute:(NSTimeInterval)timeInterval
{
    return timeInterval <= [self minuteInSeconds];
}

+ (BOOL)timeIntervalIsLessThanOneHour:(NSTimeInterval)timeInterval
{
    return timeInterval <= [self hourInSeconds];
}

+ (BOOL)timeIntervalIsLessThanOneDay:(NSTimeInterval)timeInterval
{
    return timeInterval <= [self dayInSeconds];
}

+ (BOOL)timeIntervalIsLessThanOneWeek:(NSTimeInterval)timeInterval
{
    return timeInterval <= [self weekInSeconds];
}

+ (BOOL)timeIntervalIsLessThanOneMonth:(NSTimeInterval)timeInterval
{
    return timeInterval <= [self monthInSeconds];
}

+ (BOOL)timeIntervalIsLessThanOneYear:(NSTimeInterval)timeInterval
{
    return timeInterval <= [self yearInSeconds];
}

#pragma mark - Conversion

+ (NSInteger)minuteInSeconds
{
    return 60;
}

+ (NSInteger)hourInSeconds
{
    return [self minuteInSeconds] * 60;
}

+ (NSInteger)dayInSeconds
{
    return [self hourInSeconds] * 24;
}

+ (NSInteger)weekInSeconds
{
    return [self dayInSeconds] * 7;
}

+ (NSInteger)monthInSeconds
{
    return [self dayInSeconds] * 30;
}

+ (NSInteger)yearInSeconds
{
    return [self weekInSeconds] * 52;
}

@end
