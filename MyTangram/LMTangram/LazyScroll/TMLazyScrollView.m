//
//  TMLazyScrollView.m
//  MyTangram
//
//  Created by tom555cat on 2019/3/24.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import "TMLazyScrollView.h"
#import "UIView+TMLazyScrollView.h"
#import "TMLazyItemViewProtocol.h"
#import "TMLazyModelBucket.h"
#import "TMLazyItemModel.h"

#define LazyBufferHeight 20
#define LazyBucketHeight 400

@interface TMLazyScrollView () {
    NSMutableSet<UIView *> *_visibleItems;
    
    // Store item models.
    // _modelBucket中保存的是itemModel对应的TMLazyItemModel，其中
    // 保存了itemModel的frame信息
    TMLazyModelBucket *_modelBucket;
    // 所有的layout的item的总数
    NSInteger _itemCount;
    
    // Record current muiID of reloading item.
    // Will be used for dequeueReusableItem methods.
    NSString *_currentReloadingMuiID;
    
}

@end

@implementation TMLazyScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        _reusePool = [TMLazyReusePool new];
        
        _visibleItems = [[NSMutableSet alloc] init];
        
        _modelBucket = [[TMLazyModelBucket alloc] initWithBucketHeight:LazyBucketHeight];
    }
    return self;
}

- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier
{
    return [self dequeueReusableItemWithIdentifier:identifier muiID:nil];
}

- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier muiID:(NSString *)muiID
{
    UIView *result = nil;
    if (_currentReloadingMuiID) {
        for (UIView *item in _visibleItems) {
            if ([item.muiID isEqualToString:_currentReloadingMuiID]
                && [item.reuseIdentifier isEqualToString:identifier]) {
                result = item;
                break;
            }
        }
    }
    if (result == nil) {
        result = [self.reusePool dequeueItemViewForReuseIdentifier:identifier andMuiID:muiID];
    }
    if (result) {
        if (self.autoClearGestures) {
            result.gestureRecognizers = nil;
        }
        if ([result respondsToSelector:@selector(mui_prepareForReuse)]) {
            [(UIView<TMLazyItemViewProtocol> *)result mui_prepareForReuse];
        }
    }
    return result;
}

#pragma mark Clear & Reset

- (void)clearVisibleItems:(BOOL)enableRecycle
{
    if (enableRecycle) {
        for (UIView *itemView in _visibleItems) {
            itemView.hidden = YES;
            if (itemView.reuseIdentifier.length > 0) {
                [self.reusePool addItemView:itemView forReuseIdentifier:itemView.reuseIdentifier];
            }
        }
    } else {
        for (UIView *itemView in _visibleItems) {
            [itemView removeFromSuperview];
        }
    }
    [_visibleItems removeAllObjects];
}

- (void)reloadData
{
    // 重新记录itemModel对应的frame信息model信息
    [self storeItemModelsFromIndex:0];
    [self assembleSubviews:YES];
}

- (void)storeItemModelsFromIndex:(NSInteger)startIndex
{
    if (startIndex == 0) {
        _itemCount = 0;
        [_modelBucket clear];
    }
    if (self.dataSource) {
        _itemCount = [self.dataSource numberOfItemsInScrollView:self];
        for (NSInteger index = startIndex; index < _itemCount; index++) {
            // TMLazyItemModel类型的itemModel就是记录了每个itemModel的frame信息
            TMLazyItemModel *itemModel = [self.dataSource scrollView:self itemModelAtIndex:index];
            if (itemModel.muiID.length == 0) {
                itemModel.muiID = [NSString stringWithFormat:@"%zd", index];
            }
            //
            [_modelBucket addModel:itemModel];
        }
    }
}

- (void)assembleSubviews:(BOOL)isReload
{
    if (self.outerScrollView) {
        CGRect frame = [self.superview convertRect:self.frame toView:self.outerScrollView];
        CGRect visibleArea = CGRectIntersection(self.outerScrollView.bounds, frame);
        if (visibleArea.size.height > 0) {
            CGFloat offsetY = CGRectGetMinY(frame);
            CGFloat minY = CGRectGetMinY(visibleArea) - offsetY;
            CGFloat maxY = CGRectGetMaxY(visibleArea) - offsetY;
            [self assembleSubviews:isReload minY:minY maxY:maxY];
        } else {
            [self assembleSubviews:isReload minY:0 maxY:-LazyBufferHeight * 2];
        }
    } else {
        CGFloat minY = CGRectGetMinY(self.bounds);
        CGFloat maxY = CGRectGetMaxY(self.bounds);
        [self assembleSubviews:isReload minY:minY maxY:maxY];
    }
}

- (void)assembleSubviews:(BOOL)isReload minY:(CGFloat)minY maxY:(CGFloat)maxY
{
    // Calculate which item views should be shown.
    // Calculating will cost some time, so here is a buffer for reducing
    // times of calculating.
    NSSet<TMLazyItemModel *> *newVisibleModels = [_modelBucket showingModelsFrom:minY - LazyBufferHeight
                                                                              to:maxY + LazyBufferHeight];
    NSSet<NSString *> *newVisibleMuiIDs = [newVisibleModels valueForKey:@"muiID"];
    
    // Find if item views are in visible area.
    // Recycle invisible item views.
    [self recycleItems:isReload newVisibleMuiIDs:newVisibleMuiIDs];
    
    // Calculate the inScreenVisibleModels.
    _lastInScreenVisibleMuiIDs = [_inScreenVisibleMuiIDs copy];
    [_inScreenVisibleMuiIDs removeAllObjects];
    for (TMLazyItemModel *itemModel in newVisibleModels) {
        if (itemModel.top < maxY && itemModel.bottom > minY) {
            [_inScreenVisibleMuiIDs addObject:itemModel.muiID];
        }
    }
    
    // Generate or reload visible item views.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(generateItems:) object:@(NO)];
    _newVisibleMuiIDs = [newVisibleMuiIDs mutableCopy];
    [self generateItems:isReload];
}


#pragma mark - getter & setter

- (NSSet<UIView *> *)visibleItems
{
    return [_visibleItems copy];
}

- (void)setDataSource:(id<TMLazyScrollViewDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        if (dataSource == nil || [self isDataSourceValid:dataSource]) {
            _dataSource = dataSource;
#ifdef DEBUG
        } else {
            NSAssert(NO, @"TMLazyScrollView - Invalid dataSource.");
#endif
        }
    }
}

- (BOOL)isDataSourceValid:(id<TMLazyScrollViewDataSource>)dataSource
{
    return dataSource
    && [dataSource respondsToSelector:@selector(numberOfItemsInScrollView:)]
    && [dataSource respondsToSelector:@selector(scrollView:itemModelAtIndex:)]
    && [dataSource respondsToSelector:@selector(scrollView:itemByMuiID:)];
}

@end
