//
//  MSHTTPResponse.m
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "MSHTTPResponse.h"
#import "MSHTTPServiceConstant.h"

@interface MSHTTPResponse()

/** 服务器返回的数据，并解析过 对应json数据的 data */
@property (nonatomic, strong, readwrite) id parsedResult;
/** 服务器返回的请求业务状态码 对应json数据的 code */
@property (nonatomic, assign, readwrite) MSHTTPResponseCode  code;
/** 服务器返回的描述信息，对应json数据的 msg */
@property (nonatomic, copy  , readwrite) NSString *msg;

@end


@implementation MSHTTPResponse

- (instancetype)initWithResponseObject:(id)responseObject parsedResult:(id)parseResult {
    self = [super init];
    if (self) {
        self.parsedResult = parseResult?:NSNull.null;
        self.code = [responseObject[MSHTTPServiceResponseCodeKey] integerValue];
        self.msg = responseObject[MSHTTPServiceResponseMsgKey];
    }
    return self;
}

@end
