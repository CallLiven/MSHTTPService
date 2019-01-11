//
//  MSURLParameters.h
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//  网络服务层 --参数

#import <Foundation/Foundation.h>
#import "MSHTTPServiceConstant.h"
#import "MSKeyedSubscript.h"

// 请求 METHOD
/** GET 请求 */
#define MS_RequestMethod_GET @"GET"
/** POST 请求 */
#define MS_RequestMethod_POST @"POST"
/** HEAD 请求 */
#define MS_RequestMethod_HEAD @"HEAD"
/** PUT 请求 */
#define MS_RequestMethod_PUT @"PUT"
/** PATCH 请求 */
#define MS_RequestMethod_PATCH @"PATCH"
/** DELETE 请求 */
#define MS_RequestMethod_DELETE @"DELETE"


NS_ASSUME_NONNULL_BEGIN

@class MSURLExtendsParameters;

@interface MSURLParameters : NSObject
/** 路径 */
@property (nonatomic, copy  , readwrite) NSString *path;
/** 参数 */
@property (nonatomic, strong, readwrite) NSDictionary *paramters;
/** 方法 */
@property (nonatomic, copy  , readwrite) NSString *method;
/** 基本参数 */
@property (nonatomic, strong, readwrite) MSURLExtendsParameters *extendsParameters;

/**
 请求参数配置

 @param method 方法名
 @param path url路径
 @param parameters 参数
 @return 参数实例
 */
+ (instancetype)urlParametersWithMethod:(NSString *__nullable)method
                                   path:(NSString *__nullable)path
                             parameters:(NSDictionary *__nullable)parameters;

@end



// 基本请求参数 
@interface MSURLExtendsParameters : NSObject

/** 用户token，默认空字符串 */
@property (nonatomic, copy, readonly) NSString  *token;
/** 设备编号，自行生成 */
@property (nonatomic, copy, readonly) NSString  *deviceid;
/** app版本号 */
@property (nonatomic, copy, readonly) NSString  *ver;
/** 平台iOS或android */
@property (nonatomic, copy, readonly) NSString  *platform;
/** 渠道 */
@property (nonatomic, copy, readonly) NSString  *channel;
/** 时间戳 */
@property (nonatomic, copy, readonly) NSString  *t;


+ (instancetype)entextsParameters;

@end

NS_ASSUME_NONNULL_END
