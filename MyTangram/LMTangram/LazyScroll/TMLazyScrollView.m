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
    
    // 这里边存放的是真正的element视图
    NSMutableSet<UIView *> *_visibleItems;
    
    // Store item models.
    // _modelBucket中保存的是itemModel对应的TMLazyItemModel，其中
    // 保存了itemModel的frame信息
    TMLazyModelBucket *_modelBucket;
    // 所有的layout的item的总数
    NSInteger _itemCount;
    
    // Record current muiID of reloading item.
    // Will be used for dequeueReusableItem methods.
    // 当前需要刷新的muiID。
    NSString *_currentReloadingMuiID;
    
    // 从名字上看，就是在可是范围内的MuiIDs。
    NSMutableSet<NSString *> *_inScreenVisibleMuiIDs;
    
    // Store muiID of items which are visible last time.
    // 应该是reloadData之前上次的屏幕可是范围内的MuiIDs的集合。
    NSSet<NSString *> *_lastInScreenVisibleMuiIDs;
    
    // Store muiID of items which should be visible.
    // 这个reloadData中在新的可视范围内的model的MuiID的set
    NSMutableSet<NSString *> *_newVisibleMuiIDs;
    
    // Store muiID of items which need to be reloaded.
    // 存储需要重载内容的item对应的muiID
    NSMutableSet<NSString *> *_needReloadingMuiIDs;
    
    // Store the enter screen times of items.
    // 记录MuiID对应的出现次数
    NSMutableDictionary<NSString *, NSNumber *> *_enterTimesDict;
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
        
        _loadAllItemsImmediately = YES;
        
        // 初始化的时候传递了一个(LazyBucketHeight 400)的参数，这个参数起到了什么作用？
        _modelBucket = [[TMLazyModelBucket alloc] initWithBucketHeight:LazyBucketHeight];
        
        _inScreenVisibleMuiIDs = [NSMutableSet set];
        
        _needReloadingMuiIDs = [[NSMutableSet alloc] init];
        
        _enterTimesDict = [[NSMutableDictionary alloc] init];
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
    // 获取显示范围之内的LazyItemModel(包含着frame信息)的数组
    NSSet<TMLazyItemModel *> *newVisibleModels = [_modelBucket showingModelsFrom:minY - LazyBufferHeight
                                                                              to:maxY + LazyBufferHeight];
    
    // 获取显示范围之内的这些lazyItemModel对应的muiID
    NSSet<NSString *> *newVisibleMuiIDs = [newVisibleModels valueForKey:@"muiID"];
    
    // Find if item views are in visible area.
    // Recycle invisible item views.
    [self recycleItems:isReload newVisibleMuiIDs:newVisibleMuiIDs];
    
    // Calculate the inScreenVisibleModels.
    // 将在屏item保存进离屏item set中
    _lastInScreenVisibleMuiIDs = [_inScreenVisibleMuiIDs copy];
    // 将在屏item清空
    [_inScreenVisibleMuiIDs removeAllObjects];
    // 重新填充在屏item MuiID
    for (TMLazyItemModel *itemModel in newVisibleModels) {
        if (itemModel.top < maxY && itemModel.bottom > minY) {
            [_inScreenVisibleMuiIDs addObject:itemModel.muiID];
        }
    }
    
    // Generate or reload visible item views.
    // cancelPreviousPerformRequestWithTarget:selector:object:是与performSelector:withObject:afterDelay:
    // 相对应的方法，是取消之前的方法。说明有地方使用了performSelector:withObject:afterDelay:方法。
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(generateItems:) object:@(NO)];
    _newVisibleMuiIDs = [newVisibleMuiIDs mutableCopy];
    // 在执行generateItems:之前，先调用cancelPreviousPerformRequestsWithTarget:进行取消。
    [self generateItems:isReload];
}

