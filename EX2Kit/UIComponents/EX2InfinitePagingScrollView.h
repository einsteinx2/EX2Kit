//
//  EX2InfinitePagingScrollView.h
//  EX2Kit
//
//  Created by Benjamin Baron on 4/23/13.
//  Copyright (c) 2013 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  EX2InfinitePagingScrollView;
@protocol EX2InfinitePagingScrollViewDelegate <NSObject>

@required
- (UIView *)infinitePagingScrollView:(EX2InfinitePagingScrollView *)scrollView pageForIndex:(NSInteger)index;

@optional
- (void)infinitePagingScrollViewWillBeginDragging:(EX2InfinitePagingScrollView *)scrollView;
- (void)infinitePagingScrollViewDidChangePages:(EX2InfinitePagingScrollView *)scrollView;
- (void)infinitePagingScrollViewDidEndDecelerating:(EX2InfinitePagingScrollView *)scrollView;

@end

@interface EX2InfinitePagingScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, unsafe_unretained) id<EX2InfinitePagingScrollViewDelegate> pagingDelegate;

// Keyed on NSNumber of index, works like sparse array
@property (nonatomic, strong) NSMutableDictionary *pageViews;

@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic) NSUInteger numberOfPages;
@property (nonatomic) BOOL isWrapLeft;
@property (nonatomic) BOOL isWrapRight;

- (void)clearAllPages;
- (void)setupPages;

- (void)scrollToPageIndexAnimated:(NSInteger)index;
- (void)scrollToPrevPageAnimated;
- (void)scrollToNextPageAnimated;

@end
