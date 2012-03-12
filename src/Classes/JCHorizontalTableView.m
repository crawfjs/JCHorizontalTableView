//
//  JCHorizontalTableView.m
//  AnaWhite
//
//  Created by Crawfjs on 3/12/12.
//  Copyright (c) 2012 Jaceyroo.com. All rights reserved.
//

#import "JCHorizontalTableView.h"

@interface JCHorizontalTableView(PrivateMethods)<UIScrollViewDelegate,UIWebViewDelegate>
- (void)updateCellLists;
- (void)handleTap:(UITapGestureRecognizer*)sender;
@end

@implementation JCHorizontalTableView

@synthesize horizontalTableViewDelegate, horizontalTableViewDataSource, padding;

- (id)initWithFrame:(CGRect)frame {
    if ( ( self = [super initWithFrame:frame] ) ) {
        _hashlist = [[NSMutableArray alloc] init];
        self.contentSize = frame.size;
        self.bounces = YES;
        self.delegate = self;
        self.padding = 5.0f;
    }
    return self;
}

- (void)dealloc {
    [_hashlist release], _hashlist = nil;
    
    self.horizontalTableViewDelegate = nil;
    self.horizontalTableViewDataSource = nil;
    
    [super dealloc];
}

- (void)reloadData {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subview in self.subviews) {
            [subview removeFromSuperview];
        }
        
        [_reusableCells release], _reusableCells = [[NSMutableArray alloc] init];
        [_visibleCells release], _visibleCells = [[NSMutableArray alloc] init];
        [_hashlist removeAllObjects];
        
        int columnCount = [self.horizontalTableViewDataSource numberOfColumnsInHorizontalTableView:self];
        
        CGFloat contentWidth = 0;
        for ( int i = 0; i < columnCount; i++ ) {
            contentWidth += padding;
            contentWidth += [self.horizontalTableViewDelegate horizontalTableView:self widthForColumnAtIndex:i];
            contentWidth += (self.pagingEnabled ? padding : 0);
        }
        contentWidth += (self.pagingEnabled ? 0 : padding);
        
        self.contentSize = CGSizeMake(contentWidth, self.contentSize.height);
        
        CGFloat offsetX = 0;
        for ( int i = 0; i < columnCount; i++ ) {
            offsetX += padding;
            CGFloat colWidth = [self.horizontalTableViewDelegate horizontalTableView:self widthForColumnAtIndex:i];
            NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSValue valueWithCGRect:CGRectMake(offsetX, 0, colWidth, self.frame.size.height)], @"_rect", nil];
            [_hashlist addObject:entry];
            
            offsetX += colWidth + (self.pagingEnabled ? padding : 0);
        }
        
        // Force the view to reload
        [self updateCellLists];
    });
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCellLists];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}

- (id)dequeueReusableCell {
    id response = nil;
    if ( [_reusableCells count] > 0 ) {
        response = [[[_reusableCells lastObject] objectForKey:@"_cell"] retain];
        [_reusableCells removeLastObject];
    }
    return [response autorelease];
}

#pragma mark - Private Methods -
- (void)handleTap:(UITapGestureRecognizer*)sender {
    if ( sender.state == UIGestureRecognizerStateEnded ) {
        NSNumber *idx = [sender.view performSelector:@selector(cellidx)];
        [self.horizontalTableViewDelegate horizontalTableView:self didSelectColumnAtIndex:[idx intValue]];
    }
}

