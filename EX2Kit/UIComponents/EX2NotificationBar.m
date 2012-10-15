//
//  EX2NotificationBar.m
//
//  Created by Ben Baron on 4/17/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "UIView+Tools.h"
#import "EX2NotificationBar.h"
#import "EX2Macros.h"

#define DEFAULT_HIDE_DURATION 5.0
#define ANIMATE_DUR 0.3
#define DEFAULT_BAR_HEIGHT 30.
#define SMALL_STATUS_HEIGHT 20.
#define LARGE_STATUS_HEIGHT 40.
#define ACTUAL_STATUS_HEIGHT [[UIApplication sharedApplication] statusBarFrame].size.height

@interface EX2NotificationBar()
{
    EX2NotificationBarPosition _position;
    __strong UIViewController *_mainViewController;
}
@property (nonatomic) BOOL wasStatusBarTallOnStart;
@property (nonatomic) BOOL changedTabSinceTallHeight;
@property (nonatomic) BOOL hasViewWillAppearRan;
@end

@implementation EX2NotificationBar

#pragma mark - Life Cycle

- (void)setup
{
	_notificationBarHeight = DEFAULT_BAR_HEIGHT;
	_position = EX2NotificationBarPositionTop;
}

- (id)initWithPosition:(EX2NotificationBarPosition)thePosition
{
	if ((self = [super initWithNibName:@"EX2NotificationBar" bundle:nil]))
	{
		[self setup];
		_position = thePosition;
	}
	return self;
}

