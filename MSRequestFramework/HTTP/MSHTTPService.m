//
//  MSHTTPService.m
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "MSHTTPService.h"
#import <AFNetworkActivityIndicatorManager.h>
#import <MJExtension.h>
#import <YYModel.h>

NSString *const MSHTTPServiceErrorDomain = @"MSHTTPServiceErrorDomain";
NSString *const MSHTTPServiceErrorResponseCodeKey = @"MSHTTPServiceErrorResponseCodeKey";

NSString *const MSHTTPServiceErrorRequesURLKey = @"MSHTTPServiceErrorRequesURLKey";
NSString *const MSHTTPServiceErrorMessagesKey = @"MSHTTPServiceErrorMessagesKey";
NSString *const MSHTTPServiceErrorDescriptionKey = @"MSHTTPServiceErrorDescriptionKey";
NSString *const MSHTTPServiceErrorHTTPStatusCodeKey = @"MSHTTPServiceErrorHTTPStatusCodeKey";

// 连接服务器失败 dafault
NSInteger const MSHTTPServiceErrorConnectionFailed = 668;
NSInteger const MSHTTPServiceErrorJSONParsingFailed = 669;

NSInteger const MSHTTPServiceErrorBadRequest = 670;
NSInteger const MSHTTPServiceErrorRequestForbidden = 671;

// 服务器请求失败
NSInteger const MSHTTPServiceErrorServiceRequestFailed = 672;
NSInteger const MSHTTPServiceErrorSecureConnectionFailed = 673;

@implementation MSHTTPService

#pragma mark - 单例初始化
static id _service = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _service = [[self alloc]initWithBaseURL:[NSURL URLWithString:@""] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    });
    return _service;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _service = [super allocWithZone:zone];
    });
    return _service;
}

- (id)copyWithZone:(NSZone *)zone {
    return _service;
}


- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(nullable NSURLSessionConfiguration *)configuration {
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self) {
        [self ms_configHTTPSevice];
    }
    return self;
}



#pragma mark - 网络请求 Request
- (RACSignal *)enqueueRequest:(MSHTTPRequest *)request resultClass:(Class)resultClass {
    // request 必须有值
    if (!request) return [RACSignal error:[NSError errorWithDomain:MSHTTPServiceErrorDomain code:-1 userInfo:nil]];
    
    @weakify(self);
    return [[[self enqueueRequestWithPath:request.urlParameters.path
                               parameters:request.urlParameters.paramters
                                   method:request.urlParameters.method] reduceEach:^RACStream *(NSURLResponse *response , NSDictionary *responseObject){
        @strongify(self);
        // 请求成功，这里解析数据
        return [[self parsedResponseOfClass:resultClass fromJSON:responseObject] map:^(id parsedResult) {
            MSHTTPResponse *parsedResponse = [[MSHTTPResponse alloc] initWithResponseObject:responseObject parsedResult:parsedResult];
            return parsedResponse;
        }];
    }] concat];
}


/** 请求数据 */
- (RACSignal *)enqueueRequestWithPath:(NSString *)path parameters:(id)parameters method:(NSString *)method {
    @weakify(self);
    // 创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        // 获取request
        // 请求序列化(如果成功则发起请求，失败则中断)
        NSError *serializationError = nil;
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
        if (serializationError) {
            return [RACDisposable disposableWithBlock:^{
                
            }];
        }
        
        // 获取请求任务
        __block NSURLSessionDataTask *task = nil;
        task = [self dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, NSDictionary *responseObject, NSError * _Nullable error) {
            
            NSError *resultError = nil;
            if (error) {
                NSError *parseError = [self errorFromRequestWithTask:task httpResponse:(NSHTTPURLResponse *)response responseObject:responseObject error:error];
                resultError = parseError;
                [subscriber sendError:parseError];
            }
            else{
                // 这里判断数据是否正确
                NSInteger statusCode = [responseObject[MSHTTPServiceResponseCodeKey] integerValue];
                if (statusCode == MSHTTPResponseCodeSuccess) {
                    // 打包成元祖，回调函数
                    [subscriber sendNext:RACTuplePack(response,responseObject)];
                    [subscriber sendCompleted];
                }
                else{
                    // 用户未登录
                    if (statusCode == MSHTTPResponseCodeNotLogin) {
                        
                    }else{
                    // 参数验证失败
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        userInfo[MSHTTPServiceErrorResponseCodeKey] = @(statusCode);
                        NSString *msgString = responseObject[MSHTTPServiceResponseMsgKey];
                        if (msgString.length == 0 || [msgString isKindOfClass:[NSNull class]] || msgString == nil) {
                            msgString = @"服务器出错了，请稍后重试~";
                        }
                        userInfo[MSHTTPServiceErrorMessagesKey] = msgString;
                        if (task.currentRequest.URL != nil) {
                            userInfo[MSHTTPServiceErrorRequesURLKey] = task.currentRequest.URL.absoluteString;
                        }
                        if (task.error != nil) {
                            userInfo[NSUnderlyingErrorKey] = task.error;
                        }
                        NSError *requestError = [NSError errorWithDomain:MSHTTPServiceErrorDomain code:statusCode userInfo:userInfo];
                        resultError = resultError;
                        [subscriber sendError:requestError];
                    }
                }
            
            }
            
            [self logHTTPRequest:task body:parameters error:resultError];
        }];
        
        // 开启请求任务
        [task resume];
        return  [RACDisposable disposableWithBlock:^{
                    [task cancel];
                }];
        
    }];
    
    // replayLazily 会在第一次订阅的时候才订阅sourceSignal
    return [[signal replayLazily] setNameWithFormat:@"-enqueueRequestWithPath: %@ parameters: %@ method: %@", path, parameters , method];
}