- (void)updateCellLists {
    CGRect visibleRect;
    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.bounds.size;
    
    if ( [_visibleCells count] <= 0 ) {
        int count = 0;
        int offsetX = padding;
        for (NSDictionary *entry in _hashlist) {
            if ( CGRectIntersectsRect(visibleRect, [[entry valueForKey:@"_rect"] CGRectValue]) ) {
                JCHorizontalTableViewCell * visibleCell = [self.horizontalTableViewDataSource horizontalTableView:self cellForColumnAtIndex:count];
                CGRect visibleCellFrame = visibleCell.frame;
                visibleCellFrame.origin = CGPointMake(offsetX, padding);
                visibleCell.frame = visibleCellFrame;
                
                offsetX += visibleCell.frame.size.width + padding + (self.pagingEnabled ? padding : 0);
                
                BOOL addGesture = YES;
                for (UIGestureRecognizer *recognizer in visibleCell.gestureRecognizers) {
                    if ( [recognizer isKindOfClass:[UITapGestureRecognizer class]] ) {
                        addGesture = NO;
                    }
                }
                
                if ( addGesture ) {
                    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
                    tapRecognizer.numberOfTapsRequired = 1;
                    [visibleCell addGestureRecognizer:tapRecognizer];
                    [tapRecognizer release], tapRecognizer = nil;
                }
                
                if ( [visibleCell respondsToSelector:@selector(setCellidx:)] ) {
                    [visibleCell performSelector:@selector(setCellidx:) withObject:[NSNumber numberWithInt:count]];
                }
                
                [self addSubview:visibleCell];
                [_visibleCells addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:count],@"_idx",
                                          visibleCell,@"_cell", nil]];
            }
            count++;
        }
    }
    else {
        //  for each visible cell
        //      if its no longer vis - enqueue
        NSArray *visibleCells = [_visibleCells copy];
        @try {
            for (NSDictionary *cellInfo  in visibleCells) {
                JCHorizontalTableViewCell *cell = [cellInfo objectForKey:@"_cell"];
                if ( !CGRectIntersectsRect(visibleRect, cell.frame) ) {
                    [cell didDisappear];
                    [cell removeFromSuperview];
                    [_reusableCells addObject:cellInfo];
                    [_visibleCells removeObject:cellInfo];
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception in %@\n%@\n%@", NSStringFromClass([self class]), [exception reason], [exception callStackSymbols]);
        }
        @finally {
            [visibleCells release];
        }
        
        // if max+1 is visible, call load
        @try {
            NSDictionary *lastEntry = [_visibleCells lastObject];
            JCHorizontalTableViewCell *lastCell = [lastEntry objectForKey:@"_cell"];
            if ( CGRectIntersectsRect(visibleRect, lastCell.frame) ) {
                int idx = [[lastEntry objectForKey:@"_idx"] intValue] + 1;
                while ( idx < [_hashlist count] && CGRectIntersectsRect(visibleRect, lastCell.frame)) {
                    
                    CGFloat width = [self.horizontalTableViewDelegate horizontalTableView:self widthForColumnAtIndex:idx];
                    
                    CGRect nextCellFrame = lastCell.frame;
                    nextCellFrame.origin = CGPointMake( nextCellFrame.origin.x + padding + (self.pagingEnabled ? padding : 0) + width, nextCellFrame.origin.y );
                    
                    if ( CGRectIntersectsRect(visibleRect, nextCellFrame) ) {
                        
                        JCHorizontalTableViewCell * visibleCell = [self.horizontalTableViewDataSource horizontalTableView:self cellForColumnAtIndex:idx ];
                        
                        CGRect visibleCellFrame = visibleCell.frame;
                        visibleCellFrame.origin = CGPointMake(lastCell.frame.origin.x + lastCell.frame.size.width + padding + (self.pagingEnabled ? padding : 0), padding);
                        visibleCell.frame = visibleCellFrame;
                        
                        BOOL addGesture = YES;
                        for (UIGestureRecognizer *recognizer in visibleCell.gestureRecognizers) {
                            if ( [recognizer isKindOfClass:[UITapGestureRecognizer class]] ) {
                                addGesture = NO;
                            }
                        }
                        
                        if ( addGesture ) {
                            tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
                            tapRecognizer.numberOfTapsRequired = 1;
                            [visibleCell addGestureRecognizer:tapRecognizer];
                            [tapRecognizer release], tapRecognizer = nil;
                        }
                        
                        if ( [visibleCell respondsToSelector:@selector(setCellidx:)] ) {
                            [visibleCell performSelector:@selector(setCellidx:) withObject:[NSNumber numberWithInt:idx]];
                        }
                        
                        NSDictionary *visibleCellData = [NSDictionary dictionaryWithObjectsAndKeys:
                                                         [NSNumber numberWithInt:idx],
                                                         @"_idx",visibleCell,@"_cell", nil];
                        [_visibleCells addObject:visibleCellData];
                        [self addSubview:visibleCell];
                        
                        idx += 1;
                        lastCell = visibleCell;
                    }
                    else {
                        break;
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception in %@\n%@\n%@", NSStringFromClass([self class]), [exception reason], [exception callStackSymbols]);
        }
        @finally {
        }
        
        // if min-1 is visible, call load
        @try {
            NSDictionary *firstEntry = [_visibleCells objectAtIndex:0];
            JCHorizontalTableViewCell *firstCell = [firstEntry objectForKey:@"_cell"];
            if ( CGRectIntersectsRect(visibleRect, firstCell.frame) ) {
                int idx = [[firstEntry objectForKey:@"_idx"] intValue] - 1;
                while ( idx >= 0 && CGRectIntersectsRect(visibleRect, firstCell.frame) ) {
                    
                    CGFloat width = [self.horizontalTableViewDelegate horizontalTableView:self widthForColumnAtIndex:idx];
                    
                    CGRect previousCellFrame = firstCell.frame;
                    previousCellFrame.origin = CGPointMake( previousCellFrame.origin.x - padding - (self.pagingEnabled ? padding : 0) - width, previousCellFrame.origin.y );
                    
                    if ( CGRectIntersectsRect(visibleRect, previousCellFrame) ) {
                        JCHorizontalTableViewCell * visibleCell = [self.horizontalTableViewDataSource horizontalTableView:self cellForColumnAtIndex:idx];
                        
                        CGRect visibleCellFrame = visibleCell.frame;
                        visibleCellFrame.origin = CGPointMake(firstCell.frame.origin.x - visibleCell.frame.size.width - padding - (self.pagingEnabled ? padding : 0), padding);
                        visibleCell.frame = visibleCellFrame;
                        
                        if ( [visibleCell respondsToSelector:@selector(setCellidx:)] ) {
                            [visibleCell performSelector:@selector(setCellidx:) withObject:[NSNumber numberWithInt:idx]];
                        }
                        
                        BOOL addGesture = YES;
                        for (UIGestureRecognizer *recognizer in visibleCell.gestureRecognizers) {
                            if ( [recognizer isKindOfClass:[UITapGestureRecognizer class]] ) {
                                addGesture = NO;
                            }
                        }
                        
                        if ( addGesture ) {
                            tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
                            tapRecognizer.numberOfTapsRequired = 1;
                            [visibleCell addGestureRecognizer:tapRecognizer];
                            [tapRecognizer release], tapRecognizer = nil;
                        }
                        
                        [self addSubview:visibleCell];
                        [_visibleCells insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithInt:idx],@"_idx",
                                                     visibleCell,@"_cell", nil] atIndex:0];
                        
                        idx -= 1;
                        firstCell = visibleCell;
                    }
                    
                    else {
                        break;
                    }
                    
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception in %@\n%@\n%@", NSStringFromClass([self class]), [exception reason], [exception callStackSymbols]);
        }
        @finally {
        }
    }
}

@end
