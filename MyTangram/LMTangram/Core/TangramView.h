//
//  TangramView.h
//  MyTangram
//
//  Created by tongleiming on 2019/3/25.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import "TMLazyScrollView.h"

@class TangramView;
@protocol LMTangramLayoutProtocol;
@protocol LMTangramItemModelProtocol;

@protocol TangramViewDatasource <NSObject>

@required

/**
 * return layout count in scrollView
 *
 * @param   view    TangramView
 * @return  number  Layout count in scrollView
 */
- (NSUInteger)numberOfLayoutsInTangramView:(TangramView *)view;

/**
 * return element(subviews in layout,like UICollectionViewCell) Count in specific card.
 *
 * @param   view    TangramView
 * @param   layout  layout return in element Count
 * @return  number  element in the layout
 */
//Layout的items数组中有多少个itemModel
- (NSUInteger)numberOfItemsInTangramView:(TangramView *)view forLayout:(UIView<LMTangramLayoutProtocol> *)layout;

/**
 * Get a layout by index.
 * Tangram requires this Layout must be a subclass of UIView ，and implement TangramLayoutProtocol
 * Layout is like to Layout in UICollectionView
 *
 * @param   view    TangramView
 * @param   index   Layout index
 * @return  layout  layout
 */
// 第i个layout
- (UIView<LMTangramLayoutProtocol> *)layoutInTangramView:(TangramView *)view atIndex:(NSUInteger)index;

/**
 * Get element by index in layout. Element must be a UIView or a subclass of UIView
 * Before init a new element , you can call `dequeueReusableItemWithIdentifier` to get a reuseable view first.
 *
 * @param   view    TangramView
 * @param   layout  layout
 * @param   index   index in Layout
 * @return  item    element
 */
// 创建Layout的第i个itemModel对应的element
- (UIView *)itemInTangramView:(TangramView *)view withModel:(NSObject<LMTangramItemModelProtocol> *)model forLayout:(UIView<LMTangramLayoutProtocol> *)layout  atIndex:(NSUInteger)index;

/**
 * According to the count returned from `numberOfItemsInTangramView`, generate a logical tree of models.
 * Here need return model by index and layout.
 *
 * @param   view    TangramView
 * @param   layout  Layout
 * @param   index   index in layout
 * @return  model   model，used to generate logical tree.
 */
// 返回layout的第i个itemModel
- (NSObject<LMTangramItemModelProtocol> *)itemModelInTangramView:(TangramView *)view forLayout:(UIView<LMTangramLayoutProtocol> *)layout atIndex:(NSUInteger)index;


@end

@interface TangramView : TMLazyScrollView

// Extra offset in vertical for StickyLayout and FixLayout
@property   (nonatomic, assign) CGFloat fixExtraOffset;

// Contains layouts in TangramView. Key ：layout index；value：layout
@property   (nonatomic, strong, readonly) NSMutableDictionary     *layoutDict;

// Enable margin deduplication function.
@property   (nonatomic, assign) BOOL enableMarginDeduplication;

- (void)setDataSource:(id<TangramViewDatasource>)dataSource;

// Refresh view according to datasource.
- (void)reloadData;

// When height of layer is changed and the model is not changed, call this method.
- (void)reLayoutContent;

@end

