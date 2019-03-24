//
//  LMTangramDefaultLayoutFactory.m
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import "LMTangramDefaultLayoutFactory.h"
#import "TMUtils.h"
#import "TangramScrollFlowLayout.h"
#import "TangramLayoutParseHelper.h"

@interface LMTangramDefaultLayoutFactory ()

@property (nonatomic, strong) NSMutableDictionary *layoutTypeMap;

@end

@implementation LMTangramDefaultLayoutFactory

+ (LMTangramDefaultLayoutFactory*)sharedInstance
{
    static LMTangramDefaultLayoutFactory *_layoutFactory = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _layoutFactory = [[LMTangramDefaultLayoutFactory alloc] init];
        
    });
    return _layoutFactory;
}

- (instancetype)init
{
    if (self = [super init]) {
        _layoutTypeMap = [[NSMutableDictionary alloc]init];
        NSString *layoutMapPath = [[NSBundle mainBundle] pathForResource:@"TangramLayoutTypeMap" ofType:@"plist"];
        [_layoutTypeMap addEntriesFromDictionary:[LMTangramDefaultLayoutFactory decodeTypeMap:[NSArray arrayWithContentsOfFile:layoutMapPath]]];
    }
    return self;
}

+ (NSMutableDictionary *)decodeTypeMap:(NSArray *)mapArray
{
    NSMutableDictionary *mapDict = [[NSMutableDictionary alloc]init];
    for (NSDictionary *dict in mapArray) {
        NSString *key = [dict tm_safeObjectForKey:@"type" class:[NSString class]];
        NSString *value = [dict tm_safeObjectForKey:@"class" class:[NSString class]];
        if (key.length > 0 && value.length > 0) {
            //NSAssert(![[mapDict allKeys] containsObject:key], @"model有重复注册!请检查注册的type!");
            [mapDict setObject:value forKey:key];
        }
    }
    return mapDict;
}



