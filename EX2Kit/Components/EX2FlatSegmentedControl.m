//
//  EX2FlatSegmentedControl.m
//  EX2Kit
//
//  Created by Benjamin Baron on 6/25/13.
//
//

#import "EX2FlatSegmentedControl.h"
#import <QuartzCore/QuartzCore.h>

@implementation EX2FlatSegmentedControl
{
    NSUInteger _selectedSegmentIndex;
    NSMutableArray *_items;
}

#pragma mark - Lifecycle

- (id)init
{
    if ((self = [super init]))
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithItems:(NSArray *)items
{
    if ((self = [self init]))
    {
        [items enumerateObjectsUsingBlock:^(id title, NSUInteger idx, BOOL *stop)
         {
             [self insertSegmentWithTitle:title atIndex:idx animated:NO];
         }];
    }
    return self;
}

- (void)awakeFromNib
{
    [self commonInit];
    _selectedSegmentIndex = super.selectedSegmentIndex;
    for (NSInteger i = 0; i < super.numberOfSegments; i++)
    {
        [self insertSegmentWithTitle:[super titleForSegmentAtIndex:i] atIndex:i animated:NO];
    }
    [super removeAllSegments];
}

- (void)commonInit
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _selectedSegmentIndex = -1;
    _items = [NSMutableArray array];
    _segmentMargin = 20.;
    _borderWidth = .5;
    
    UIColor *gray = [UIColor colorWithHexString:@"707070"];
    
    _borderColor = gray;
    _selectedBackgroundColor = gray;
    _selectedTextColor = UIColor.whiteColor;
    _unselectedTextColor = gray;
    _unselectedFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.];
    _selectedFont = _unselectedFont;
    
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.layer.borderColor = gray.CGColor;
    self.layer.borderWidth = _borderWidth;
    self.layer.cornerRadius = 5.;
    self.clipsToBounds = YES;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    CGRect frame = self.frame;
    if (frame.size.height == 0)
    {
        frame.size.height = 40.;
        self.frame = frame;
    }
    if (frame.size.width == 0)
    {
        [self adjustSize];
    }
}

#pragma mark - Properties

- (void)setItems:(NSArray *)items
{
    [self removeAllSegments];
    [items enumerateObjectsUsingBlock:^(id title, NSUInteger idx, BOOL *stop)
     {
         [self insertSegmentWithTitle:title atIndex:idx animated:NO];
     }];
}

- (NSArray *)items
{
    NSMutableArray *itemStrings = [NSMutableArray array];
    for (UILabel *item in _items)
    {
        [itemStrings addObjectSafe:item.text];
    }
    return [NSArray arrayWithArray:itemStrings];
}

- (NSUInteger)numberOfSegments
{
    return _items.count;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
    
    // Fix the spacer colors
    for (UIView *item in _items)
    {
        UIView *spacer = item.subviews.firstObjectSafe;
        spacer.backgroundColor = borderColor;
    }
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor
{
    _selectedBackgroundColor = selectedBackgroundColor;
    [self highlightSelectedSegment];
}

- (void)setSelectedTextColor:(UIColor *)selectedTextColor
{
    _selectedTextColor = selectedTextColor;
    [self highlightSelectedSegment];
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    if (_selectedSegmentIndex != selectedSegmentIndex)
    {
        NSParameterAssert(selectedSegmentIndex < (NSInteger)_items.count);
        _selectedSegmentIndex = selectedSegmentIndex;
        
        [self highlightSelectedSegment];
    }
}

- (NSInteger)selectedSegmentIndex
{
    return _selectedSegmentIndex;
}

- (void)setSegmentMargin:(CGFloat)segmentMargin
{
    if (_segmentMargin != segmentMargin)
    {
        _segmentMargin = segmentMargin;
        [self adjustSize];
    }
}

- (void)setSelectedFont:(UIFont *)selectedFont
{
    if (![_selectedFont isEqual:selectedFont])
    {
        _selectedFont = selectedFont;
        [self adjustSize];
    }
}

- (void)setUnselectedFont:(UIFont *)unselectedFont
{
    if (![_unselectedFont isEqual:unselectedFont])
    {
        _unselectedFont = unselectedFont;
        [self adjustSize];
    }
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    self.layer.borderWidth = _borderWidth;
}

- (void)setStaticWidth:(CGFloat)staticWidth
{
    _staticWidth = staticWidth;
    [self adjustSize];
}

#pragma mark - Helper Methods

// Adjust size so that all segments are equally sized and fit
- (void)adjustSize
{
    if (self.items.count == 0)
    {
        self.width = 0.;
        return;
    }
    
    // Find the largest label size or use the static size
    __block CGFloat maxWidth = self.staticWidth / self.items.count;
    if (maxWidth == 0.)
    {
        for (UILabel *item in _items)
        {
            // Use the largest font for sizing
            UIFont *sizingFont = self.selectedFont;
            if (self.unselectedFont.pointSize > self.selectedFont.pointSize)
                sizingFont = self.unselectedFont;
            
            CGFloat width = [item.text sizeWithFont:sizingFont].width;
            if (width > maxWidth)
                maxWidth = width;
        }
        
        // Add the margins
        maxWidth += (self.segmentMargin * 2);
    }
    
    // Adjust all segments to match that size
    [_items enumerateObjectsUsingBlock:^(UILabel *item, NSUInteger index, BOOL *stop)
     {
         item.frame = CGRectMake(index * maxWidth, 0., maxWidth, self.height);
     }];
    
    self.width = _items.count * maxWidth;
}

- (void)highlightSelectedSegment
{
    [_items enumerateObjectsUsingBlock:^(UILabel *item, NSUInteger index, BOOL *stop) {
        item.backgroundColor = index == self.selectedSegmentIndex ? self.selectedBackgroundColor : UIColor.clearColor;
        item.textColor = index == self.selectedSegmentIndex ? self.selectedTextColor : self.unselectedTextColor;
        item.font = index == self.selectedSegmentIndex ? self.selectedFont : self.unselectedFont;
    }];
}

- (UIView *)createSpacerView:(UIView *)segmentView
{
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(segmentView.width - .5, 0., 1., self.height)];
    spacerView.backgroundColor = self.borderColor;
    spacerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    return spacerView;
}

