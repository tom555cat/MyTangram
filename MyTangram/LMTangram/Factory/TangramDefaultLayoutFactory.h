//
//  TangramDefaultLayoutFactory.h
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TangramLayoutFactoryProtocol.h"

@interface TangramDefaultLayoutFactory : NSObject <TangramLayoutFactoryProtocol>

/**
 Return class name by type to ItemModelFactory
 in order to support nesting of layout
 
 @return layout class
 */
+ (NSString *)layoutClassNameByType:(NSString *)type;

@end
