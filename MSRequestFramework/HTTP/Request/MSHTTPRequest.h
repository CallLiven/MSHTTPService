//
//  MSHTTPRequest.h
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//  网络服务层   -- 请求

#import <Foundation/Foundation.h>
#import "MSURLParameters.h"
#import "RACSignal+MSHTTPServiceAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSHTTPRequest : NSObject

/** 请求参数*/
@property (nonatomic, strong, readonly) MSURLParameters *urlParameters;

/**
 请求类

 @param parameters 参数模型
 @return 请求类
 */
+ (instancetype)requestWithParameters:(MSURLParameters *)parameters;

@end


// MSHTTPService的分类
@interface MSHTTPRequest (MSHTTPService)

@end




NS_ASSUME_NONNULL_END