#pragma mark - 解析数据
- (RACSignal *)parsedResponseOfClass:(Class)resultClass fromJSON:(NSDictionary *)responseObject {
    // 这里主要解析 data：对应的数据
    responseObject = responseObject[MSHTTPServiceResponseDataKey];
    
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 解析字典
        void (^parseJSONDictionary)(NSDictionary *) = ^(NSDictionary *JSONDictionary) {
            if (resultClass == nil) {
                [subscriber sendNext:JSONDictionary];
                return;
            }
            // 继续取出数据 data{"list":[]}
            NSArray *JSONArray = JSONDictionary[MSHTTPServiceResponseDataListKey];
            if ([JSONArray isKindOfClass:[NSArray class]]) {
                // 字典数组 转 对应的模型
                NSArray *parsedObjects = [NSArray yy_modelArrayWithClass:resultClass.class json:JSONArray];
                [subscriber sendNext:parsedObjects];
            }
            else{
                // 字典转模型
                NSObject *parsedObject = [resultClass yy_modelWithDictionary:JSONDictionary];
                if (parsedObject == nil) {
                    NSError *error = [NSError errorWithDomain:@"" code:2222 userInfo:@{}];
                    [subscriber sendError:error];
                    return;
                }
                
                [subscriber sendNext:parsedObject];
            }
        };
        
        
        if ([responseObject isKindOfClass:[NSArray class]]) {
            if (resultClass == nil) {
                [subscriber sendNext:responseObject];
            }
            else{
                // 数组 保证数组里面装的是同一种 NSDictionary
                for (NSDictionary *JSONDictionary in responseObject) {
                    if (![JSONDictionary isKindOfClass:[NSDictionary class]]) {
                        NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Invalid JSON array element: %@", @""), JSONDictionary];
                        [subscriber sendError:[self parsingErrorWithFailureReason:failureReason]];
                        return nil;
                    }
                }
                
                // 字典数组 转 对应的模型
                NSArray *parsedObjects = [NSArray yy_modelArrayWithClass:resultClass.class json:responseObject];
                [subscriber sendNext:parsedObjects];
                
            }
            [subscriber sendCompleted];
        }
        else if ([responseObject isKindOfClass:[NSDictionary class]]) {
            parseJSONDictionary(responseObject);
            [subscriber sendCompleted];
        }
        else if (responseObject == nil || [responseObject isKindOfClass:[NSNull class]]) {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        }
        else {
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Response wasn't an array or dictionary (%@): %@", @""), [responseObject class], responseObject];
            [subscriber sendError:[self parsingErrorWithFailureReason:failureReason]];
        }
        return nil;
    }];
}


#pragma mark - 解析错误
/**
 业务错误
 */
- (NSError *)parsingErrorWithFailureReason:(NSString *)localizedFailureReason {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Could not parse the service response.", @"");
    if (localizedFailureReason != nil)  userInfo[NSLocalizedFailureReasonErrorKey] = localizedFailureReason;
    return [NSError errorWithDomain:MSHTTPServiceErrorDomain code:MSHTTPServiceErrorJSONParsingFailed userInfo:userInfo];
}


/**
 网络请求错误
 */
