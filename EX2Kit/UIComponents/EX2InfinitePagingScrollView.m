//
//  EX2InfinitePagingScrollView.m
//  EX2Kit
//
//  Created by Benjamin Baron on 4/23/13.
//  Copyright (c) 2013 Anghami. All rights reserved.
//

#import "EX2InfinitePagingScrollView.h"

#define PAGE_WIDTH (self.frame.size.width*self.pageWidthFraction)
#define CENTER_OFFSET CGPointMake((PAGE_WIDTH * 2. + self.pageSpacing * 2 - (1-self.pageWidthFraction)/2.*self.frame.size.width), 0.)

#define DEFAULT_AUTOSCROLL_INTERVAL 10.

@interface EX2InfinitePagingScrollView ()
{
    BOOL isAutoscrolling;
}
@property (nonatomic, strong) NSTimer *autoScrollTimer;
@end

@implementation EX2InfinitePagingScrollView

- (void)setup
{
    self.pagingEnabled = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.delegate = self;
    self.scrollsToTop = NO;
    self.pageSpacing = 0;
    self.pageWidthFraction = 1;
    self.contentSize = CGSizeMake(PAGE_WIDTH * 5., self.height);
    
    _pageViews = [[NSMutableDictionary alloc] initWithCapacity:10];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setup];
    }
    isAutoscrolling = NO;
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    isAutoscrolling = NO;
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

- (void)clearAllPages
{
    // Dispose of any existing scrollView subviews
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.pageViews removeAllObjects];
}

- (void)clearInvisiblePages
{
    NSInteger index = self.currentPageIndex;
    NSArray *keys = self.pageViews.allKeys;
    for (NSNumber *key in keys)
    {
        NSInteger keyInt = key.integerValue;
        if (keyInt < index - 2 || keyInt > index + 2)
        {
            [self removePageAtIndex:keyInt];
        }
    }
}

- (void)removePageAtIndex:(NSInteger)index
{
    NSNumber *key = @(index);
    
    UIView *view = self.pageViews[key];
    [view removeFromSuperview];
    
    [self.pageViews removeObjectForKey:key];
}

- (CGPoint)centerOffset
{
    if (self.isWrapLeft && self.isWrapRight)
    {
        return CENTER_OFFSET;
    }
    else if (!self.isWrapLeft && self.currentPageIndex < 2)
    {
        return CGPointMake((PAGE_WIDTH+self.pageSpacing)*self.currentPageIndex, 0);
    }
    else if (!self.isWrapRight && self.currentPageIndex > self.numberOfPages - 3)
    {
        NSInteger offset = self.numberOfPages-self.currentPageIndex;
        DLog(@"%lu %ld %ld %g", (unsigned long)self.numberOfPages, (long)self.currentPageIndex, (long)offset, self.contentSize.width-offset*PAGE_WIDTH-(offset-1)*self.pageSpacing);
        return CGPointMake(self.contentSize.width-offset*PAGE_WIDTH-(offset-1)*self.pageSpacing, 0.);
    }
    return CENTER_OFFSET;
}

- (void)setupPages
{
    // Fix content size in case we've been resized
    self.contentSize = CGSizeMake((PAGE_WIDTH * 5) + (self.pageSpacing * 4), self.height);
    
    // We always scroll to the center page to start, and then load the appropriate pages on the left, center, and right
    self.contentOffset = self.centerOffset;
    
    // Load the views for the visible pages (2 pages to the left, center page, and two pages to the right)
    int start = self.currentPageIndex - 2;
    start = start < 0 && !self.isWrapLeft ? 0 : start;
    
    int end = self.currentPageIndex + 2;
    if (!self.isWrapRight && end >= self.numberOfPages) {
        end = self.numberOfPages - 1;
        start = end - 4;
    }
    
    for (int i = start; i <= end; i++)
    {
        @autoreleasepool
        {
            // Special handling for wrapping pages
            NSInteger loadIndex = i;
            if (i > 0 && i > self.numberOfPages - 1)
            {
                loadIndex = i - self.numberOfPages;
            }
            else if (loadIndex < 0)
            {
                loadIndex = self.numberOfPages + i;
            }
            
            // First try to see if a page for this index already exists, if so we'll just move it instead of loading a new one
            NSNumber *key = @(i);
            UIView *view = self.pageViews[key];
            CGFloat x = (i-start)*(PAGE_WIDTH+self.pageSpacing);
            CGRect rect = CGRectMake(x, 0., PAGE_WIDTH, self.height);
            
            if (view)
            {
                // This view already exists, it just isn't in the right place
                view.frame = rect;
            }
            else
            {
                // This view doesn't exist yet, so load one and place it
                if (self.createPageBlock)
                    view = self.createPageBlock(self, loadIndex);
                else
                    view = [self.pagingDelegate infinitePagingScrollView:self pageForIndex:loadIndex];
                if (view)
                {
                    view.frame = rect;
                    [self addSubview:view];
                    self.pageViews[key] = view;
                }
            }
        }
    }

    [self clearInvisiblePages];

    // Ensure that the content offset is set properly in case an animation was in progress
    [self setContentOffset:self.centerOffset animated:YES];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self setupPages];
}

