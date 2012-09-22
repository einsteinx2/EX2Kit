//
//  EX2NavigationController.m
//  WOD
//
//  Created by Casey Marshall on 2/3/11.
//  Copyright 2011 Modal Domains. All rights reserved.
//

#import "EX2NavigationController.h"
#import <objc/runtime.h>

@implementation UIViewController (EX2NavigationController)

// No adding instance properties in categories you say? Hogwash! Three cheers for associative references!
static char key;
- (EX2NavigationController *)ex2NavigationController
{
    // Try to get the reference
    EX2NavigationController *navController = (EX2NavigationController *)objc_getAssociatedObject(self, &key);
    
    // This ensures that if this controller is inside another and so it's property
    // was not set directly, we'll still get the reference
    if (!navController)
    {
        // Check it's parent controllers
        UIViewController *parent = self.parentViewController;
        while (parent)
        {
            navController = (EX2NavigationController *)objc_getAssociatedObject(parent, &key);
            if (navController)
                break;
            else
                parent = parent.parentViewController;
        }
    }
    
    return navController;
}
- (void)setEx2NavigationController:(EX2NavigationController *)ex2NavigationController
{
    objc_setAssociatedObject(self, &key, ex2NavigationController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@interface EX2NavigationController()
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (nonatomic) BOOL isAnimating;
@end

@implementation EX2NavigationController

@synthesize navigationBar, contentView, delegate, viewControllers;

#define AnimationDuration 0.3
#define AnimationCurve UIViewAnimationOptionCurveEaseInOut

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
		viewControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ([super initWithCoder:aDecoder])
    {
        viewControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)viewController
{
	if (self = [super init])
	{
        viewController.ex2NavigationController = self;
		
		viewControllers = [[NSMutableArray alloc] initWithObjects:viewController, nil];
	}
	return self;
}

// To allow easy overriding with custom navigation bar. Useful for skinning the nav bar in iOS 4
// (have a EX2NavivigationBar subclass return a custom UINavigationBar subclass from this method)
- (UINavigationBar *)createNavigationBar
{
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    return navBar;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	self.view = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 364)];
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
	self.navigationBar = [self createNavigationBar];
    
	self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, 320, 320)];
	self.contentView.clipsToBounds = YES;
	self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
	[self.view addSubview:self.navigationBar];
	[self.view addSubview:self.contentView];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if (self.viewControllers.count > 0)
	{
		UIViewController *current = self.viewControllers.lastObject;
		
		if ([self.delegate respondsToSelector:@selector(ex2NavigationController:willShowViewController:animated:)])
        {
            [self.delegate ex2NavigationController:self willShowViewController:current animated:NO];
        }
			
		[self.contentView addSubview:current.view];
		current.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[current.view setFrame:self.contentView.bounds];
		
		NSMutableArray *newItems = [[NSMutableArray alloc] initWithCapacity:self.viewControllers.count];
		for (UIViewController *vc in self.viewControllers)
		{
			[newItems addObject:vc.navigationItem];
			[vc.navigationItem.backBarButtonItem setTarget:self];
			[vc.navigationItem.backBarButtonItem setAction:@selector(backItemTapped:)];
		}
		self.navigationBar.items = newItems;
		
		if ([self.delegate respondsToSelector:@selector(ex2NavigationController:didShowViewController:animated:)])
        {
            [self.delegate ex2NavigationController:self didShowViewController:current animated:NO];
        }
	}
}

