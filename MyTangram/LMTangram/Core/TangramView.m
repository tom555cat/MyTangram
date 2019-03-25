//
//  TangramView.m
//  MyTangram
//
//  Created by tongleiming on 2019/3/25.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import "TangramView.h"
#import "UIView+VirtualView.h"
#import "TMUtils.h"
#import "LMTangramLayoutProtocol.h"
#import "TangramStickyLayout.h"
#import "TangramDragableLayout.h"
#import "TangramFixLayout.h"

@interface TangramView ()

@property (nonatomic, weak, setter=setDataSource:) id<TangramViewDatasource>       clDataSource;

// Element Count in every layout. key ：layoutKey；value ：element count in a layout(NSNumber)
// 每个layout中有多少个items，key为layoutIndex，value为itemCount的数目
@property   (nonatomic, strong) NSMutableDictionary     *numberOfItemsInlayout;

// Contains layouts in TangramView. Key ：layout index；value：layout
//
@property   (nonatomic, strong) NSMutableDictionary     *layoutDict;

// Layout Key List
// 据说是layout的key构成的数组
@property   (nonatomic, strong) NSMutableArray          *layoutKeyArray;

//#####三种类型的layout保存在这几个数组里#####
// FixLayout Array
@property   (nonatomic, strong) NSMutableArray          *fixLayoutArray;
// StickyLayout Array
@property   (nonatomic, strong) NSMutableArray          *stickyLayoutArray;
// DragableLayout Array
@property   (nonatomic, strong) NSMutableArray          *dragableLayoutArray;



@end

@implementation TangramView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [super setDataSource:self];
    }
    return self;
}

- (void)reloadData {
    if (self.clDataSource
        && [self.clDataSource conformsToProtocol:@protocol(TangramViewDatasource)]
        && [self.clDataSource respondsToSelector:@selector(numberOfLayoutsInTangramView:)]
        && [self.clDataSource respondsToSelector:@selector(layoutInTangramView:atIndex:)]
        && [self.clDataSource respondsToSelector:@selector(itemModelInTangramView:forLayout:atIndex:)]
        && [self.clDataSource respondsToSelector:@selector(numberOfItemsInTangramView:forLayout:)]
        ) {
        //Generate layout, remove old layout
        // 进行reloadData，首先将数据全部清空。
        // reloadData不会清理当前屏幕上的视图。
        [self removeLayoutsAndElements:NO];
        
        // 重新调用DataSource的方法，将刚才清理的数据重新设置好
        NSUInteger numberOfLayouts = [self.clDataSource numberOfLayoutsInTangramView:self];
        [self.layoutDict removeAllObjects];
        [self.layoutKeyArray removeAllObjects];
        for (UIView * view in self.fixLayoutArray) {
            [view removeFromSuperview];
        }
        [self.fixLayoutArray removeAllObjects];
        for (UIView *view in self.stickyLayoutArray) {
            [view removeFromSuperview];
        }
        [self.stickyLayoutArray removeAllObjects];
        for (UIView *view in self.dragableLayoutArray) {
            [view removeFromSuperview];
        }
        [self.dragableLayoutArray removeAllObjects];
        for (int i=0; i< numberOfLayouts; i++) {
            NSString *layoutKey = [NSString stringWithFormat:@"%d", i];
            // BUSMARK - get layout
            UIView<LMTangramLayoutProtocol> *layout = [self.clDataSource layoutInTangramView:self atIndex:i];
            // 将layout存放进layoutDict中，key为index
            [self.layoutDict tm_safeSetObject:layout forKey:layoutKey];
            // key为index
            [self.layoutKeyArray tm_safeAddObject:layoutKey];
            
            NSUInteger numberOfItemsInLayout = [self.clDataSource numberOfItemsInTangramView:self forLayout:layout];
            
            // 如果layout的items为0，并且xxxx，则直接返回。
            if(numberOfItemsInLayout == 0 && [layout respondsToSelector:@selector(loadAPI)] && [layout loadAPI].length > 0)
            {
                continue;
            }
            if ([layout respondsToSelector:@selector(setEnableMarginDeduplication:)]) {
                [layout setEnableMarginDeduplication:self.enableMarginDeduplication];
            }
            
            // 设置每个layout中有多少个items数目
            [self.numberOfItemsInlayout tm_safeSetObject:@(numberOfItemsInLayout) forKey:layoutKey];
            
            if ([layout respondsToSelector:@selector(position)] && layout.position && layout.position.length > 0)
            {
                if ([layout.position isEqualToString:@"top-fixed"] || [layout.position isEqualToString:@"bottom-fixed"] || [layout.position isEqualToString:@"fixed"] ) {
                    [self.fixLayoutArray tm_safeAddObject:layout];
                }
                if ([layout.position isEqualToString:@"sticky"]) {
                    [self.stickyLayoutArray tm_safeAddObject:layout];
                }
                if ([layout.position isEqualToString:@"float"]){
                    [self.dragableLayoutArray tm_safeAddObject:layout];
                }
            }
            NSMutableArray *modelArray = [[NSMutableArray alloc] init];
            for (int j=0; j<numberOfItemsInLayout; j++) {
                [modelArray tm_safeAddObject:[self.clDataSource itemModelInTangramView:self forLayout:layout atIndex:j]];
            }
            [layout setItemModels:[NSArray arrayWithArray:modelArray]];
        }

        [self layoutContentWithCalculateLayout:YES];
    }
    [super reloadData];
}

