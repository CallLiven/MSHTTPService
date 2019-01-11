//
//  ViewController.m
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "ViewController.h"
#import "MSHTTPService.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 使用方法
    NSString *path = @"";
    MSURLParameters *parameters = [MSURLParameters urlParametersWithMethod:@"GET" path:path parameters:nil];
    MSHTTPRequest *request = [MSHTTPRequest requestWithParameters:parameters];
    [[[MSHTTPService shareInstance] enqueueRequest:request resultClass:nil] subscribeNext:^(MSHTTPResponse *result) {
        NSLog(@"请求结果：%@",result);
        NSLog(@"parsedResult======%@",result.parsedResult);
        NSLog(@"code======%lu",(unsigned long)result.code);
        NSLog(@"msg======%@",result.msg);
    } error:^(NSError * _Nullable error) {
        NSLog(@"请求失败：%@",error);
    } completed:^{
        NSLog(@"请求完成");
    }];
    
    
}


@end
