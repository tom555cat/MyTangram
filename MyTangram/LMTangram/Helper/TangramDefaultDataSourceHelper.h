//
//  TangramDefaultDataSourceHelper.h
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TangramLayoutProtocol.h"


/**
 是一个干杂货的类，主要干的活包括3个部分:
 1> 将JSON中的cards数组中的每个元素转换为layout实例
 2> 将JSON中的cards数组中的每个元素的items数组中的元素转换为model
 */
@interface TangramDefaultDataSourceHelper : NSObject


/**
 从JSON数据中生成layout的数组。

 */
+(NSArray<UIView<TangramLayoutProtocol> *> *)layoutsWithArray: (NSArray<NSDictionary *> *)dictArray
                                                   tangramBus: (TangramBus *)tangramBus;
// 找到一个与itemModel对应的可复用的element，刷新其中的数据。
+(UIView *)refreshElement:(UIView *)element byModel:(NSObject<TangramItemModelProtocol> *)model
                   layout:(UIView<TangramLayoutProtocol> *)layout
               tangramBus:(TangramBus *)tangramBus;

// 创建一个element，用itemModel的数据填充它。
+(UIView *)elementByModel:(NSObject<TangramItemModelProtocol> *)model
                   layout:(UIView<TangramLayoutProtocol> *)layout
               tangramBus:(TangramBus *)tangramBus;

+ (NSArray *)parseArrayWithRP:(NSArray *)originArray;

+ (float)floatValueByRPObject:(id)rpObject;

@end
