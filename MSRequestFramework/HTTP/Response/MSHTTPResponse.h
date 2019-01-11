//
//  MSHTTPResponse.h
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//  服务器返回数据模型类

#import <Foundation/Foundation.h>

/**
 网络请求返回业务状态码
 (备注：每个公司的定义都不一样，以下为参考实例)
 */
typedef NS_ENUM(NSUInteger,MSHTTPResponseCode) {
    MSHTTPResponseCodeSuccess = 0,                // 请求成功
    MSHTTPResponseCodeNotLogin = 666,               // 用户尚未登录
    MSHTTPResponseCodeParameterVerifyFailure = 105, // 参数验证失败
};

NS_ASSUME_NONNULL_BEGIN

@interface MSHTTPResponse : NSObject

/** 服务器返回的数据，并解析过. 对应json数据的 data */
@property (nonatomic, strong, readonly) id parsedResult;
/** 服务器返回的请求业务状态码. 对应json数据的 code */
@property (nonatomic, assign, readonly) MSHTTPResponseCode  code;
/** 服务器返回的描述信息. 对应json数据的 msg */
@property (nonatomic, copy  , readonly) NSString *msg;


/**
 初始化

 @param responseObject 服务器返回的json
 @param parseResult 服务器返回的json解析过得
 @return MSHTTPResponse
 */
- (instancetype)initWithResponseObject:(id)responseObject parsedResult:(id)parseResult;

@end

NS_ASSUME_NONNULL_END
