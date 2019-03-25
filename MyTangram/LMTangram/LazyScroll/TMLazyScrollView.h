//
//  TMLazyScrollView.h
//  MyTangram
//
//  Created by tom555cat on 2019/3/24.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMLazyReusePool.h"

@class TMLazyScrollView;

@protocol TMLazyScrollViewDataSource <NSObject>

@required

/**
 Similar with 'tableView:numberOfRowsInSection:' of UITableView.
 */
- (NSUInteger)numberOfItemsInScrollView:(nonnull TMLazyScrollView *)scrollView;

/**
 Similar with 'tableView:heightForRowAtIndexPath:' of UITableView.
 Manager the correct muiID of item views will bring a higher performance.
 */
- (nonnull TMLazyItemModel *)scrollView:(nonnull TMLazyScrollView *)scrollView itemModelAtIndex:(NSUInteger)index;

/**
 Similar with 'tableView:cellForRowAtIndexPath:' of UITableView.
 It will use muiID in item model instead of index.
 */
- (nonnull UIView *)scrollView:(nonnull TMLazyScrollView *)scrollView
                   itemByMuiID:(nonnull NSString *)muiID;

@end

@interface TMLazyScrollView : UIScrollView

@property (nonatomic, weak, nullable) id<TMLazyScrollViewDataSource> dataSource;

/**
 Used for managing reuseable item views.
 */
@property (nonatomic, strong, nonnull) TMLazyReusePool *reusePool;

/**
 LazyScrollView can be used as a subview of another ScrollView.
 For example:
 You can use LazyScrollView as footerView of TableView.
 Then the outerScrollView should be that TableView.
 You MUST set this property to nil before the outerScrollView's dealloc.
 */
// 是当前scrollView所在的scrollView，注意是weak引用的。
@property (nonatomic, weak, nullable) UIScrollView *outerScrollView;

/**
 If it is YES, LazyScrollView will clear all gestures for item view before
 reusing it.
 Default value is YES.
 */
@property (nonatomic, assign) BOOL autoClearGestures;

- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier;


/**
 Hide all visible items and recycle reusable item views.
 After call this method, every item view will receive
 'afterGetView' & 'didEnterWithTimes' again.
 
 @param enableRecycle  Recycle items or remove them.
 */
- (void)clearVisibleItems:(BOOL)enableRecycle;

- (void)reloadData;

@end