// originalArray是原始JSON数据，比如cards
+ (NSArray *)preprocessedDataArrayFromOriginalArray:(NSArray *)originalArray
{
    NSMutableArray *layouts = [[NSMutableArray alloc]init];
    for (NSUInteger i = 0 ; i < originalArray.count ; i ++) {
        NSDictionary *dict = [originalArray tm_dictionaryAtIndex:i];
        // 在每一个card中，"type"是一级标签。
        NSString *type = [dict tm_stringForKey:@"type"];
        if (type.length <= 0) {
            break;
        }
        // 主要是提取一个type字段，其他一级字段主要是为了@"11"和@"24"这两种type。
        //------------------------------------------//
        
        // 在每一个card中，"style"是一级标签。
        // "style":{
        //    "padding":["5rp","5","5","5"]
        // },
        NSDictionary *style = [dict tm_dictionaryForKey:@"style"];
        // style下可以有"forLabel"标签
        NSString *forLabel = [style tm_stringForKey:@"forLabel"];
        if (forLabel.length > 0 && i < originalArray.count - 1)
        {
            NSDictionary *nestLayoutDict = [originalArray tm_safeObjectAtIndex:i + 1];
            if (![forLabel isEqualToString:[nestLayoutDict tm_stringForKey:@"id"]] || [nestLayoutDict tm_arrayForKey:@"items"].count <= 0)
            {
                continue;
            }
        }
        // 在每一个card中，"items"是一级标签。
        NSArray *originalItems = [dict tm_arrayForKey:@"items"];
        //24 TabsLayout，做数据拆分
        if ([type isEqualToString:@"24"]) {
            //解析出来顶部的header
            NSString *originalIdentifier = [dict tm_stringForKey:@"id"];
            NSString *layoutClassType = @"20";
            NSString *headerIdentifier = [NSString stringWithFormat:@"%@-tabheader",originalIdentifier];
            NSMutableDictionary *tabHeaderDictionary = [[NSMutableDictionary alloc]init];
            [tabHeaderDictionary setObject:headerIdentifier forKey:@"id"];
            if (style) {
                [tabHeaderDictionary setObject:[style copy] forKey:@"style"];
            }
            [tabHeaderDictionary setObject:layoutClassType forKey:@"type"];
            [tabHeaderDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"canHorizontalScroll"];
            [tabHeaderDictionary setObject:[[originalItems tm_dictionaryAtIndex:0] copy] forKey:@"items"];
            [layouts tm_safeAddObject:tabHeaderDictionary];
            //解析其他内容，删掉第一个组件
            NSMutableDictionary *layoutMutableDict = [dict mutableCopy];
            NSMutableArray *contentItems = [originalItems mutableCopy];
            if (contentItems.count > 1) {
                [contentItems removeObjectAtIndex:0];
                [layoutMutableDict setObject:contentItems forKey:@"items"];
            }
            [layouts tm_safeAddObject:[layoutMutableDict copy]];
        }
        //11 MixLayout, 做数据拆分
        else if ([type isEqualToString:@"11"]) {
            NSMutableArray *mutableOriginalItems = [originalItems mutableCopy];
            NSString *identifier = [dict tm_stringForKey:@"id"];
            //获得了N个Layout实例
            NSArray *mixLayoutoriginalArray = [[dict tm_dictionaryForKey:@"style"] tm_arrayForKey:@"mixedLayouts"];
            NSUInteger originalArrayCount = 1;
            if (![type isEqualToString:@"24"]) {
                originalArrayCount = mixLayoutoriginalArray.count;
            }
            
            for (NSUInteger i = 0 ; i< originalArrayCount ; i++) {
                NSDictionary *mixLayoutDict = [mixLayoutoriginalArray tm_dictionaryAtIndex:i];
                NSMutableDictionary *mutableDict = [mixLayoutDict mutableCopy];
                [mutableDict setObject:[NSString stringWithFormat:@"%@-%ld",identifier,(long)(i+1)] forKey:@"id"];
                NSUInteger count = [dict tm_integerForKey:@"count"];
                if (mutableOriginalItems.count > 0 ) {
                    if (mutableOriginalItems.count < count) {
                        count = mutableOriginalItems.count;
                    }
                    NSArray *itemModels = [mutableOriginalItems objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
                    [mutableDict setObject:[itemModels copy] forKey:@"items"];
                    [mutableOriginalItems removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
                }
                [layouts tm_safeAddObject:mutableDict];
            }
        }
        //如果找不到了对应的layout，那么外面套一个onecolumn 当做组件处理
        else if (![[self class]layoutClassNameByType:type]){
            NSMutableDictionary *singleColumnDict = [[NSMutableDictionary alloc]init];
            [singleColumnDict tm_safeSetObject:@"container-oneColumn" forKey:@"type"];
            [singleColumnDict tm_safeSetObject:[dict tm_stringForKey:@"id"] forKey:@"id"];
            [singleColumnDict tm_safeSetObject:@[dict] forKey:@"items"];
            [layouts tm_safeAddObject:[singleColumnDict copy]];
        }
        else{
            [layouts tm_safeAddObject:dict];
        }
    }
    return [layouts copy];
}

+ (NSString *)layoutClassNameByType:(NSString *)type
{
    return [[LMTangramDefaultLayoutFactory sharedInstance].layoutTypeMap tm_stringForKey:type];
}

/**
 Generate a layout by a dictionary
 
 @param dict dict
 @return layout
 */
// 处理preprocessedDataArrayFromOriginalArray函数的返回结果数组中的每一个字典
+ (UIView<LMTangramLayoutProtocol> *)layoutByDict:(NSDictionary *)dict
{
    NSString *type = [dict tm_safeObjectForKey:@"type" class:[NSString class]];
    if (type.length <= 0) {
        return nil;
    }
    
//    1 = TangramSingleColumnLayout;
//    10 = TangramPageScrollLayout;
//    2 = TangramDoubleColumnLayout;
//    20 = TangramStickyLayout;
//    21 = TangramStickyLayout;
//    23 = TangramFixTopLayout;
//    25 = TangramScrollWaterFlowLayout;
//    27 = TangramScrollFlowLayout;
//    28 = TangramFixLayout;
//    29 = TangramPageScrollLayout;
//    3 = TangramTribleColumnLayout;
//    30 = TangramFixLayout;
//    4 = TangramTetradColumnLayout;
//    5 = TangramSingleAndDoubleLayout;
//    7 = TangramDragableLayout;
//    8 = TangramFixBottomLayout;
//    9 = TangramQuintetColumnLayout;
//    "container-fiveColumn" = TangramQuintetColumnLayout;
//    "container-fix" = TangramFixLayout;
//    "container-float" = TangramDragableLayout;
//    "container-flow" = TangramScrollFlowLayout;
//    "container-fourColumn" = TangramTetradColumnLayout;
//    "container-oneColumn" = TangramSingleColumnLayout;
//    "container-onePlusN" = TangramSingleAndDoubleLayout;
//    "container-scroll" = TangramPageScrollLayout;
//    "container-scrollFix" = TangramFixLayout;
//    "container-scrollFixBanner" = TangramFixLayout;
//    "container-sticky" = TangramStickyLayout;
//    "container-threeColumn" = TangramTribleColumnLayout;
//    "container-twoColumn" = TangramDoubleColumnLayout;
//    "container-waterfall" = TangramScrollWaterFlowLayout;
    
    // layoutClassName可以根据type获取到这些layoutClassName
    NSString *layoutClassName = [[LMTangramDefaultLayoutFactory sharedInstance].layoutTypeMap tm_stringForKey:type];
    UIView<LMTangramLayoutProtocol> *layout = nil;
    if ([dict tm_boolForKey:@"canHorizontalScroll"] && ([type integerValue] <= 4 || [type integerValue] == 9)) {
        layout = [[TangramScrollFlowLayout alloc] init];
        ((TangramScrollFlowLayout *)layout).numberOfColumns = (NSUInteger)[type integerValue];
    }
    else {
        layout = (UIView<LMTangramLayoutProtocol> *)[[NSClassFromString(layoutClassName) alloc]init];
    }
    if (!layout) {
        NSLog(@"[TangramDefaultLayoutFactory] layoutByDict : cannot find layout by type , type :%@",type);
        return nil;
    }
    return [LMTangramDefaultLayoutFactory fillLayoutProperty:layout withDict:dict];
}

/**
 Fill Layout Property
 
 @param layout layout
 @param dict dict
 @return layout filled property
 */
// 将JSON中的数据填充到layout实例中。
+ (UIView<LMTangramLayoutProtocol> *)fillLayoutProperty:(UIView<LMTangramLayoutProtocol> *)layout withDict:(NSDictionary *)dict
{
    layout.identifier = [dict tm_stringForKey:@"id"];
    NSDictionary *styleDict = [dict tm_dictionaryForKey:@"style"];
    NSString *backgroundColor = [styleDict tm_stringForKey:@"bgColor"];
    if (backgroundColor.length <= 0 ) {
        backgroundColor = [styleDict tm_stringForKey:@"background-color"];
    }
    if (backgroundColor.length > 0) {
        layout.backgroundColor = [UIColor vv_colorWithString:backgroundColor];
    }
    NSString *bgImgURL = [styleDict tm_stringForKey:@"bgImgUrl"];
    if (bgImgURL.length <= 0) {
        bgImgURL = [styleDict tm_stringForKey:@"background-image"];
    }
    if (bgImgURL.length > 0 && [layout respondsToSelector:@selector(setBgImgURL:)]) {
        layout.bgImgURL = bgImgURL;
    }
    return [TangramLayoutParseHelper layoutConfigByOriginLayout:layout withDict:dict];
}

@end