#pragma mark - UISegmentControl Methods

- (void)insertSegmentWithImage:(UIImage *)image atIndex:(NSUInteger)segment animated:(BOOL)animated
{
    NSAssert(NO, @"insertSegmentWithImage:atIndex:animated: is not supported by EX2FlatSegmentedControl");
}

- (UIImage *)imageForSegmentAtIndex:(NSUInteger)segment
{
    NSAssert(NO, @"imageForSegmentAtIndex: is not supported by EX2FlatSegmentedControl");
    return nil;
}

- (void)setImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)segment
{
    NSAssert(NO, @"setImage:forSegmentAtIndex: is not supported by EX2FlatSegmentedControl");
}

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment
{ 
    if (segment < self.numberOfSegments)
    {
        // Set the title
        UILabel *segmentView = _items[segment];
        segmentView.text = title;
        
        // Adjust the size of the control so each items have the same width
        [self adjustSize];
    }
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment
{
    if (segment < self.numberOfSegments)
    {
        UILabel *segmentView = _items[segment];
        return segmentView.text;
    }
    
    return nil;
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)index animated:(BOOL)animated
{
    // Create the segment view
    UILabel *segmentView = [[UILabel alloc] init];
    segmentView.text = title;
    segmentView.textAlignment = UITextAlignmentCenter;
    segmentView.accessibilityLabel = segmentView.text;
    segmentView.textColor = self.unselectedTextColor;
    segmentView.font = self.unselectedFont;
    segmentView.backgroundColor = UIColor.clearColor;
    segmentView.userInteractionEnabled = YES;
    segmentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [segmentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelect:)]];
    
    // Insert it at the correct position
    index = index >= self.numberOfSegments ? self.numberOfSegments : index;
    if (index < _items.count)
    {
        // Create the spacer view
        [segmentView addSubview:[self createSpacerView:segmentView]];
        
        // Insert the segment
        [self insertSubview:segmentView belowSubview:_items[index]];
        [_items insertObject:segmentView atIndex:index];
    }
    else
    {
        // Create the spacer for the previous end item
        [_items.lastObject addSubview:[self createSpacerView:_items.lastObject]];
        
        // Add the segment to the end
        [self addSubview:segmentView];
        [_items addObject:segmentView];
    }
    
    // Adjust the selected segment index if necessary
    if (self.selectedSegmentIndex >= index)
    {
        self.selectedSegmentIndex++;
    }
    
    // Redraw the control
    if (animated)
    {
        [UIView animateWithDuration:.4 animations:^
         {
             [self adjustSize];
         }];
    }
    else
    {
        [self adjustSize];
    }
}

- (void)removeSegmentAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (index >= _items.count)
        return;
    
    // Adjust the selected segment index if necessary
    if (self.selectedSegmentIndex >= index)
    {
        self.selectedSegmentIndex--;
    }
    
    // If this is the last segment, remove the spacer from the new last segment
    if (index == _items.count - 1)
    {
        UIView *lastSegment = _items[index - 1];
        [lastSegment.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    // Remove the segment and redraw
    UIView *segmentView = _items[index];
    if (animated)
    {
        [_items removeObject:segmentView];
        [UIView animateWithDuration:.4 animations:^
         {
             [self adjustSize];
         }
        completion:^(BOOL finished)
         {
             [segmentView removeFromSuperview];
         }];
    }
    else
    {
        [segmentView removeFromSuperview];
        [_items removeObject:segmentView];
        [self adjustSize];
    }
}

- (void)removeAllSegments
{
    [_items makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_items removeAllObjects];
    self.selectedSegmentIndex = -1;
}

- (void)handleSelect:(UIGestureRecognizer *)gestureRecognizer
{
    NSUInteger index = [_items indexOfObject:gestureRecognizer.view];
    if (index != NSNotFound)
    {
        // Set the new selected index
        self.selectedSegmentIndex = index;
        
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end
