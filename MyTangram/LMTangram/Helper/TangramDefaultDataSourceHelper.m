//
//  TangramDefaultDataSourceHelper.m
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import "TangramDefaultDataSourceHelper.h"
#import "TangramLayoutFactoryProtocol.h"
#import "TangramItemModelFactoryProtocol.h"
#import "TangramLayoutParseHelper.h"
#import "TMUtils.h"
#import "TangramDefaultItemModel.h"
#import "TangramElementFactoryProtocol.h"
#import "TangramEasyElementProtocol.h"
#import "UIView+TMLazyScrollView.h"

@interface TangramDefaultDataSourceHelper ()

@property (nonatomic, strong) Class<TangramLayoutFactoryProtocol> layoutFactoryClass;
@property (nonatomic, strong) Class<TangramItemModelFactoryProtocol> itemModelFactoryClass;
@property (nonatomic, strong) Class<TangramElementFactoryProtocol> elementFactoryClass;

@end

@implementation TangramDefaultDataSourceHelper

+ (TangramDefaultDataSourceHelper*)sharedInstance
{
    static TangramDefaultDataSourceHelper *_dataSourceHelper = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _dataSourceHelper = [[TangramDefaultDataSourceHelper alloc] init];
    });
    return _dataSourceHelper;
}

- (instancetype)init {
    if (self = [super init]) {
        self.layoutFactoryClass = NSClassFromString(@"TangramDefaultLayoutFactory");
        self.itemModelFactoryClass = NSClassFromString(@"TangramDefaultItemModelFactory");
        self.elementFactoryClass = NSClassFromString(@"TangramDefaultElementFactory");
    }
    return self;
}

+(UIView *)elementByModel:(NSObject<TangramItemModelProtocol> *)model
                   layout:(UIView<TangramLayoutProtocol> *)layout
               tangramBus:(TangramBus *)tangramBus {
    UIView *element = [[TangramDefaultDataSourceHelper sharedInstance].elementFactoryClass elementByModel:model];
    element.reuseIdentifier = model.reuseIdentifier;
    // 创建之后还要做这些操作
    // 执行element实现的TangramEasyElementProtocol代理方法
    // setTangramItemModel:方法
    // setAtLayout:方法
    // setTangramBus:方法
    if ([element conformsToProtocol:@protocol(TangramEasyElementProtocol)]){
        if (model && [element respondsToSelector:@selector(setTangramItemModel:)] && [model isKindOfClass:[TangramDefaultItemModel class]]) {
            [((UIView<TangramEasyElementProtocol> *)element) setTangramItemModel:(TangramDefaultItemModel *)model];
        }
        if (layout && [element respondsToSelector:@selector(setAtLayout:)]) {
            //if its nested itemModel, here should bind tangrambus
            if ([model isKindOfClass:[TangramDefaultItemModel class]]
                && [layout respondsToSelector:@selector(subLayoutDict)]
                && [layout respondsToSelector:@selector(subLayoutIdentifiers)]
                && model.inLayoutIdentifier.length > 0) {
                [((UIView<TangramEasyElementProtocol> *)element) setAtLayout:[layout.subLayoutDict tm_safeObjectForKey:model.inLayoutIdentifier]];
            }
            else{
                [((UIView<TangramEasyElementProtocol> *)element) setAtLayout:layout];
            }
        }
        if (tangramBus && [element respondsToSelector:@selector(setTangramBus:)] ) {
            [((UIView<TangramEasyElementProtocol> *)element) setTangramBus:tangramBus];
        }
    }
    return element;
}