- (void)setCurrentPageIndex:(NSInteger)index
{
    _currentPageIndex = index;
    [self setupPages];
}

- (void)scrollToPrevPageAnimated
{
    NSInteger index = self.currentPageIndex - 1;
    if (index < 0 && !self.isWrapLeft)
    {
        // Do nothing
        return;
    }
    
    [self scrollToPageIndexAnimated:index];
}

- (void)scrollToNextPageAnimated
{
    NSInteger index = self.currentPageIndex + 1;
    if (index >= self.numberOfPages && !self.isWrapRight)
    {
        // Do nothing
        return;
    }
    
    [self scrollToPageIndexAnimated:index];
}

- (void)scrollToPageIndexAnimated:(NSInteger)index
{
    NSInteger indexDiff = (index-self.currentPageIndex);
    if (indexDiff == 0) {
        return;
    }
    if (abs(indexDiff) == 1)
    {
        CGFloat offset = indexDiff * (PAGE_WIDTH + self.pageSpacing);
        [self setContentOffset:CGPointMake(self.centerOffset.x + offset, 0.) animated:YES];
    }
    else
    {
        // too far, so just set it with no animation
        self.currentPageIndex = index;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat distanceFromCenter = targetContentOffset->x - self.centerOffset.x;
    
    NSInteger indexDiff = 0;
    if (fabs(distanceFromCenter) >= (PAGE_WIDTH + self.pageSpacing)/2.)
    {
        indexDiff = distanceFromCenter < 0 ? -1 : 1;
    }
    targetContentOffset->x = self.centerOffset.x + (PAGE_WIDTH + self.pageSpacing) * indexDiff;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.pagingDelegate respondsToSelector:@selector(infinitePagingScrollViewWillBeginDragging:)])
    {
        [self.pagingDelegate infinitePagingScrollViewWillBeginDragging:self];
    }
    if (self.autoScrollTimer)
        [self.autoScrollTimer invalidate];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat distanceFromCenter = self.contentOffset.x - self.centerOffset.x;
    
    // See if we need to change the index and shuffle pages
    if (fabs(distanceFromCenter) >= PAGE_WIDTH + self.pageSpacing)
    {
        NSInteger index = distanceFromCenter < 0 ? self.currentPageIndex-1 : self.currentPageIndex+1;
        if (index < 0 && self.isWrapLeft)
        {
            index = self.numberOfPages - 1;
        }
        else if (index >= self.numberOfPages && self.isWrapRight)
        {
            index = 0;
        }
        
        _currentPageIndex = index;
        [self setupPages];
        
        if ([self.pagingDelegate respondsToSelector:@selector(infinitePagingScrollViewDidChangePages:)])
        {
            // Run async
            [EX2Dispatch runInMainThreadAsync:^{
                [self.pagingDelegate infinitePagingScrollViewDidChangePages:self];
            }];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // If we're auto-scrolling, restart the timer
    if (isAutoscrolling)
    {
        [self startAutoScrolling];
    }
    
    // Call the delegate
    if ([self.pagingDelegate respondsToSelector:@selector(infinitePagingScrollViewDidEndDecelerating:)])
    {
        // Run async
        [EX2Dispatch runInMainThreadAsync:^{
            [self.pagingDelegate infinitePagingScrollViewDidEndDecelerating:self];
        }];
    }
}

- (void)startAutoScrolling
{
    // Defensive: prevent auto-scrolling when there's only 1 page view
    if (self.pageViews.count > 1)
    {
        isAutoscrolling = YES;
        // Cancel any existing timer
        if (self.autoScrollTimer)
            [self.autoScrollTimer invalidate];
        
        // Set some defaults
        if (self.autoScrollDirection == EX2AutoScrollDirection_None)
            self.autoScrollDirection = EX2AutoScrollDirection_Right;
        if (self.autoScrollInterval == 0.)
            self.autoScrollInterval = DEFAULT_AUTOSCROLL_INTERVAL;
        
        // Choose the correct selector
        SEL selector = self.autoScrollDirection == EX2AutoScrollDirection_Right ? @selector(scrollToNextPageAnimated) : @selector(scrollToPrevPageAnimated);
        
        self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollInterval target:self selector:selector userInfo:nil repeats:YES];
    }
}

- (void)stopAutoScrolling
{
    if (self.autoScrollTimer)
    {
        isAutoscrolling = NO;
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
    }
}

- (CGFloat)pageWidthFraction
{
    // no wrapping and fractional pages don't mix well together in the current system
    if (self.numberOfPages == 1 || !self.isWrapLeft || !self.isWrapRight) {
        return 1;
    }
    return _pageWidthFraction;
}

- (void)setNumberOfPages:(NSUInteger)numberOfPages
{
    self.scrollEnabled = numberOfPages != 1;
    _numberOfPages = numberOfPages;
}

@end