- (NSError *)errorFromRequestWithTask:(NSURLSessionTask *)task httpResponse:(NSHTTPURLResponse *)httpResponse responseObject:(NSDictionary *)responseObject error:(NSError *)error {
    NSInteger HTTPCode = httpResponse.statusCode;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    NSInteger errorCode = MSHTTPServiceErrorConnectionFailed;
    NSString *errorDesc = @"服务器出错了，请稍后重试~";
    
    NSInteger httpFirstCode = HTTPCode/100;
    
    if (httpFirstCode>0) {
        if (httpFirstCode == 4) {
            // 请求错误，请稍后再试
            if (HTTPCode == 408) {
                errorDesc = @"请求超时，请稍后再试~";
            }
            else{
                errorDesc = @"请求出错了，请稍后重试~";
            }
        }
        else if (httpFirstCode == 5 || httpFirstCode == 6) {
            errorDesc = @"服务器出错了，请稍后重试~";
        }
        else if (!self.reachabilityManager.isReachable) {
            errorDesc = @"网络开小差了，请稍后再试~";
        }
    }
    else {
        if (!self.reachabilityManager.isReachable) {
            errorDesc = @"网络开小差了，请稍后再试~";
        }
    }
    
    switch (HTTPCode) {
        case 400:
            errorCode = MSHTTPServiceErrorBadRequest;
            break;
        case 403:
            errorCode = MSHTTPServiceErrorRequestForbidden;
        case 422:
            errorCode = MSHTTPServiceErrorServiceRequestFailed;
        default:
            // 从error中解析
            if ([error.domain isEqualToString:NSURLErrorDomain]) {
                errorDesc = @"请求出错了，请稍后重试~";
                switch (error.code) {
                    case NSURLErrorSecureConnectionFailed:
                    case NSURLErrorServerCertificateHasBadDate:
                    case NSURLErrorServerCertificateHasUnknownRoot:
                    case NSURLErrorServerCertificateUntrusted:
                    case NSURLErrorServerCertificateNotYetValid:
                    case NSURLErrorClientCertificateRejected:
                    case NSURLErrorClientCertificateRequired:
                        errorCode = MSHTTPServiceErrorSecureConnectionFailed; /// 建立安全连接出错了
                        break;
                    case NSURLErrorTimedOut:
                        errorDesc = @"请求超时，请稍后再试~";
                        break;
                    case NSURLErrorNotConnectedToInternet:
                        errorDesc = @"网络开小差了，请稍后重试~";
                        break;
                }
            }
            break;
    }
    
    userInfo[MSHTTPServiceErrorHTTPStatusCodeKey] = @(HTTPCode);
    userInfo[MSHTTPServiceErrorDescriptionKey] = errorDesc;
    if (task.currentRequest.URL != nil) {
        userInfo[MSHTTPServiceErrorRequesURLKey] = task.currentRequest.URL.absoluteString;
    }
    if (task.error != nil) {
        userInfo[NSUnderlyingErrorKey] = task.error;
    }
    return [NSError errorWithDomain:MSHTTPServiceErrorDomain code:errorCode userInfo:userInfo];
    
}


#pragma mark - 配置
/**
 配置http请求session
 */
- (void)ms_configHTTPSevice {
    // 1.0 返回数据序列化
    AFJSONResponseSerializer *responseSericalizer = [AFJSONResponseSerializer serializer];
    responseSericalizer.removesKeysWithNullValues = YES;
    responseSericalizer.readingOptions = NSJSONReadingAllowFragments;
    self.responseSerializer = responseSericalizer;
    
    // 2.0 请求数据序列化
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    // 3.0 安全策略
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    // 是否允许无效证书(也就是自建证书)，默认是NO
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认是YES
    securityPolicy.validatesDomainName = NO;
    self.securityPolicy = securityPolicy;
    
    // 4.0 支持解析类型设置
    self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                      @"text/json",
                                                      @"text/javascript",
                                                      @"text/html",
                                                      @"text/plain",
                                                      @"text/html;charset=UTF-8",
                                                      nil];
    // 5.0 开启网络监测
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusUnknown) {
            NSLog(@"== 未知网络 ==");
        }
        else if (status == AFNetworkReachabilityStatusNotReachable) {
            NSLog(@"== 无网络 ==");
        }else{
            NSLog(@"== 有网络 ==");
        }
    }];
    [self.reachabilityManager startMonitoring];
    
}


/**
 httpRequest 序列化
 
 @param request 请求类
 @return HTTPRequestSerializer
 */
- (AFHTTPRequestSerializer *)ms_requestSerializerWithRequest:(MSHTTPRequest *)request {
    // 获取请求参数
    NSMutableDictionary *parameters = [self ms_parameterWithRequest:request];
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    for (NSString *key in parameters) {
        NSString *value = parameters[key];
        if (value.length == 0) {
            continue;
        }
        [requestSerializer setValue:value forHTTPHeaderField:key];
    }
    return requestSerializer;
}


/**
 获取完成的请求参数(基础的+扩展参数)
 
 @param request 请求类
 @return 请求参数字典
 */
- (NSMutableDictionary *)ms_parameterWithRequest:(MSHTTPRequest *)request {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSDictionary *extendsUrlParams = [request.urlParameters.extendsParameters mj_keyValues].copy;
    if ([extendsUrlParams count]) {
        [parameters addEntriesFromDictionary:extendsUrlParams];
    }
    if ([request.urlParameters.paramters count]) {
        [parameters addEntriesFromDictionary:request.urlParameters.paramters];
    }
    return parameters;
}


#pragma mark - 打印请求日志
- (void)logHTTPRequest:(NSURLSessionTask *)task body:params error:(NSError *)error {
    NSLog(@">>>>>>>>>>>>>>>>>>>>>👇 Request Finish 👇>>>>>>>>>>>>>>>>>>>>>>>>>>");
    NSLog(@"Request%@========>:%@", error?@"失败":@"成功", task.currentRequest.URL.absoluteString);
    NSLog(@"RequestBody======>:%@", params);
    NSLog(@"RequstHeader=====>:%@", task.currentRequest.allHTTPHeaderFields);
    NSLog(@"Response=========>:%@", task.response);
    NSLog(@"Error============>:%@", error);
    NSLog(@"<<<<<<<<<<<<<<<<<<<<<👆 Request Finish 👆<<<<<<<<<<<<<<<<<<<<<<<<<<");
}



@end