+(UIView *)refreshElement:(UIView *)element byModel:(NSObject<TangramItemModelProtocol> *)model
                   layout:(UIView<TangramLayoutProtocol> *)layout
               tangramBus:(TangramBus *)tangramBus {
    if ([model respondsToSelector:@selector(layoutIdentifierForLayoutModel)] && model.layoutIdentifierForLayoutModel && model.layoutIdentifierForLayoutModel.length > 0) {
        return nil;
    }
    element = [[TangramDefaultDataSourceHelper sharedInstance].elementFactoryClass refreshElement:element byModel:model];
    // 刷新之后还要做这些操作
    // 执行element实现的TangramEasyElementProtocol代理方法
    // setTangramItemModel:方法
    // setAtLayout:方法
    // setTangramBus:方法
    if ([element conformsToProtocol:@protocol(TangramEasyElementProtocol)]){
        if (model && [element respondsToSelector:@selector(setTangramItemModel:)] && [model isKindOfClass:[TangramDefaultItemModel class]]) {
            [((UIView<TangramEasyElementProtocol> *)element) setTangramItemModel:(TangramDefaultItemModel *)model];
        }
        if (layout && [element respondsToSelector:@selector(setAtLayout:)]) {
            //if its nested itemModel, here should bind tangrambus
            if ([model isKindOfClass:[TangramDefaultItemModel class]]
                && [layout respondsToSelector:@selector(subLayoutDict)]
                && [layout respondsToSelector:@selector(subLayoutIdentifiers)]
                && model.inLayoutIdentifier.length > 0) {
                [((UIView<TangramEasyElementProtocol> *)element) setAtLayout:[layout.subLayoutDict tm_safeObjectForKey:model.inLayoutIdentifier]];
            }
            else{
                [((UIView<TangramEasyElementProtocol> *)element) setAtLayout:layout];
            }
        }
        if (tangramBus && [element respondsToSelector:@selector(setTangramBus:)] ) {
            [((UIView<TangramEasyElementProtocol> *)element) setTangramBus:tangramBus];
        }
    }
    return element;
}

