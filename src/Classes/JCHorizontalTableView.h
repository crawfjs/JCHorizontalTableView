//
//  JCHorizontalTableView.h
//  AnaWhite
//
//  Created by Crawfjs on 3/12/12.
//  Copyright (c) 2012 Jaceyroo.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JCHorizontalTableViewCell.h"

/*
 * HorizontalTableView DataSource
 */
@class JCHorizontalTableView;
@protocol JCHortizontalTableViewDataSource <NSObject>
- (JCHorizontalTableViewCell*)horizontalTableView:(JCHorizontalTableView*)hTableView cellForColumnAtIndex:(int)idx;
- (NSInteger)numberOfColumnsInHorizontalTableView:(JCHorizontalTableView*)hTableView;
@end

/*
 * HorizontalTableView Delegate
 */
@protocol JCHorizontalTableViewDelegate <NSObject>

- (void)horizontalTableView:(JCHorizontalTableView*)hTableView didSelectColumnAtIndex:(int)idx;
- (CGFloat)horizontalTableView:(JCHorizontalTableView*)hTableView widthForColumnAtIndex:(int)idx;

@end

/*
 * HorizontalTableView
 */
@interface JCHorizontalTableView : UIScrollView {
@private
    NSMutableArray *_hashlist;
    
    NSMutableArray *_reusableCells;
    NSMutableArray *_visibleCells;
    
    UITapGestureRecognizer *tapRecognizer;
    
}

@property (nonatomic, readwrite) CGFloat padding;
@property (nonatomic, retain) id<JCHorizontalTableViewDelegate> horizontalTableViewDelegate;
@property (nonatomic, retain) id<JCHortizontalTableViewDataSource> horizontalTableViewDataSource;

- (void)reloadData;
- (id)dequeueReusableCell;

@end