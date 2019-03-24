//
//  LMTangramDefaultItemModelFactory.h
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMTangramItemModelFactoryProtocol.h"
#import "TangramDefaultItemModel.h"

@interface LMTangramDefaultItemModelFactory : NSObject <LMTangramItemModelFactoryProtocol>

+ (TangramDefaultItemModel *)praseDictToItemModel:(TangramDefaultItemModel *)itemModel dict:(NSDictionary *)dict;

@end