- (id)init
{
	return [self initWithPosition:EX2NotificationBarPositionTop];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self init];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
		[self setup];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    	
	// Setup the main view controller if it was done before the XIB loaded
	self.mainViewController = self.mainViewController;
    
    // Register for status bar frame changes
    //[NSNotificationCenter defaultCenter]
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChange:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// In iOS 4 make sure to pass this message
	if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
	{
		[self.mainViewController viewWillAppear:animated];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// In iOS 4 make sure to pass this message
	if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
	{
		[self.mainViewController viewWillDisappear:animated];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// In iOS 4 make sure to pass this message
	if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
	{
		[self.mainViewController viewDidAppear:animated];
	}
    
    // Fix for modal view controller dismissal positioning
    if ([self.mainViewController isKindOfClass:[UITabBarController class]])
    {
        UITabBarController *tabController = (UITabBarController *)self.mainViewController;
        if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
            if (ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT)
            {
                [UIView animateWithDuration:.2 animations:^{
                    
                    CGFloat heightChange = self.isNotificationBarShowing ? LARGE_STATUS_HEIGHT : SMALL_STATUS_HEIGHT;
                    
                    if (self.hasViewWillAppearRan)
                    {
                        CGRect theFrame = CGRectMake(0., heightChange, navController.visibleViewController.view.width, navController.visibleViewController.view.height - heightChange);
                        navController.visibleViewController.view.frame = theFrame;
                    }
                    
                    if (!self.wasStatusBarTallOnStart || self.hasViewWillAppearRan)
                        navController.navigationBar.y += heightChange;
                }];
            }
        }
    }
    
    self.hasViewWillAppearRan = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// In iOS 4 make sure to pass this message
	if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
	{
		[self.mainViewController viewDidDisappear:animated];
	}
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return [self shouldAutorotateToInterfaceOrientation:[UIDevice currentDevice].orientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inOrientation 
{
	// Don't allow rotating while the notification bar is animating
	if (!self.view.userInteractionEnabled)
	{
		return inOrientation == [UIApplication sharedApplication].statusBarOrientation;
	}

	// Otherwise ask the main view controller
	return [self.mainViewController shouldAutorotateToInterfaceOrientation:inOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[self.mainViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
		
	if ([self.mainViewController isKindOfClass:[UITabBarController class]])
	{
		UITabBarController *tabController = (UITabBarController *)self.mainViewController;
		if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
		{
			// Must resize the navigation bar manually because it will only happen automatically when 
			// it's the main window's root view controller
			UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
			navController.navigationBar.height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 44. : 32.;
		}
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	[self.mainViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	if (self.isNotificationBarShowing)
	{
		if ([self.mainViewController isKindOfClass:[UITabBarController class]])
		{
			UITabBarController *tabController = (UITabBarController *)self.mainViewController;
			if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
			{
				// Must shift down the navigation controller after switching tabs
				UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
				//navController.view.y += STATUS_HEIGHT; // attempt to fix the moving down on rotation bug
				navController.view.y = ACTUAL_STATUS_HEIGHT;
			}
		}
	}
}

#pragma mark - Properties

- (EX2NotificationBarPosition)position
{
	return _position;
}

- (void)setPosition:(EX2NotificationBarPosition)thePosition
{
	if (!self.isNotificationBarShowing)
	{
		_position = thePosition;
	}
}

- (UIViewController *)mainViewController
{
	return _mainViewController;
}

- (void)setMainViewController:(UIViewController *)theMainViewController
{
	// Remove the old controller's view, if there is one
	for (UIView *subview in _mainViewHolder.subviews)
	{
		[subview removeFromSuperview];
	}
        
	// Set the new controller
	_mainViewController = theMainViewController;
    
    // Make sure it's the right size
    _mainViewController.view.frame = self.mainViewHolder.bounds;
	
	// Add the new controller's view
	[self.mainViewHolder addSubview:_mainViewController.view];
	
	// Handle UITabBarController weirdness
	if ([_mainViewController isKindOfClass:[UITabBarController class]])
	{
		_mainViewController.view.y = -ACTUAL_STATUS_HEIGHT;
	}
    
    if (ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT)
        self.wasStatusBarTallOnStart = YES;
    
    // Add tab change observation
    if ([_mainViewController isKindOfClass:[UITabBarController class]])
    {
        UITabBarController *tabController = (UITabBarController *)_mainViewController;
        @try
        {
            [tabController removeObserver:self forKeyPath:@"selectedViewController"];
        }
        @catch (id anException)
        {
            // Ignore this
        }
        [tabController addObserver:self forKeyPath:@"selectedViewController" options:NSKeyValueObservingOptionOld context:NULL];
    }
}

#pragma mark - Methods

- (void)showAndHideForDuration:(NSTimeInterval)duration
{
	[self show];
	[self performSelector:@selector(hide) withObject:nil afterDelay:duration];
}

- (void)showAndHide
{
	[self showAndHideForDuration:DEFAULT_HIDE_DURATION];
}

- (void)show
{
	[self show:NULL];
}

- (void)show:(void (^)(void))completionBlock
{
	if (self.isNotificationBarShowing || !self.view.userInteractionEnabled)
		return;
	    
	self.view.userInteractionEnabled = NO;
	
	if (completionBlock != NULL)
	{
		completionBlock = [completionBlock copy];
	}
    	
	if (self.position == EX2NotificationBarPositionTop)
	{
		self.notificationBar.height = 0;
	}
	else if (self.position == EX2NotificationBarPositionBottom)
	{
		//self.view.y = self.view.superview.height - self.view.height + 20.;
		//self.view.width = self.view.superview.width;
		//self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		
		self.notificationBar.y = self.view.height - self.notificationBar.height;
	}
    	
	void (^animations)(void) = ^(void)
	{
		if (self.position == EX2NotificationBarPositionTop)
		{
			if ([self.mainViewController isKindOfClass:[UITabBarController class]])
			{
				UITabBarController *tabController = (UITabBarController *)self.mainViewController;
				//[tabController addObserver:self forKeyPath:@"selectedViewController" options:NSKeyValueObservingOptionOld context:NULL];
				
				if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
				{
					UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
					navController.view.y += self.changedTabSinceTallHeight ? ACTUAL_STATUS_HEIGHT : SMALL_STATUS_HEIGHT;
                    
                    if (!self.wasStatusBarTallOnStart)
                    {
                        navController.navigationBar.y += self.changedTabSinceTallHeight ? SMALL_STATUS_HEIGHT : 0.;
                    }
                    
                    if (ACTUAL_STATUS_HEIGHT < LARGE_STATUS_HEIGHT && self.wasStatusBarTallOnStart)
                    {
                        navController.navigationBar.y += LARGE_STATUS_HEIGHT;
                    }
					//navController.view.height -= STATUS_HEIGHT;
				}
			}
            			
			self.notificationBar.height = self.notificationBarHeight;
			self.mainViewHolder.frame = CGRectMake(self.mainViewHolder.x,
                                                   self.mainViewHolder.y + self.notificationBarHeight,
                                                   self.mainViewHolder.width,
                                                   self.mainViewHolder.height - self.notificationBarHeight);
		}
		else if (self.position == EX2NotificationBarPositionBottom)
		{
			self.mainViewHolder.height -= self.notificationBar.height; 
			//UIView *topView = appDelegateS.mainTabBarController.selectedViewController.view;
			//topView.height -= self.notificationBar.height; 
		}
	};
	
	void (^completion)(BOOL) = ^(BOOL finished)
	{
		[UIView animateWithDuration:ANIMATE_DUR delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^(void){
			if (self.position == EX2NotificationBarPositionTop)
			{
				if ([self.mainViewController isKindOfClass:[UITabBarController class]])
				{
					UITabBarController *tabController = (UITabBarController *)self.mainViewController;
					
					if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
					{
						UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
						
						navController.view.y += SMALL_STATUS_HEIGHT;
						navController.navigationBar.y -= SMALL_STATUS_HEIGHT;
					}
				}
			}
		} completion:^(BOOL finished){
			_isNotificationBarShowing = YES;
			self.view.userInteractionEnabled = YES;
            
            if ([self.mainViewController isKindOfClass:[UITabBarController class]])
            {
                UITabBarController *tabController = (UITabBarController *)self.mainViewController;
                
                if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
                {
                    UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;

                    if (self.wasStatusBarTallOnStart)
                    {
                        CGRect theFrame = CGRectMake(0., SMALL_STATUS_HEIGHT, navController.visibleViewController.view.width, navController.visibleViewController.view.height - SMALL_STATUS_HEIGHT);
                        navController.visibleViewController.view.frame = theFrame;
                    }
                }
            }
                     
			[[NSNotificationCenter defaultCenter] postNotificationName:EX2NotificationBarDidHide object:nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];
			
			if (completionBlock != NULL)
			{
				completionBlock();
			}
		}];
	};
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EX2NotificationBarWillShow object:nil];
	
	[UIView animateWithDuration:ANIMATE_DUR 
						  delay:0.0 
						options:UIViewAnimationCurveEaseInOut 
					 animations:animations
					 completion:completion];
}

- (void)hide
{
	[self hide:NULL];
}

- (void)hide:(void (^)(void))completionBlock
{
	if (!self.isNotificationBarShowing || !self.view.userInteractionEnabled)
		return;
	
	self.view.userInteractionEnabled = NO;
	
	if (completionBlock != NULL)
	{
		completionBlock = [completionBlock copy];
	}
	
	if (self.position == EX2NotificationBarPositionTop)
	{
		if ([self.mainViewController isKindOfClass:[UITabBarController class]])
		{
			UITabBarController *tabController = (UITabBarController *)self.mainViewController;
			/*@try
			{
				[tabController removeObserver:self forKeyPath:@"selectedViewController"];
			}
			@catch (id anException) 
			{
				// This shouldn't happen
			}*/
			
			if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
			{
				UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
				navController.view.y = 0.;
				navController.navigationBar.y = SMALL_STATUS_HEIGHT;
				navController.topViewController.view.y = 0.;
			}
		}
	}
	
	void (^animations)(void) = ^(void)
	{
		if (self.position == EX2NotificationBarPositionTop)
		{
			self.notificationBar.height = 0.;
			self.mainViewHolder.frame = CGRectMake(self.mainViewHolder.x, 
                                                   self.mainViewHolder.y - self.notificationBarHeight, 
                                                   self.mainViewHolder.width, 
                                                   self.mainViewHolder.height + self.notificationBarHeight);
		}
		else if (self.position == EX2NotificationBarPositionBottom)
		{
			self.mainViewHolder.height += self.notificationBar.height; 
			//UIView *topView = appDelegateS.mainTabBarController.selectedViewController.view;
			//topView.height += self.notificationBar.height; 
		}
	};
	
	void (^completion)(BOOL) = ^(BOOL finished) 
	{
		_isNotificationBarShowing = NO;
		self.view.userInteractionEnabled = YES;
		
        if ([self.mainViewController isKindOfClass:[UITabBarController class]])
		{
			UITabBarController *tabController = (UITabBarController *)self.mainViewController;
            if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
            {
                UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
                
                if (ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT)
                {
                    if (self.wasStatusBarTallOnStart)
                    {
                        navController.navigationBar.y = LARGE_STATUS_HEIGHT;
                    }
                    else
                    {
                        CGRect theFrame = CGRectMake(0., SMALL_STATUS_HEIGHT, navController.visibleViewController.view.width, navController.visibleViewController.view.height - SMALL_STATUS_HEIGHT);
                        navController.visibleViewController.view.frame = theFrame;
                    }
                }
                else if (self.wasStatusBarTallOnStart)
                {
                    navController.view.y = SMALL_STATUS_HEIGHT;
                    navController.visibleViewController.view.y = SMALL_STATUS_HEIGHT;
                }
            }
        }
        
		[[NSNotificationCenter defaultCenter] postNotificationName:EX2NotificationBarDidHide object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];
		
		if (completionBlock != NULL)
		{
			completionBlock();
		}
	};
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EX2NotificationBarWillHide object:nil];
	
	[UIView animateWithDuration:ANIMATE_DUR 
						  delay:0. 
						options:UIViewAnimationCurveEaseInOut 
					 animations:animations 
					 completion:completion];
}

// Handle status bar height changes
- (void)statusBarDidChange:(NSNotification *)notification
{    
    if ([self.mainViewController isKindOfClass:[UITabBarController class]])
    {
        UITabBarController *tabController = (UITabBarController *)self.mainViewController;
        if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
        {            
            // Must shift down the navigation controller after switching tabs
            UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
            
            if (ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT)
            {
                if (self.wasStatusBarTallOnStart)
                {
                    [UIView animateWithDuration:.2 animations:^{
                        
                        if (self.isNotificationBarShowing)
                        {
                            CGRect theFrame = CGRectMake(0., LARGE_STATUS_HEIGHT, navController.visibleViewController.view.width, navController.visibleViewController.view.height - LARGE_STATUS_HEIGHT);
                            navController.visibleViewController.view.frame = theFrame;
                        }
                        
                        navController.navigationBar.y = LARGE_STATUS_HEIGHT;
                    }];
                }
                else if (self.isNotificationBarShowing)
                {
                    CGFloat heightChange = self.changedTabSinceTallHeight ? LARGE_STATUS_HEIGHT : SMALL_STATUS_HEIGHT;
                    
                    [UIView animateWithDuration:.2 animations:^{
                        CGRect theFrame = CGRectMake(0., heightChange, navController.view.width, navController.view.height - heightChange);
                        navController.view.frame = theFrame;
                    }];
                }
                else
                {
                    CGFloat heightChange = SMALL_STATUS_HEIGHT;//self.changedTabSinceTallHeight ? LARGE_STATUS_HEIGHT : SMALL_STATUS_HEIGHT;
                    
                    [UIView animateWithDuration:.2 animations:^{
                        CGRect theFrame = CGRectMake(0., heightChange, navController.visibleViewController.view.width, navController.visibleViewController.view.height - heightChange);
                        navController.visibleViewController.view.frame = theFrame;
                        
                        navController.navigationBar.y = SMALL_STATUS_HEIGHT;
                    }];
                }
            }
            else
            {
                if (self.wasStatusBarTallOnStart)
                {
                    [UIView animateWithDuration:.2 animations:^{
                        //navController.navigationBar.y -= LARGE_STATUS_HEIGHT;
                        //navController.view.y += LARGE_STATUS_HEIGHT;
                        
                        navController.navigationBar.y = 0.;
                        
                        CGRect theFrame = CGRectMake(0., LARGE_STATUS_HEIGHT, navController.view.width, navController.view.height - LARGE_STATUS_HEIGHT);
                        navController.view.frame = theFrame;
                    }];
                }
                else if (self.isNotificationBarShowing)
                {
                    [UIView animateWithDuration:.2 animations:^{
                        CGRect theFrame = CGRectMake(0., SMALL_STATUS_HEIGHT, navController.view.width, navController.view.height - SMALL_STATUS_HEIGHT);
                        navController.view.frame = theFrame;
                    }];
                }
                else if (self.changedTabSinceTallHeight)
                {
                    [UIView animateWithDuration:.2 animations:^{
                        navController.navigationBar.y += SMALL_STATUS_HEIGHT;
                    }];
                }
            }
        }
    }
}

// Handle tab bar changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.changedTabSinceTallHeight = ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT;
    DLog(@"changedTabSinceTallHeight: %@", NSStringFromBOOL(self.changedTabSinceTallHeight));

    if ([keyPath isEqualToString:@"selectedViewController"])
    {
        if ([object isKindOfClass:[UITabBarController class]])
        {
            id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
            UITabBarController *tabController = (UITabBarController *)object;
            
            if (oldValue != tabController.selectedViewController)
            {
                // Only if the tab actually changed
                if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
                {
                    // Must shift down the navigation controller after switching tabs
                    UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
                    
                    if (ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT || self.isNotificationBarShowing)
                    {
                        CGFloat changeHeight = SMALL_STATUS_HEIGHT;
                        if (ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT)
                            changeHeight = self.wasStatusBarTallOnStart ? LARGE_STATUS_HEIGHT : SMALL_STATUS_HEIGHT;
                        else if (ACTUAL_STATUS_HEIGHT < LARGE_STATUS_HEIGHT && self.wasStatusBarTallOnStart)
                            changeHeight = LARGE_STATUS_HEIGHT;
                        
                        if (ACTUAL_STATUS_HEIGHT > SMALL_STATUS_HEIGHT || self.isNotificationBarShowing)
                        {
                            if (self.wasStatusBarTallOnStart && !self.isNotificationBarShowing)
                            {
                                return;
                            }
                            
                            navController.view.y += changeHeight;
                            
                            CGRect theFrame = CGRectMake(0., 0, navController.visibleViewController.view.width, navController.visibleViewController.view.height - SMALL_STATUS_HEIGHT);
                            navController.visibleViewController.view.frame = theFrame;
                        }
                    }
                    else if (ACTUAL_STATUS_HEIGHT < LARGE_STATUS_HEIGHT && self.wasStatusBarTallOnStart)
                    {
                        navController.view.y = LARGE_STATUS_HEIGHT;
                    }
                }
            }
        }
    }
}

@end