+(NSArray<UIView<TangramLayoutProtocol> *> *)layoutsWithArray: (NSArray<NSDictionary *> *)dictArray
                                                   tangramBus: (TangramBus *)tangramBus
{
    NSMutableArray *layouts = [[NSMutableArray alloc]init];
    // 使用TangramDefaultLayoutFactory进行初步处理。
    if ([(Class)([TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass) instanceMethodForSelector:@selector(preprocessedDataArrayFromOriginalArray:)]) {
        // 预处理JSON数据，如何某个layout的type不在预设的type中，那么当做一个container-oneColumn，添加进layoutArray中
        dictArray = [[TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass preprocessedDataArrayFromOriginalArray:dictArray];
    }
    for (NSDictionary *dict in dictArray) {
        // 通过JSON中card中描述的type，创建了与type对应的layoutClass的实例layout，然后将JSON的字段赋值
        // 给layout的属性中。
        UIView<TangramLayoutProtocol> *layout = [[TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass layoutByDict:dict];
        // 将itemModel赋值给layout中
        [self fillLayoutProperty:layout withDict:dict tangramBus:tangramBus];
        if (0 == layout.itemModels.count) {
            continue;
        }
        [layouts tm_safeAddObject:layout];
        for (int i = 0 ; i< layout.itemModels.count; i++) {
            TangramDefaultItemModel *itemModel = [layout.itemModels tm_safeObjectAtIndex:i];
            if ([itemModel isKindOfClass:[TangramDefaultItemModel class]]) {
                itemModel.index = i;
            }
        }
    }
    return [layouts copy];
}

#pragma mark - Private

+ (UIView<TangramLayoutProtocol> *)fillLayoutProperty :(UIView<TangramLayoutProtocol> *)layout withDict:(NSDictionary *)dict tangramBus:(TangramBus *)tangramBus
{
    // 将cards下的每一个元素
    layout.itemModels = [self modelsWithLayoutDictionary:dict];
    //layout在自己内部做处理其他数据
    layout = [TangramLayoutParseHelper layoutConfigByOriginLayout:layout withDict:dict];
    //解析HeaderModel & FooterModel
    // 解析card中的一级字段"header"作为itemModel，设置给自己的属性headerItemModel中。
    if ([dict tm_dictionaryForKey:@"header"] != nil && [layout respondsToSelector:@selector(setHeaderItemModel:)]) {
        // car
        TangramDefaultItemModel *headerModel = [TangramDefaultDataSourceHelper modelWithDictionary:[dict tm_dictionaryForKey:@"header"]];
        headerModel.display = @"block";
        layout.headerItemModel = headerModel;
    }
    // 解析card中的一级字段"footer"作为itemModel，设置给自己的属性footerItemModel中。
    if ([dict tm_dictionaryForKey:@"footer"] != nil && [layout respondsToSelector:@selector(setHeaderItemModel:)]) {
        TangramDefaultItemModel *footerModel = [TangramDefaultDataSourceHelper modelWithDictionary:[dict tm_dictionaryForKey:@"footer"]];
        footerModel.display = @"block";
        layout.footerItemModel = footerModel;
    }
    //Check whether its nested layout
    NSMutableDictionary *mutableInnerLayoutDict = [[NSMutableDictionary alloc]init];
    NSMutableArray *mutableInnerLayoutIdentifierArray = [[NSMutableArray alloc]init];
    NSMutableArray *itemModelToBeAdded = [[NSMutableArray alloc]init];
    NSMutableArray *itemModelToBeRemoved = [[NSMutableArray alloc]init];
    for (NSUInteger i = 0 ; i < layout.itemModels.count ; i++) {
        NSObject<TangramItemModelProtocol> *model = [layout.itemModels tm_safeObjectAtIndex:i];
        //Analyze whether its nested layout.
        // 这个先放一放
        if ([model respondsToSelector:@selector(layoutIdentifierForLayoutModel)] &&  model.layoutIdentifierForLayoutModel && model.layoutIdentifierForLayoutModel.length > 0) {
            NSDictionary *modelDict = [[dict tm_arrayForKey:@"items"] tm_dictionaryAtIndex:i];
            if ( 0 >= [modelDict tm_arrayForKey:@"items"].count) {
                [itemModelToBeRemoved tm_safeAddObject:model];
                continue;
            }
            //Generate layout
            UIView<TangramLayoutProtocol> *innerLayout = [self layoutWithDictionary:modelDict  tangramBus:tangramBus];
            if (innerLayout && innerLayout.identifier.length > 0) {
                [mutableInnerLayoutDict setObject:innerLayout forKey:innerLayout.identifier];
                [mutableInnerLayoutIdentifierArray tm_safeAddObject:innerLayout.identifier];
            }
            
            NSArray *innerLayoutItemModels = innerLayout.itemModels;
            for (NSObject<TangramItemModelProtocol> *innerModel in innerLayoutItemModels) {
                if ([innerModel conformsToProtocol:@protocol(TangramItemModelProtocol)]){
                    if([innerModel respondsToSelector:@selector(setInnerItemModel:)]) {
                        innerModel.innerItemModel = YES;
                    }
                    if ([innerModel respondsToSelector:@selector(setInLayoutIdentifier:)]) {
                        innerModel.inLayoutIdentifier = innerLayout.identifier;
                    }
                }
            }
            if (innerLayoutItemModels && [innerLayoutItemModels isKindOfClass:[NSArray class]] && innerLayoutItemModels.count > 0) {
                [itemModelToBeAdded addObjectsFromArray:innerLayoutItemModels];
            }
        }
    }
    NSMutableArray *originMutableItemModels = [layout.itemModels mutableCopy];
    for (NSObject<TangramItemModelProtocol> *model in itemModelToBeRemoved) {
        [originMutableItemModels removeObject:model];
    }
    [originMutableItemModels addObjectsFromArray:itemModelToBeAdded];
    layout.itemModels = [originMutableItemModels copy];
    if ([layout respondsToSelector:@selector(setSubLayoutDict:)] && mutableInnerLayoutDict.count > 0) {
        layout.subLayoutDict = [mutableInnerLayoutDict copy];
        layout.subLayoutIdentifiers = [mutableInnerLayoutIdentifierArray copy];
    }
    //bind tangrambus
    if (tangramBus && [tangramBus isKindOfClass:[TangramBus class]] && [layout respondsToSelector:@selector(setTangramBus:)] ) {
        [layout setTangramBus:tangramBus];
    }
    return layout;
}

+(UIView<TangramLayoutProtocol> *)layoutWithDictionary: (NSDictionary *)dict tangramBus:(TangramBus *)tangramBus
{
    NSString *type = [dict tm_stringForKey:@"type"];
    if (type.length <= 0) {
        return nil;
    }
    UIView<TangramLayoutProtocol> *layout = nil;
    layout = [[TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass layoutByDict:dict];
    return [self fillLayoutProperty:layout withDict:dict tangramBus:tangramBus];
}

+ (NSArray *)parseArrayWithRP:(NSArray *)originArray
{
    if (originArray.count > 3) {
        return @[
                 @([TangramDefaultDataSourceHelper floatValueByRPObject:[originArray objectAtIndex:0]]),
                 @([TangramDefaultDataSourceHelper floatValueByRPObject:[originArray objectAtIndex:1]]),
                 @([TangramDefaultDataSourceHelper floatValueByRPObject:[originArray objectAtIndex:2]]),
                 @([TangramDefaultDataSourceHelper floatValueByRPObject:[originArray objectAtIndex:3]]),
                 ];
    }
    return @[@0,@0,@0,@0];
}

+ (float)floatValueByRPObject:(id)rpObject
{
    float margin = 0.f;
    //如果是字符串并且包含rp
    if ([rpObject isKindOfClass:[NSString class]]) {
        if ([rpObject containsString:@"rp"]) {
            margin = [rpObject floatValue]*[UIScreen mainScreen].bounds.size.width / 750.f;
        }
        else{
            margin = [rpObject floatValue];
        }
    }
    else if ([rpObject isKindOfClass:[NSNumber class]]){
        margin = [rpObject floatValue];
    }
    return margin;
}

// 将card的一级菜单中的"items"标签中的数组提取出来并返回。
// items数组中的每个元素转化为遵守"TangramItemModelProtocol"协议的model。
//"items": [
//          {
//              "type": "text",
//              "text": "VirtualView Element , use rp as margin",
//              "style":{
//                  "margin":["5rp","5","5","5"]
//              }
//          },
//          {
//              "type": "text",
//              "text": "rp is a unit that considers all screen widths to be 750 ",
//              "style":{
//                  "margin":["5rp","5","5","5"]
//              }
//          },
//          {
//              "type": "TmallComponent2",
//              "imgUrl": "https://gw.alicdn.com/tps/TB1Nin9JFXXXXbXaXXXXXXXXXXX-224-224.png",
//              "title": "VirtualView",
//              "style":{
//                  "ratio":"5"
//              }
//          }
//]
+(NSMutableArray *)modelsWithLayoutDictionary : (NSDictionary *)dict
{
    if (dict.count == 0) {
        return  [[NSMutableArray alloc]init];
    }
    NSMutableArray *itemModels = [[NSMutableArray alloc]init];
    NSArray *itemModelArray = [dict tm_arrayForKey:@"items"];
    for (NSUInteger i = 0 ; i < itemModelArray.count ; i++) {
        NSDictionary *dict = [itemModelArray tm_dictionaryAtIndex:i];
        // 将item字典转化为ItemModel
        NSObject<TangramItemModelProtocol> *model =  [self modelWithDictionary:dict];
        if (model) {
            [itemModels tm_safeAddObject:model];
        }
        if ([model isKindOfClass:[TangramDefaultItemModel class]]) {
            ((TangramDefaultItemModel *)model).index = i;
        }
    }
    return itemModels;
}

// 将card的items中的每个item转化为NSObject<TangramItemModelProtocol> *
+(NSObject<TangramItemModelProtocol> *)modelWithDictionary : (NSDictionary *)dict
{
    NSString *type = [dict tm_stringForKey:@"type"];
    if (type.length <= 0) {
        return nil;
    }
    NSObject<TangramItemModelProtocol> *itemModel = nil;
    // 使用遵守TangramItemModelFactoryProtocol这个协议的类，即TangramDefaultItemModelFactory
    // 来创建一个itemModel实例对象，并将字典中的内容赋值到itemModel实例对象中。
    itemModel = [[TangramDefaultDataSourceHelper sharedInstance].itemModelFactoryClass itemModelByDict:dict];

    if ([[dict tm_stringForKey:@"kind"] isEqualToString:@"row"] ||
        [[TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass layoutClassNameByType:type] != nil) {
        //[[TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass layoutClassNameByType:type] != nil
        
        // 如果items数组中的元素中的type在DefaultLayoutFactory中的layoutTypeMap中找到，
        // itemModel.linkElementName指的是layoutTypeMap[item.type]，是个layoutClass
        if ([(Class)([TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass) instanceMethodForSelector:@selector(layoutClassNameByType:)]) {
            itemModel.linkElementName = [[TangramDefaultDataSourceHelper sharedInstance].layoutFactoryClass layoutClassNameByType:itemModel.itemType];
        }
    }
    return itemModel;
}

@end
