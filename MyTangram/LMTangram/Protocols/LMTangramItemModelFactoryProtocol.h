//
//  LMTangramItemModelFactoryProtocol.h
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMTangramItemModelProtocol.h"

@protocol LMTangramItemModelFactoryProtocol <NSObject>

/*
@param type In ItemModel we need return a itemType, the itemType will be used here
*/

// type和element的class关联起来。
+ (void)registElementType:(NSString *)type className:(NSString *)elementClassName;

/**
 Generate itemModel by a dictionary
 
 @return itemModel
 */
// 将JSON中的cards中的每个layout下边的items中的每个元素item转化为ItemModel。
//"items": [
//          {
//              "type": "text",
//              "text": "VirtualView Element , use rp as margin",
//              "style":{
//                  "margin":["5rp","5","5","5"]
//              }
//          },
//]
+ (NSObject<LMTangramItemModelProtocol> *)itemModelByDict:(NSDictionary *)dict;

@end
