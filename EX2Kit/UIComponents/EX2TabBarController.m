//
//  EX2TabBarController.m
//  Anghami
//
//  Created by Ben Baron on 8/31/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "EX2TabBarController.h"
#import <objc/runtime.h>

@implementation UIViewController (EX2TabBarController)
// No adding instance properties in categories you say? Hogwash! Three cheers for associative references!
static char key;
- (EX2TabBarController *)ex2TabBarController
{
    // Try to get the reference
    EX2TabBarController *tabController = (EX2TabBarController *)objc_getAssociatedObject(self, &key);
    
    // This ensures that if this controller is inside another and so it's property
    // was not set directly, we'll still get the reference
    if (!tabController)
    {
        // Check it's parent controllers
        UIViewController *parent = self.parentViewController;
        
        if (!parent)
        {
            parent = self.presentingViewController;
        }
        
        while (parent)
        {
            tabController = (EX2TabBarController *)objc_getAssociatedObject(parent, &key);
            if (tabController)
                break;
            else
                parent = parent.parentViewController;
        }
    }
    
    return tabController;
}
- (void)setEx2TabBarController:(EX2TabBarController *)ex2TabBarController
{
    objc_setAssociatedObject(self, &key, ex2TabBarController, OBJC_ASSOCIATION_ASSIGN);
}
@end

@implementation EX2TabBarController
@synthesize containerView, tabBar, viewControllers, selectedIndex, animation;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
        
    // Handle having a large status bar on start
    if ([[UIApplication sharedApplication] statusBarFrame].size.height > 20.)
    {
        self.containerView.height -= 20;
        self.tabBar.y -= 20.;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // TODO: Hacky fix for sizing issue, need to properly fix later
    self.containerView.height = IS_TALL_SCREEN() ? 499. : 411.;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSArray *)viewControllers
{
    return viewControllers;
}

- (void)setViewControllers:(NSArray *)controllers
{
    // Remove any displayed views first
    [self.containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // Clear the ex2TabBarController property from the old controllers if they exist
    for (UIViewController *controller in viewControllers)
    {
        controller.ex2TabBarController = nil;
    }
    
    // Set the ivar
    viewControllers = controllers;
        
    // Setup the tab bar items and set the ex2TabBarController property
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:viewControllers.count];
    for (UIViewController *controller in viewControllers)
    {
        controller.ex2TabBarController = self;
        [items addObject:controller.tabBarItem];
    }
    self.tabBar.items = [NSArray arrayWithArray:items];
    
    // Display the first controller if it exists
    if (viewControllers.count > 0)
    {
        [self displayControllerAtIndex:0 animation:self.animation];
    }
}

- (UIViewController *)selectedViewController
{
    return [viewControllers objectAtIndexSafe:selectedIndex];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    NSUInteger index = [viewControllers indexOfObject:selectedViewController];
    if (index != NSNotFound)
    {
        self.selectedIndex = index;
    }
}

- (NSUInteger)selectedIndex
{
    return selectedIndex;
}

- (void)setSelectedIndex:(NSUInteger)index
{
    if (selectedIndex != index)
    {
        self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:index];
        [self tabBar:self.tabBar didSelectItem:self.tabBar.selectedItem];
    }
}

- (void)displayControllerAtIndex:(NSUInteger)index animation:(EX2TabBarControllerAnimation)animationType
{
    if (viewControllers.count > index)
    {
        switch (animationType)
        {
            case EX2TabBarControllerAnimationNone:
            {
                // Remove any displayed views first
                [self.containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                
                // Resize the view
                UIViewController *controller = [viewControllers objectAtIndex:index];
                controller.view.frame = self.containerView.bounds;
                controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                
                // Add the view
                [self.containerView addSubview:controller.view];
                break;
            }
            case EX2TabBarControllerAnimationFadeInOut:
            {
                [UIView animateWithDuration:.15 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    // Fade out the view
                    self.containerView.alpha = 0.0;
                } completion:^(BOOL finished){
                    // Switch the controllers
                    [self displayControllerAtIndex:index animation:EX2TabBarControllerAnimationNone];
                    
                    // Fade in the view
                    [UIView animateWithDuration:.15 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        self.containerView.alpha = 1.0;
                    } completion:nil];
                }];
                
                break;
            }
            case EX2TabBarControllerAnimationFadeTogether:
            {
                // Prepare the new view
                UIViewController *controller = [viewControllers objectAtIndex:index];
                controller.view.frame = self.containerView.bounds;
                controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                controller.view.alpha = 0.0;
                [self.containerView insertSubview:controller.view atIndex:0];
                
                [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    // Fade the views
                    for (UIView *view in self.containerView.subviews)
                    {
                        view.alpha = !view.alpha;
                    }
                } completion:^(BOOL finished){
                    // Remove the old view
                    for (UIView *view in self.containerView.subviews)
                    {
                        if (view != controller.view)
                        {
                            [view removeFromSuperview];
                        }
                    }
                }];
                break;
            }
            default:
                break;
        }
    }
}

- (void)tabBar:(UITabBar *)bar didSelectItem:(UITabBarItem *)item
{
    NSUInteger index = [bar.items indexOfObject:item];
    if (index != NSNotFound && selectedIndex != index)
    {
        selectedIndex = index;
        [self displayControllerAtIndex:index animation:self.animation];
    }
}

@end
