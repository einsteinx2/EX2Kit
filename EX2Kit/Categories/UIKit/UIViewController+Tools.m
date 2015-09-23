//
//  UIViewController+Tools.m
//  EX2Kit
//
//  Created by Justin Hill on 11/7/13.
//
//

#import "UIViewController+Tools.h"

@implementation UIViewController (Tools)

- (void)insertAsChildViewController:(UIViewController *)viewController
{
    [self addChildViewController: viewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)removeFromParentContainerViewController
{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)replaceTextWithLocalizedText
{
    [UIViewController replaceTextWithLocalizedTextInSubviewsForView:self.view];
}

+(void) replaceTextWithLocalizedTextInSubviewsForView:(UIView*)view
{
    for (UIView* v in view.subviews)
    {
        if (v.subviews.count > 0)
        {
            [self replaceTextWithLocalizedTextInSubviewsForView:v];
        }
        
        if ([v isKindOfClass:[UILabel class]])
        {
            UILabel* l = (UILabel*)v;
            l.text = NSLocalizedString(l.text, nil);
            //            [l sizeToFit];
        }
        
        if ([v isKindOfClass:[UIButton class]])
        {
            UIButton* b = (UIButton*)v;
            [b setTitle:NSLocalizedString(b.titleLabel.text, nil) forState:UIControlStateNormal];
        }
    }    
}


@end
