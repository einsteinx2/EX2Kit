//
//  SlidingNotification.m
//  EX2Kit
//
//  Created by Ben Baron on 4/17/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "EX2SlidingNotification.h"

#define ANIMATION_DELAY 0.25
#define DEFAULT_DISPLAY_TIME 2.0

@interface EX2SlidingNotification()
@property (nonatomic, strong) EX2SlidingNotification *selfRef;
@end

@implementation EX2SlidingNotification
@synthesize messageLabel, imageView, message, image, parentView, displayTime, backgroundImageView, selfRef;

- (id)initOnView:(UIView *)theParentView message:(NSString *)theMessage image:(UIImage*)theImage displayTime:(NSTimeInterval)time
{
	if ((self = [super initWithNibName:@"SlidingNotification" bundle:nil])) 
	{
		displayTime = time;
		parentView = theParentView;
		image = theImage;
		message = [theMessage copy];
		
		// If we're directly on the UIWindow, add 20 points for the status bar
		CGFloat height = -self.view.height;
		height += (parentView == [[UIApplication sharedApplication] keyWindow] ? 20. : 0.);
		self.view.frame = CGRectMake(0., height, parentView.width, self.view.height);
		
		[parentView addSubview:self.view];
	}
	
	return self;
}

- (id)initOnView:(UIView *)theParentView message:(NSString *)theMessage image:(UIImage*)theImage
{
	return [self initOnView:theParentView message:theMessage image:theImage displayTime:DEFAULT_DISPLAY_TIME];
}

+ (id)slidingNotificationOnMainWindowWithMessage:(NSString *)theMessage image:(UIImage*)theImage
{
	return [[EX2SlidingNotification alloc] initOnView:[[UIApplication sharedApplication] keyWindow] message:theMessage image:theImage];
}

+ (id)slidingNotificationOnTopViewWithMessage:(NSString *)theMessage image:(UIImage*)theImage
{
	return [[EX2SlidingNotification alloc] initOnView:[[[UIApplication sharedApplication] keyWindow].subviews firstObjectSafe] message:theMessage image:theImage];
}

+ (id)slidingNotificationOnView:(UIView *)theParentView message:(NSString *)theMessage image:(UIImage*)theImage
{
	return [[EX2SlidingNotification alloc] initOnView:theParentView message:theMessage image:theImage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.imageView.image = image;
	self.messageLabel.text = message;
	
	[self.view addBottomShadow];
	CALayer *shadow = [[self.view.layer sublayers] objectAtIndexSafe:0];
    shadow.frame = CGRectMake(shadow.frame.origin.x, shadow.frame.origin.y, 1024., shadow.frame.size.height);
	
	/*CGRect newFrame;
	if (image)
	{
		newFrame = CGRectMake(5., 5., self.view.height - 10., self.view.height - 10.);
		self.imageView.frame = newFrame;
		
		newFrame = CGRectMake(self.view.height, 5., self.view.width - self.view.height - 5., self.view.height - 10.);
		self.messageLabel.frame = newFrame;
	}
	else
	{
		newFrame = CGRectMake(5., 5., self.view.width - 10., self.view.height - 10.);		
		self.messageLabel.frame = newFrame;
	}*/
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)sizeToFit
{
	CGSize maximumLabelSize = CGSizeMake(self.messageLabel.width, 300.);
	CGSize expectedLabelSize = [message sizeWithFont:self.messageLabel.font constrainedToSize:maximumLabelSize lineBreakMode:self.messageLabel.lineBreakMode];
	if (expectedLabelSize.height >= 25.)
	{
		self.messageLabel.size = expectedLabelSize;
		self.view.height = self.messageLabel.height + 6.;
		
		[[[self.view.layer sublayers] objectAtIndexSafe:0] removeFromSuperlayer];
		[self.view addBottomShadow];
		CALayer *shadow = [[self.view.layer sublayers] objectAtIndexSafe:0];
		shadow.frame = CGRectMake(shadow.frame.origin.x, shadow.frame.origin.y, 1024., shadow.frame.size.height);
	}
}

- (void)showAndHideSlidingNotification
{
	[self showSlidingNotification];
	
	[self performSelector:@selector(hideSlidingNotification) withObject:nil afterDelay:displayTime];
}

- (void)showSlidingNotification
{
	self.selfRef = self;
	[UIView animateWithDuration:ANIMATION_DELAY animations:^(void)
     {
         // If we're directly on the UIWindow then add the status bar height
         CGFloat y = 0.;
         if (self.view.superview == [[UIApplication sharedApplication] keyWindow])
             y = [[UIApplication sharedApplication] statusBarFrame].origin.y;
             
         self.view.y = y;
     }];
}

- (void)hideSlidingNotification
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
	
	[UIView animateWithDuration:ANIMATION_DELAY animations:^(void)
     {
         self.view.y = -self.view.height;
     }
    completion:^(BOOL finished)
     {
         [self.view removeFromSuperview];
         self.selfRef = nil;
     }];
}

@end
