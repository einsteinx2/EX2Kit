//
//  EX2SlidingNotification.h
//  EX2Kit
//
//  Created by Ben Baron on 4/17/12.
//  Copyright (c) 2012 Anghami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface EX2SlidingNotification : UIViewController

- (id)initOnView:(UIView *)theParentView message:(NSString *)theMessage displayTime:(NSTimeInterval)time;

+ (id)slidingNotificationOnMainWindowWithMessage:(NSString *)theMessage;
+ (id)slidingNotificationOnTopViewWithMessage:(NSString *)theMessage;

+ (id)slidingNotificationOnView:(UIView *)theParentView message:(NSString *)theMessage;
- (id)initOnView:(UIView *)theParentView message:(NSString *)theMessage;

// Allow user to set main window explicitly instead of trying to figure it out each time
+ (void)setMainWindow:(UIWindow *)mainWindow;
+ (UIWindow *)mainWindow;

+ (BOOL)isThrottlingEnabled;
+ (void)setIsThrottlingEnabled:(BOOL)throttlingEnabled;

@property (nonatomic, strong) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;

@property (nonatomic, strong) UIView *parentView;
@property (nonatomic, copy) NSString *message;

@property NSTimeInterval displayTime;

@property (nonatomic, strong) IBOutlet UIButton *tapButton;

@property (copy) void (^tapBlock)(void);
@property (copy) void (^closeBlock)(void);

- (BOOL)showAndHideSlidingNotification;
- (BOOL)showAndHideSlidingNotification:(NSTimeInterval)showTime;
- (BOOL)showSlidingNotification;
- (void)hideSlidingNotification;

- (void)sizeToFit;

@end
