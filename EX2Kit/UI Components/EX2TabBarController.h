//
//  EX2TabBarController.h
//  Anghami
//
//  Created by Ben Baron on 8/31/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

// Custom UITabBarController re-implementation for use inside containers
// such as an EX2NotificationBar. Regular UITabBarController does all
// kinds of annoying resizing.

#import <UIKit/UIKit.h>

typedef enum
{
    EX2TabBarControllerAnimationNone = 0,
    EX2TabBarControllerAnimationFadeInOut,
    EX2TabBarControllerAnimationFadeTogether
}
EX2TabBarControllerAnimation;

@class EX2TabBarController;
@interface UIViewController (EX2TabBarController)
@property (nonatomic, unsafe_unretained) EX2TabBarController *ex2TabBarController;
@end

@interface EX2TabBarController : UIViewController <UITabBarDelegate>

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UITabBar *tabBar;

@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic) EX2TabBarControllerAnimation animation;

@end