// 进行reloadData，首先将数据全部清空
- (void)removeLayoutsAndElements:(BOOL)cleanElement;
{
    // 将所有的layout全部从tangramView中移出去
    for (UIView *layout in [self.layoutDict allValues]) {
        [layout removeFromSuperview];
    }
    [self.layoutDict removeAllObjects];
    [self.layoutKeyArray removeAllObjects];
    // 这三种layout进行清空
    [self.dragableLayoutArray removeAllObjects];
    [self.fixLayoutArray removeAllObjects];
    [self.stickyLayoutArray removeAllObjects];
    if (cleanElement) {
        // 清理掉当前屏幕的UIView，参数为是否回收，
        // 如果是回收的话，就将数据存放进了reusePool中去了。
        [super clearVisibleItems:YES];
        // 改变当前的contentSize，设置为当前view的宽和高
        self.contentSize = CGSizeMake(self.vv_width, self.vv_height);
    }
}

//if calculate is YES, here will call the `calculateLayout` method of layout.
// 这个方法，就是更加itemModel的内部宽高从而计算每个layout的宽和高，从而累加得到TangramView的contentSize的宽和高
-(void)layoutContentWithCalculateLayout:(BOOL)calculate
{
    CGFloat layoutTop = 0.f;
    CGFloat lastLayoutTop = 0.f;
    CGFloat lastLayoutMarginBottom = 0.f;
    CGFloat contentHeight = 0.f;
    CGFloat contentWidth = 0.f;
    CGFloat topOffset = 0.f;
    NSMutableDictionary *zIndexLayoutDict = [[NSMutableDictionary alloc]init];
    for (UIView<LMTangramLayoutProtocol> *layout in self.stickyLayoutArray) {
        // 对于可悬浮的layout，先将其进入悬浮状态置为NO
        ((TangramStickyLayout *)layout).enterFloatStatus = NO;
    }
    for (int i=0; i< self.layoutKeyArray.count; i++) {
        NSString *layoutKey = [self.layoutKeyArray tm_stringAtIndex:i];
        UIView<LMTangramLayoutProtocol> *layout = [self.layoutDict tm_safeObjectForKey:layoutKey];
        NSUInteger numberOfItemsInLayout = [self.clDataSource numberOfItemsInTangramView:self forLayout:layout];
        [self.numberOfItemsInlayout tm_safeSetObject:@(numberOfItemsInLayout) forKey:layoutKey];
        // 根据Layout的实现，计算其上边距
        CGFloat marginTop       = 0.f;
        // Make sure there are something in itemModel of layout
        if ([layout conformsToProtocol:@protocol(LMTangramLayoutProtocol)]
            && [layout respondsToSelector:@selector(marginTop)] && layout.itemModels.count > 0) {
            marginTop = [layout marginTop];
        }
        
        // 根据Layout的实现，计算其右边距
        CGFloat marginRight     = 0.f;
        if ([layout conformsToProtocol:@protocol(LMTangramLayoutProtocol)]
            && [layout respondsToSelector:@selector(marginRight)] && layout.itemModels.count > 0) {
            marginRight = [layout marginRight];
        }
        
        // 根据Layout的实现，计算其左边距
        CGFloat marginBottom    = 0.f;
        if ([layout conformsToProtocol:@protocol(LMTangramLayoutProtocol)]
            && [layout respondsToSelector:@selector(marginBottom)] && layout.itemModels.count > 0) {
            marginBottom = [layout marginBottom];
        }
        
        // 根据Layout的实现，计算其右边距
        CGFloat marginLeft      = 0.f;
        if ([layout conformsToProtocol:@protocol(LMTangramLayoutProtocol)]
            && [layout respondsToSelector:@selector(marginLeft)] && layout.itemModels.count > 0) {
            marginLeft = [layout marginLeft];
        }
        // BUSMARK - Add TangramView
        
        // 将layout加入到了TangramView中了。
        [self addSubview:layout];
        
        //CGFloat contentHeight = self.contentSize.height;
        //If the layout is  `FixLayout` or its subclass, its height will not be added to the height of contentSize.
        // 如果layout是fix的，那么其高度不会被计算进contentSize中。
        if ([layout respondsToSelector:@selector(position)]  && ([layout.position isEqualToString:@"top-fixed"] || [layout.position isEqualToString:@"bottom-fixed"] || [layout.position isEqualToString:@"float"] || [layout.position isEqualToString:@"fixed"]))
        {
            if (calculate) {
                [layout calculateLayout];
            }
            CGPoint originPoint = CGPointMake(0, 0);
            switch (((TangramFixLayout *)layout).alignType) {
                case TopLeft:
                    originPoint.x += ((TangramFixLayout *)layout).offsetX;
                    originPoint.y += ((TangramFixLayout *)layout).offsetY;
                    originPoint.y += self.fixExtraOffset;
                    if (topOffset < originPoint.y) {
                        //offset 保证和最高的固定布局保持一致
                        topOffset = originPoint.y;
                    }
                    break;
                case TopRight:
                    originPoint.x = self.vv_width - layout.vv_width - ((TangramFixLayout *)layout).offsetX;
                    originPoint.y += ((TangramFixLayout *)layout).offsetY;
                    originPoint.y += self.fixExtraOffset;
                    if (topOffset < originPoint.y) {
                        //offset 保证和最高的固定布局保持一致
                        topOffset = originPoint.y;
                    }
                    break;
                case BottomLeft:
                    originPoint.x += ((TangramFixLayout *)layout).offsetX;
                    originPoint.y = self.vv_height - layout.vv_height - ((TangramFixLayout *)layout).offsetY;
                    break;
                case BottomRight:
                    originPoint.x = self.vv_width - layout.vv_width - ((TangramFixLayout *)layout).offsetX;
                    originPoint.y = self.vv_height - layout.vv_height - ((TangramFixLayout *)layout).offsetY;
                    break;
            }
            ((TangramFixLayout *)layout).originPoint = originPoint;
            layout.frame = CGRectMake(originPoint.x , originPoint.y, layout.vv_width, layout.vv_height);
            switch (((TangramFixLayout *)layout).showType) {
                case FixLayoutShowOnLeave:
                    ((TangramFixLayout *)layout).showY = layoutTop;
                    if (calculate && layout.hidden == NO) {
                        layout.hidden = YES;
                    }
                    break;
                case FixLayoutShowOnEnter:
                    ((TangramFixLayout *)layout).showY = lastLayoutTop;
                    if (calculate && layout.hidden == YES) {
                        layout.hidden = NO;
                    }
                    break;
                case FixLayoutShowAlways:
                    break;
            }
        }
        //如果不是，那么算高度
        else{
            
            if (self.enableMarginDeduplication) {
                //marginTop和上一个marginBottom取大的
                layout.frame = CGRectMake(marginLeft, MAX(marginTop,lastLayoutMarginBottom) + layoutTop,
                                          CGRectGetWidth(self.frame) - marginLeft - marginRight, layout.frame.size.height);
            }
            else{
                layout.frame = CGRectMake(marginLeft, marginTop + layoutTop,
                                          CGRectGetWidth(self.frame) - marginLeft - marginRight, layout.frame.size.height);
            }
            
            // This method moves the specified view to the beginning of the array of views in the subviews property.
            // 将视图存放在subviews的前面
            [self sendSubviewToBack:layout];
            if(calculate)
            {
                //BUSMARK - layout布局
                [layout calculateLayout];
            }
            if (self.enableMarginDeduplication) {
                //如果启动了Margin去重，不算bottom，另算
                layoutTop = CGRectGetMaxY(layout.frame);
                //去重的话，需要记录一下上一个的marginBottom，下次要做对比
                lastLayoutMarginBottom = layout.marginBottom;
            }
            else{
                layoutTop = CGRectGetMaxY(layout.frame) + marginBottom;
            }
            lastLayoutTop = CGRectGetMinY(layout.frame);
            contentHeight   = CGRectGetMaxY(layout.frame) + layout.marginBottom;
        }
        contentWidth    = MAX(self.contentSize.width, CGRectGetWidth(layout.frame));
        if ([layout respondsToSelector:@selector(zIndex)] && layout.zIndex > 0) {
            //            layout.layer.zPosition = layout.zIndex;
            NSMutableArray *zIndexMutableArray = [zIndexLayoutDict tm_safeObjectForKey:[NSString stringWithFormat:@"%ld",(long)(layout.zIndex)] class:[NSMutableArray class]];
            if (zIndexMutableArray == nil) {
                zIndexMutableArray = [[NSMutableArray alloc]init];
            }
            [zIndexMutableArray tm_safeAddObject:layout];
            [zIndexLayoutDict tm_safeSetObject:zIndexMutableArray forKey:[NSString stringWithFormat:@"%ld",(long)(layout.zIndex)]];
        }
        else{
            NSMutableArray *zIndexMutableArray = [zIndexLayoutDict tm_safeObjectForKey:@"0" class:[NSMutableArray class]];
            if (zIndexMutableArray == nil) {
                zIndexMutableArray = [[NSMutableArray alloc]init];
            }
            [zIndexMutableArray tm_safeAddObject:layout];
            [zIndexLayoutDict tm_safeSetObject:zIndexMutableArray forKey:@"0"];
        }
        if ([layout.identifier isEqualToString:@"newer_banner_container-2"]) {
            layout.userInteractionEnabled = NO;
        }
    }
    NSArray *zIndexArray  = [[zIndexLayoutDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSInteger firstNumber = [obj1 integerValue];
        NSInteger secondNumber = [obj2 integerValue];
        if (firstNumber > secondNumber) {
            return  NSOrderedDescending;
        }
        else if(firstNumber < secondNumber){
            return NSOrderedAscending ;
        }
        else{
            return NSOrderedSame;
        }
    }];
    for (NSString *zIndex in zIndexArray) {
        NSMutableArray *zIndexMutableArray = [zIndexLayoutDict tm_safeObjectForKey:zIndex class:[NSMutableArray class]];
        for (UIView *layout in zIndexMutableArray) {
            [self bringSubviewToFront:layout];
        }
    }
    
    self.contentSize = CGSizeMake(contentWidth, contentHeight);
    if (self.contentSize.width > self.vv_width) {
        self.contentSize = CGSizeMake(self.vv_width, self.contentSize.height);
    }
    
    for (UIView *layout in self.dragableLayoutArray) {
        [self bringSubviewToFront:layout];
    }
    
    for (UIView<LMTangramLayoutProtocol> *layout in self.stickyLayoutArray) {
        //目前仅处理吸顶类型的顶部额外offset
        if (((TangramStickyLayout *)layout).stickyBottom == NO) {
            if (self.fixExtraOffset > 0.f) {
                ((TangramStickyLayout *)layout).extraOffset = self.fixExtraOffset;
            }
            //topOffset(实际偏移顶部的距离) 已经比extraOffset大了，那么已经不需要再网上加额外的offset了
            //有两个以及以上的吸顶有可能出现这种情况
            if (topOffset >= ((TangramStickyLayout *)layout).extraOffset) {
                ((TangramStickyLayout *)layout).extraOffset = 0.f;
            }
            topOffset += (((TangramStickyLayout *)layout).extraOffset + layout.vv_height);
        }
        [self bringSubviewToFront:layout];
    }
    for (UIView<LMTangramLayoutProtocol> *layout in self.fixLayoutArray) {
        [self bringSubviewToFront:layout];
    }
    //这个动作，是为了保证让Fixlayout的frame不因为contentOffset的突然改变而改变固定和浮动布局的位置
    //Research Mark
    self.contentOffset = self.contentOffset;
    
}

