//
//  LMTangramDefaultDataSourceHelper.h
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMTangramLayoutProtocol.h"


/**
 是一个干杂货的类，主要干的活包括3个部分:
 1> 将JSON中的cards数组中的每个元素转换为layout实例
 2> 将JSON中的cards数组中的每个元素的items数组中的元素转换为model
 */
@interface LMTangramDefaultDataSourceHelper : NSObject


/**
 从JSON数据中生成layout的数组。

 @param dictArray <#dictArray description#>
 @param tangramBus <#tangramBus description#>
 @return <#return value description#>
 */
+(NSArray<UIView<LMTangramLayoutProtocol> *> *)layoutsWithArray: (NSArray<NSDictionary *> *)dictArray
                                                   tangramBus: (TangramBus *)tangramBus;

@end
