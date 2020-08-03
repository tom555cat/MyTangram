//
//  ViewController.m
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import "ViewController.h"
#import "TangramDefaultItemModelFactory.h"
#import "TangramDefaultDataSourceHelper.h"
#import "TangramBus.h"
#import "TangramView.h"
#import "TangramLayoutProtocol.h"

@interface ViewController () <TangramViewDatasource>

@property (nonatomic, strong) NSMutableArray *layoutModelArray;

@property (nonatomic, strong) NSArray *layoutArray;

@property  (nonatomic, strong) TangramBus *tangramBus;

@property (nonatomic, strong) TangramView *tangramView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 首先要解析数据
    [self loadMockContent];
    [self registEvent];
    [self.tangramView reloadData];
}

- (void)loadMockContent {
    NSString *mockDataString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TangramMock" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [mockDataString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingAllowFragments error:nil];
    
    // 提取出JSON数据中的cards数组
    self.layoutModelArray = [[dict objectForKey:@"data"] objectForKey:@"cards"];
    
    // 注册type和elementClass
    [TangramDefaultItemModelFactory registElementType:@"image" className:@"TangramSingleImageElement"];
    [TangramDefaultItemModelFactory registElementType:@"text" className:@"TangramSimpleTextElement"];
    
    self.layoutArray = [TangramDefaultDataSourceHelper layoutsWithArray:self.layoutModelArray tangramBus:self.tangramBus];
}

- (void)registEvent {
    [self.tangramBus registerAction:@"responseToClickEvent:" ofExecuter:self onEventTopic:@"jumpAction"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - getter & setter

- (TangramBus *)tangramBus
{
    if (nil == _tangramBus) {
        _tangramBus = [[TangramBus alloc]init];
    }
    return _tangramBus;
}

-(TangramView *)tangramView
{
    if (nil == _tangramView) {
        _tangramView = [[TangramView alloc]init];
        _tangramView.frame = self.view.bounds;
        [_tangramView setDataSource:self];
        _tangramView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_tangramView];
    }
    return _tangramView;
}

#pragma mark - TangramViewDatasource

- (NSUInteger)numberOfLayoutsInTangramView:(TangramView *)view {
    return self.layoutArray.count;
}

- (UIView<TangramLayoutProtocol> *)layoutInTangramView:(TangramView *)view atIndex:(NSUInteger)index {
    return [self.layoutArray objectAtIndex:index];
}

- (NSUInteger)numberOfItemsInTangramView:(TangramView *)view forLayout:(UIView<TangramLayoutProtocol> *)layout {
    return layout.itemModels.count;
}

- (NSObject<TangramItemModelProtocol> *)itemModelInTangramView:(TangramView *)view forLayout:(UIView<TangramLayoutProtocol> *)layout atIndex:(NSUInteger)index {
    return [layout.itemModels objectAtIndex:index];
}

- (UIView *)itemInTangramView:(TangramView *)view withModel:(NSObject<TangramItemModelProtocol> *)model forLayout:(UIView<TangramLayoutProtocol> *)layout atIndex:(NSUInteger)index {
    UIView *reuseableView = [view dequeueReusableItemWithIdentifier:model.reuseIdentifier];
    if (reuseableView) {
        // 找到了一个可以重用的view，刷新其中的数据
        reuseableView = [TangramDefaultDataSourceHelper refreshElement:reuseableView byModel:model layout:layout tangramBus:self.tangramBus];
    } else {
        reuseableView = [TangramDefaultDataSourceHelper elementByModel:model layout:layout tangramBus:self.tangramBus];
    }
    return reuseableView;
}

@end
