//
//  ViewController.m
//  MyTangram
//
//  Created by tom555cat on 2019/3/23.
//  Copyright © 2019年 Hello World Corporation. All rights reserved.
//

#import "ViewController.h"
#import "LMTangramDefaultItemModelFactory.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *layoutModelArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 首先要解析数据
    
}

- (void)loadMockContent {
    NSString *mockDataString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TangramMock" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [mockDataString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingAllowFragments error:nil];
    
    // 提取出JSON数据中的cards数组
    self.layoutModelArray = [[dict objectForKey:@"data"] objectForKey:@"cards"];
    
    // 注册type和elementClass
    [LMTangramDefaultItemModelFactory registElementType:@"image" className:@"TangramSingleImageElement"];
    [LMTangramDefaultItemModelFactory registElementType:@"text" className:@"TangramSimpleTextElement"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