#pragma mark - getter & setter

- (NSMutableArray *)layoutKeyArray
{
    if (nil == _layoutKeyArray) {
        _layoutKeyArray = [[NSMutableArray alloc] init];
    }
    return _layoutKeyArray;
}

- (NSMutableDictionary *)layoutDict
{
    if (nil == _layoutDict) {
        _layoutDict = [[NSMutableDictionary alloc] init];
    }
    return _layoutDict;
}

- (NSMutableArray *)fixLayoutArray
{
    if (nil == _fixLayoutArray) {
        _fixLayoutArray = [[NSMutableArray alloc]init];
    }
    return _fixLayoutArray;
}
- (NSMutableArray *)stickyLayoutArray
{
    if (nil == _stickyLayoutArray) {
        _stickyLayoutArray = [[NSMutableArray alloc]init];
    }
    return _stickyLayoutArray;
}
- (NSMutableArray *)dragableLayoutArray
{
    if (nil == _dragableLayoutArray) {
        _dragableLayoutArray = [[NSMutableArray alloc]init];
    }
    return _dragableLayoutArray;
}

#pragma mark - DataSource 3个方法
// - (NSUInteger)numberOfItemsInScrollView:(TMLazyScrollView *)scrollView

// - (TMLazyItemModel *)scrollView:(TMLazyScrollView *)scrollView itemModelAtIndex:(NSUInteger)index

// - (UIView *)scrollView:(TMLazyScrollView *)scrollView itemByMuiID:(NSString *)muiID

@end
