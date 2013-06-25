//
//  EX2FlatSegmentedControl.h
//  EX2Kit
//
//  Created by Benjamin Baron on 6/25/13.
//
//

#import <UIKit/UIKit.h>

@interface EX2FlatSegmentedControl : UISegmentedControl

@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *selectedBackgroundColor;

@property (nonatomic, strong) UIColor *selectedTextColor;
@property (nonatomic, strong) UIColor *unselectedTextColor;

@property (nonatomic, strong) UIFont *selectedFont;
@property (nonatomic, strong) UIFont *unselectedFont;

@property (nonatomic) CGFloat segmentMargin;
@property (nonatomic, strong) NSArray *items;

@end

