//
//  TangramLayoutFactoryProtocol.h
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TangramLayoutProtocol.h"

@protocol TangramLayoutFactoryProtocol <NSObject>

@required
/**
 Generate a layout by a dictionary
 
 @return layout
 */
+ (UIView<TangramLayoutProtocol> *)layoutByDict:(NSDictionary *)dict;



@optional

/**
 Return class name by type to ItemModelFactory
 in order to support nesting of layout
 
 @return layout class
 */
+ (NSString *)layoutClassNameByType:(NSString *)type;
/**
 Regist Layout Type and its className
 
 @param type is TangramLayoutType In TangramLayoutProtocol
 */
+ (void)registLayoutType:(NSString *)type className:(NSString *)layoutClassName;

/**
 Preprocess DataArray from original Array
 if implement this method in the layout factory, helper will call this methid in `layoutsWithArray`
 
 @return preprocess in originalarray
 */

// 从JSON数据中读取内容，转化成了什么？？？
+ (NSArray *)preprocessedDataArrayFromOriginalArray:(NSArray *)originalArray;

@end
