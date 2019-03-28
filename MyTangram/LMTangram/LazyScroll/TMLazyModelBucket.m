//
//  TMLazyModelBucket.m
//  LazyScrollView
//
//  Copyright (c) 2015-2018 Alibaba. All rights reserved.
//

#import "TMLazyModelBucket.h"

@interface TMLazyModelBucket () {
    NSMutableArray<NSMutableSet *> *_buckets;
}

@end

@implementation TMLazyModelBucket

@synthesize bucketHeight = _bucketHeight;

- (instancetype)initWithBucketHeight:(CGFloat)bucketHeight
{
    if (self = [super init]) {
        // 难道_bucketHeight的目的就是一次性处理bucketHeight高度的itemModel吗？
        _bucketHeight = bucketHeight;
        _buckets = [NSMutableArray array];
    }
    return self;
}


/**
 将显示区域划分成每bucketHeight作为一个bucket，对应着一个set，set中存放
 着当前bucketHeight区域的item。
 */
- (void)addModel:(TMLazyItemModel *)itemModel
{
    if (itemModel && itemModel.bottom > itemModel.top) {
        NSInteger startIndex = (NSInteger)floor(itemModel.top / _bucketHeight);
        NSInteger endIndex = (NSInteger)floor((itemModel.bottom - 0.01) / _bucketHeight);
        for (NSInteger index = 0; index <= endIndex; index++) {
            if (_buckets.count <= index) {
                [_buckets addObject:[NSMutableSet set]];
            }
            if (index >= startIndex && index <= endIndex) {
                NSMutableSet *bucket = [_buckets objectAtIndex:index];
                [bucket addObject:itemModel];
            }
        }
    }
}

- (void)addModels:(NSSet<TMLazyItemModel *> *)itemModels
{
    if (itemModels) {
        for (TMLazyItemModel *itemModel in itemModels) {
            [self addModel:itemModel];
        }
    }
}

- (void)removeModel:(TMLazyItemModel *)itemModel
{
    if (itemModel) {
        for (NSMutableSet *bucket in _buckets) {
            [bucket removeObject:itemModel];
        }
    }
}

- (void)removeModels:(NSSet<TMLazyItemModel *> *)itemModels
{
    if (itemModels) {
        for (NSMutableSet *bucket in _buckets) {
            [bucket minusSet:itemModels];
        }
    }
}

- (void)reloadModel:(TMLazyItemModel *)itemModel
{
    [self removeModel:itemModel];
    [self addModel:itemModel];
}

- (void)reloadModels:(NSSet<TMLazyItemModel *> *)itemModels
{
    [self removeModels:itemModels];
    [self addModels:itemModels];
}

- (void)clear
{
    [_buckets removeAllObjects];
}

// 获取显示区范围之内的LazyItemModel
- (NSSet<TMLazyItemModel *> *)showingModelsFrom:(CGFloat)startY to:(CGFloat)endY
{
    NSMutableSet *result = [NSMutableSet set];
    NSInteger startIndex = (NSInteger)floor(startY / _bucketHeight);
    NSInteger endIndex = (NSInteger)floor((endY - 0.01) / _bucketHeight);
    for (NSInteger index = 0; index <= endIndex; index++) {
        if (_buckets.count > index && index >= startIndex && index <= endIndex) {
            // 将所有显示区域的bucket对应的set中的itemModel并在一个集合result中。
            NSSet *bucket = [_buckets objectAtIndex:index];
            [result unionSet:bucket];
        }
    }
    // 从result中过滤出在显示区之外的itemModel
    NSMutableSet *needToBeRemoved = [NSMutableSet set];
    for (TMLazyItemModel *itemModel in result) {
        if (itemModel.top >= endY || itemModel.bottom <= startY) {
            [needToBeRemoved addObject:itemModel];
        }
    }
    [result minusSet:needToBeRemoved];
    return [result copy];
}

@end
