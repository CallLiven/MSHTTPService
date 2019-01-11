//
//  MSHTTPService.h
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "AFHTTPSessionManager+RACSupport.h"
#import "RACSubscriber+AFProgressCallbacks.h"
#import "MSHTTPRequest.h"
#import "MSHTTPResponse.h"
#import "MSHTTPAPIConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSHTTPService : AFHTTPSessionManager

+ (instancetype)shareInstance;


/**
 发起请求

 @param request 请求类
 @param resultClass 返回数据模型类
 @return signal
 */
- (RACSignal *)enqueueRequest:(MSHTTPRequest *__nullable)request
                  resultClass:(Class __nullable)resultClass;

@end

NS_ASSUME_NONNULL_END
