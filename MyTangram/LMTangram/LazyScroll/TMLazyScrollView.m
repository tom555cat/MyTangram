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

@interface TMLazyScrollView () {
    NSMutableSet<UIView *> *_visibleItems;
    
    // Store item models.
    TMLazyModelBucket *_modelBucket;
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
            TMLazyItemModel *itemModel = [self.dataSource scrollView:self itemModelAtIndex:index];
            if (itemModel.muiID.length == 0) {
                itemModel.muiID = [NSString stringWithFormat:@"%zd", index];
            }
            [_modelBucket addModel:itemModel];
        }
    }
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