// Pass viewWillAppear to the visible view controller
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.viewControllers.count > 0)
    {
        [self.viewControllers.lastObject viewWillAppear:animated];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

#pragma mark -
#pragma mark Navigation methods

- (void)animationStopped:(UIViewController *)disappearingController appearingController:(UIViewController *)appearingController
{
    DLog(@"animation stopped");
    [disappearingController.view removeFromSuperview];
    
    if ([self.delegate respondsToSelector:@selector(ex2NavigationController:didShowViewController:animated:)])
    { 
        [self.delegate ex2NavigationController:self didShowViewController:appearingController animated:YES];
    }
}

- (void)performAnimation:(UIViewController *)appearing appearingStart:(CGRect)appearingStart appearingEnd:(CGRect)appearingEnd disappearing:(UIViewController *)disappearing disappearingEnd:(CGRect)disappearingEnd
{
    DLog(@"appearingStart: %@  appearingEnd: %@  disappearingEnd: %@", NSStringFromCGRect(appearingStart), NSStringFromCGRect(appearingEnd), NSStringFromCGRect(disappearingEnd));
    
    if (self.isAnimating)
        return;
    
    [self.contentView addSubview:appearing.view];
    appearing.view.frame = appearingStart;
    
    self.isAnimating = YES;
    [UIView animateWithDuration:AnimationDuration
                          delay:0.0
                        options:AnimationCurve
                     animations:^ {
                         disappearing.view.frame = disappearingEnd;
                         appearing.view.frame = appearingEnd;
                     }
                     completion:^(BOOL finished) {
                         [self animationStopped:disappearing appearingController:appearing];
                         self.isAnimating = NO;
                     }];
}

- (void)animate:(UIViewController *)appearing disappearing:(UIViewController *)disappearing animation:(EX2NavigationControllerAnimation)animation
{
    if (self.isAnimating)
        return;
    
    CGRect appearingEnd = self.contentView.bounds;
    switch (animation)
	{
		case EX2NavigationControllerAnimationTop:
		{
            CGRect appearingStart = CGRectMake(0, -self.contentView.bounds.size.height, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
            CGRect disappearingEnd = disappearing.view.frame;
            disappearingEnd.origin.y = disappearingEnd.size.height;
            [self performAnimation:appearing appearingStart:appearingStart appearingEnd:appearingEnd disappearing:disappearing disappearingEnd:disappearingEnd];
            break;
		}
		case EX2NavigationControllerAnimationBottom:
		{
            CGRect appearingStart = CGRectMake(0, self.contentView.bounds.size.height, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
            CGRect disappearingEnd = disappearing.view.frame;
            disappearingEnd.origin.y = -disappearingEnd.size.height;
            [self performAnimation:appearing appearingStart:appearingStart appearingEnd:appearingEnd disappearing:disappearing disappearingEnd:disappearingEnd];
            break;
		}
		case EX2NavigationControllerAnimationRight:
		{
            CGRect appearingStart = CGRectMake(self.contentView.bounds.size.width, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
            CGRect disappearingEnd = disappearing.view.frame;
            disappearingEnd.origin.x = -disappearingEnd.size.width;
            [self performAnimation:appearing appearingStart:appearingStart appearingEnd:appearingEnd disappearing:disappearing disappearingEnd:disappearingEnd];
            break;
		}
		case EX2NavigationControllerAnimationLeft:
		{
            CGRect appearingStart = CGRectMake(-self.contentView.bounds.size.width, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
            CGRect disappearingEnd = disappearing.view.frame;
            disappearingEnd.origin.x = disappearingEnd.size.width;
            [self performAnimation:appearing appearingStart:appearingStart appearingEnd:appearingEnd disappearing:disappearing disappearingEnd:disappearingEnd];
            break;
		}
        case EX2NavigationControllerAnimationDefault:
		case EX2NavigationControllerAnimationNone:
		default:
		{
			[disappearing.view removeFromSuperview];
			[contentView addSubview:appearing.view];
            appearing.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
            appearing.view.frame = appearingEnd;
            
            if ([self.delegate respondsToSelector:@selector(ex2NavigationController:didShowViewController:animated:)])
            {
                [self.delegate ex2NavigationController:self didShowViewController:appearing animated:NO];
            }
            break;
		}
    }
}

- (void)setViewControllers:(NSArray *)vc animated:(BOOL)animated
{
	[self setViewControllers:vc withAnimation:(animated ? EX2NavigationControllerAnimationDefault : EX2NavigationControllerAnimationNone)];
}

- (void)setViewControllers:(NSArray *)vc withAnimation:(EX2NavigationControllerAnimation)animation
{
	UIViewController *disappearing = nil;
	if (self.viewControllers.count > 0)
		disappearing = self.viewControllers.lastObject;
	UIViewController *appearing = vc.lastObject;
	for (UIViewController *c in self.viewControllers)
	{
        c.ex2NavigationController = nil;
	}
	[self.viewControllers removeAllObjects];
	[self.viewControllers addObjectsFromArray:vc];
	
	for (UIViewController *c in self.viewControllers)
	{
        c.ex2NavigationController = self;
	}
    
    // Perform the controller animation
    [self animate:appearing disappearing:disappearing animation:animation];
	
    // Setup the navigation bar
	NSMutableArray *newItems = [[NSMutableArray alloc] initWithCapacity:self.viewControllers.count];
	for (UIViewController *c in self.viewControllers)
	{
		[newItems addObject: c.navigationItem];
		[c.navigationItem.backBarButtonItem setTarget:self];
		[c.navigationItem.backBarButtonItem setAction:@selector(backItemTapped:)];
	}
	[navigationBar setItems:newItems animated:(animation != EX2NavigationControllerAnimationNone)];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	[self pushViewController:viewController withAnimation:(animated ? EX2NavigationControllerAnimationDefault : EX2NavigationControllerAnimationNone)];
}

- (void)pushViewController:(UIViewController *)viewController withAnimation:(EX2NavigationControllerAnimation)animation
{
    if (self.isAnimating)
        return;
    
	if ([self.delegate respondsToSelector:@selector(ex2NavigationController:willShowViewController:animated:)])
    {
        [self.delegate ex2NavigationController:self willShowViewController:viewController animated:(animation != EX2NavigationControllerAnimationNone)];
    }
	
    viewController.ex2NavigationController = self;
	UIViewController *disappearing = nil;
	if (self.viewControllers.count > 0)
		disappearing = self.viewControllers.lastObject;
	[self.viewControllers addObject:viewController];
    
    // Perform the animation
    animation = animation == EX2NavigationControllerAnimationDefault ? EX2NavigationControllerAnimationRight : animation;
    [self animate:viewController disappearing:disappearing animation:animation];
	
	[self.navigationBar pushNavigationItem:viewController.navigationItem animated:(animation != EX2NavigationControllerAnimationNone)];
	[self.navigationBar.topItem.backBarButtonItem setTarget: self];
	[self.navigationBar.topItem.backBarButtonItem setAction: @selector(backItemTapped:)];
}

- (void)popViewControllerAnimated:(BOOL)animated
{
	[self popViewControllerWithAnimation:(animated ? EX2NavigationControllerAnimationDefault : EX2NavigationControllerAnimationNone)];
}

- (void)popViewControllerWithAnimation:(EX2NavigationControllerAnimation)animation
{
	if (self.isAnimating || self.viewControllers.count == 1)
		return;
    
	UIViewController *disappearing = self.viewControllers.lastObject;
    disappearing.ex2NavigationController = nil;
	[self.viewControllers removeLastObject];
	UIViewController *appearing = self.viewControllers.lastObject;
	
    if ([self.delegate respondsToSelector:@selector(ex2NavigationController:willShowViewController:animated:)])
    {
        [self.delegate ex2NavigationController:self willShowViewController:appearing animated:(animation != EX2NavigationControllerAnimationNone)];
    }
    
    animation = animation == EX2NavigationControllerAnimationDefault ? EX2NavigationControllerAnimationLeft : animation;
    [self animate:appearing disappearing:disappearing animation:animation];
    
    [self.navigationBar popNavigationItemAnimated:(animation != EX2NavigationControllerAnimationNone)];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated
{
    if (!self.isAnimating && self.viewControllers.count > 1)
    {
        NSArray *array = [NSArray arrayWithObject:[viewControllers objectAtIndex:0]];
        [self setViewControllers:array withAnimation:(animated ? EX2NavigationControllerAnimationLeft : EX2NavigationControllerAnimationNone)];
    }
}

@end
