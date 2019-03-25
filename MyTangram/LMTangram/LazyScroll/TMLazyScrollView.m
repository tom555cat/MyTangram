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

#pragma mark - getter & setter

- (NSSet<UIView *> *)visibleItems
{
    return [_visibleItems copy];
}

@end
