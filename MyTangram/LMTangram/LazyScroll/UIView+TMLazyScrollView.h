//
//  UIView+TMLazyScrollView.h
//  MyTangram
//
//  Created by tongleiming on 2019/3/25.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (TMLazyScrollView)

@property (nonatomic, copy) NSString *muiID;
@property (nonatomic, copy) NSString *reuseIdentifier;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

@end

NS_ASSUME_NONNULL_END
