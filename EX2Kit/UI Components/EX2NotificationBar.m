//
//  EX2NotificationBar.m
//
//  Created by Ben Baron on 4/17/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "EX2NotificationBar.h"

#define DEFAULT_HIDE_DURATION 5.0
#define ANIMATE_DUR 0.3
#define DEFAULT_BAR_HEIGHT 30.
#define STATUS_HEIGHT ([UIApplication sharedApplication].isStatusBarHidden ? 0. : 20.)

@implementation EX2NotificationBar
@synthesize position, notificationBar, notificationBarContent, mainViewHolder, mainViewController, isNotificationBarShowing, notificationBarHeight;

#pragma mark - Life Cycle

- (void)setup
{
	notificationBarHeight = DEFAULT_BAR_HEIGHT;
	position = EX2NotificationBarPositionTop;
}

- (id)initWithPosition:(EX2NotificationBarPosition)thePosition
{
	if ((self = [super initWithNibName:@"EX2NotificationBar" bundle:nil]))
	{
		[self setup];
		position = thePosition;
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
                
                if (navController.view.y != STATUS_HEIGHT)
                {
                    [UIView animateWithDuration:0.25 animations:^
                     {
                         navController.view.y = STATUS_HEIGHT;
                     }];
                }
			}
		}
	}
	
	// In iOS 4 make sure to pass this message
	if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
	{
		[self.mainViewController viewDidAppear:animated];
	}
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
				navController.view.y = STATUS_HEIGHT;
			}
		}
	}
}

#pragma mark - Properties

- (EX2NotificationBarPosition)position
{
	return position;
}

- (void)setPosition:(EX2NotificationBarPosition)thePosition
{
	if (!self.isNotificationBarShowing)
	{
		position = thePosition;
	}
}

- (UIViewController *)mainViewController
{
	return mainViewController;
}

- (void)setMainViewController:(UIViewController *)theMainViewController
{
	// Remove the old controller's view, if there is one
	for (UIView *subview in mainViewHolder.subviews)
	{
		[subview removeFromSuperview];
	}
        
	// Set the new controller
	mainViewController = theMainViewController;
	
	// Add the new controller's view
	[self.mainViewHolder addSubview:mainViewController.view];
	
	// Handle UITabBarController weirdness
	if ([mainViewController isKindOfClass:[UITabBarController class]])
	{
		mainViewController.view.y = -20.;
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
    	
	if (position == EX2NotificationBarPositionTop)
	{
		self.notificationBar.height = 0;
	}
	else if (position == EX2NotificationBarPositionBottom)
	{
		//self.view.y = self.view.superview.height - self.view.height + 20.;
		//self.view.width = self.view.superview.width;
		//self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		
		self.notificationBar.y = self.view.height - self.notificationBar.height;
	}
    	
	void (^animations)(void) = ^(void)
	{
		if (position == EX2NotificationBarPositionTop)
		{
			if ([mainViewController isKindOfClass:[UITabBarController class]])
			{
				UITabBarController *tabController = (UITabBarController *)mainViewController;
				[tabController addObserver:self forKeyPath:@"selectedViewController" options:NSKeyValueObservingOptionOld context:NULL];
				
				if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
				{
					UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
					navController.view.y += STATUS_HEIGHT;
					//navController.view.height -= STATUS_HEIGHT;					
				}
			}
            			
			notificationBar.height = self.notificationBarHeight;
			mainViewHolder.frame = CGRectMake(mainViewHolder.x, 
											  mainViewHolder.y + self.notificationBarHeight, 
											  mainViewHolder.width, 
											  mainViewHolder.height - self.notificationBarHeight);
		}
		else if (position == EX2NotificationBarPositionBottom)
		{
			mainViewHolder.height -= self.notificationBar.height; 
			//UIView *topView = appDelegateS.mainTabBarController.selectedViewController.view;
			//topView.height -= self.notificationBar.height; 
		}
	};
	
	void (^completion)(BOOL) = ^(BOOL finished)
	{
		[UIView animateWithDuration:ANIMATE_DUR delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^(void){
			if (position == EX2NotificationBarPositionTop)
			{
				if ([mainViewController isKindOfClass:[UITabBarController class]])
				{
					UITabBarController *tabController = (UITabBarController *)mainViewController;
					
					if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
					{
						UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
						
						navController.view.y += STATUS_HEIGHT;
						navController.navigationBar.y -= STATUS_HEIGHT;
					}
				}
			}
		} completion:^(BOOL finished){
			isNotificationBarShowing = YES;
			self.view.userInteractionEnabled = YES;
			
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
	
	if (position == EX2NotificationBarPositionTop)
	{
		if ([mainViewController isKindOfClass:[UITabBarController class]])
		{
			UITabBarController *tabController = (UITabBarController *)mainViewController;
			@try
			{
				[tabController removeObserver:self forKeyPath:@"selectedViewController"];
			}
			@catch (id anException) 
			{
				// This shouldn't happen
			}
			
			if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]])
			{
				UINavigationController *navController = (UINavigationController *)tabController.selectedViewController;
				navController.view.y = 0.;
				navController.navigationBar.y = STATUS_HEIGHT;
				navController.topViewController.view.y = 0.;				
			}
		}
	}
	
	void (^animations)(void) = ^(void)
	{
		if (position == EX2NotificationBarPositionTop)
		{
			notificationBar.height = 0.;
			mainViewHolder.frame = CGRectMake(mainViewHolder.x, 
											  mainViewHolder.y - self.notificationBarHeight, 
											  mainViewHolder.width, 
											  mainViewHolder.height + self.notificationBarHeight);
		}
		else if (position == EX2NotificationBarPositionBottom)
		{
			mainViewHolder.height += self.notificationBar.height; 
			//UIView *topView = appDelegateS.mainTabBarController.selectedViewController.view;
			//topView.height += self.notificationBar.height; 
		}
	};
	
	void (^completion)(BOOL) = ^(BOOL finished) 
	{
		isNotificationBarShowing = NO;
		self.view.userInteractionEnabled = YES;
		
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

// Handle tab bar changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
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
					navController.view.y += STATUS_HEIGHT;
				}
			}
		}
	}
}

@end