- (void)generateItems:(BOOL)isReload
{
    if (_newVisibleMuiIDs == nil || _newVisibleMuiIDs.count == 0) {
        return;
    }
    
    // 从_newVisibleMuiIDs中获取muiID
    NSString *muiID = [_newVisibleMuiIDs anyObject];
    BOOL hasLoadAnItem = NO;
    
    // 1. Item view is not visible. We should create or reuse an item view.
    // 2. Item view need to be reloaded.
    //
    BOOL isVisible = [self isMuiIdVisible:muiID];
    BOOL needReload = [_needReloadingMuiIDs containsObject:muiID];
    if (isVisible == NO || needReload == YES) {
        // 如果muiID不可以见，或者是需要刷新
        if (self.dataSource) {
            hasLoadAnItem = YES;
            
            // If you call dequeue method in your dataSource, the currentReloadingMuiID
            // will be used for searching the best-matched reusable view.
            if (isVisible == YES) {
                // 如果当前view可见，则需要尽心刷新
                _currentReloadingMuiID = muiID;
            }
            UIView *itemView = [self.dataSource scrollView:self itemByMuiID:muiID];
            _currentReloadingMuiID = nil;
            
            if (itemView) {
                // Call afterGetView.
                
                // 调用AOP函数
                if ([itemView respondsToSelector:@selector(mui_afterGetView)]) {
                    [(UIView<TMLazyItemViewProtocol> *)itemView mui_afterGetView];
                }
                // Show the item view.
                itemView.muiID = muiID;
                itemView.hidden = NO;
                if (self.autoAddSubview) {
                    if (itemView.superview != self) {
                        [self addSubview:itemView];
                    }
                }
                // Add item view to visibleItems.
                if (isVisible == NO) {
                    [_visibleItems addObject:itemView];
                }
            }
            
            [_needReloadingMuiIDs removeObject:muiID];
        }
    }
    
    // Call didEnterWithTimes.
    // didEnterWithTimes will only be called when item view enter the in screen
    // visible area, so we have to write the logic at here.
    if ([_lastInScreenVisibleMuiIDs containsObject:muiID] == NO
        && [_inScreenVisibleMuiIDs containsObject:muiID] == YES) {
        for (UIView *itemView in _visibleItems) {
            if ([itemView.muiID isEqualToString:muiID]) {
                if ([itemView respondsToSelector:@selector(mui_didEnterWithTimes:)]) {
                    NSInteger times = [_enterTimesDict tm_integerForKey:itemView.muiID];
                    times++;
                    [_enterTimesDict tm_safeSetObject:@(times) forKey:itemView.muiID];
                    [(UIView<TMLazyItemViewProtocol> *)itemView mui_didEnterWithTimes:times];
                }
                break;
            }
        }
    }
    
    [_newVisibleMuiIDs removeObject:muiID];
    // 处理完当前屏幕可视范围内的_newVisibleMuiIDs中的一个muiID，还有其他的muiID，则继续处理
    if (_newVisibleMuiIDs.count > 0) {
        // loadAllItemsImmediately是立即加载m，默认值是yes，则会同步加载剩余的element
        if (isReload == YES || self.loadAllItemsImmediately == YES || hasLoadAnItem == NO) {
            [self generateItems:isReload];
        } else {
            [self performSelector:@selector(generateItems:)
                       withObject:@(isReload)
                       afterDelay:0.0000001
                          inModes:@[NSRunLoopCommonModes]];
        }
    }
}


- (void)recycleItems:(BOOL)isReload newVisibleMuiIDs:(NSSet<NSString *> *)newVisibleMuiIDs
{
    NSSet *visibleItemsCopy = [_visibleItems copy];
    for (UIView *itemView in visibleItemsCopy) {
        BOOL isToShow  = [newVisibleMuiIDs containsObject:itemView.muiID];
        if (!isToShow) {
            // Call didLeave.
            if ([itemView respondsToSelector:@selector(mui_didLeave)]){
                [(UIView<TMLazyItemViewProtocol> *)itemView mui_didLeave];
            }
            if (itemView.reuseIdentifier.length > 0) {
                itemView.hidden = YES;
                [self.reusePool addItemView:itemView forReuseIdentifier:itemView.reuseIdentifier];
                [_visibleItems removeObject:itemView];
            } else if(isReload && itemView.muiID) {
                [_needReloadingMuiIDs addObject:itemView.muiID];
            }
        } else if (isReload && itemView.muiID) {
            [_needReloadingMuiIDs addObject:itemView.muiID];
        }
    }
}

#pragma mark - Private

- (BOOL)isMuiIdVisible:(NSString *)muiID
{
    for (UIView *itemView in _visibleItems) {
        if ([itemView.muiID isEqualToString:muiID]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - getter & setter

- (NSSet<UIView *> *)inScreenVisibleItems
{
    NSMutableSet<UIView *> * inScreenVisibleItems = [NSMutableSet set];
    for (UIView *view in _visibleItems) {
        if ([_inScreenVisibleMuiIDs containsObject:view.muiID]) {
            [inScreenVisibleItems addObject:view];
        }
    }
    return [inScreenVisibleItems copy];
}

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
