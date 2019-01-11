//
//  RACSignal+MSHTTPServiceAdditions.m
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "RACSignal+MSHTTPServiceAdditions.h"
#import "MSHTTPResponse.h"

@implementation RACSignal (MSHTTPServiceAdditions)

- (RACSignal *)mh_parsedResults {
    return [self map:^(MSHTTPResponse *response) {
        NSAssert([response isKindOfClass:MSHTTPResponse.class], @"Expected %@ to be an MHHTTPResponse.", response);
        return response.parsedResult;
    }];
}

@end
