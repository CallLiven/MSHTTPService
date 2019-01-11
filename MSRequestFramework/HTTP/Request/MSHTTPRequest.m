//
//  MSHTTPRequest.m
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "MSHTTPRequest.h"

@interface MSHTTPRequest()
@property (nonatomic, strong, readwrite) MSURLParameters *urlParameters;
@end

@implementation MSHTTPRequest

+ (instancetype)requestWithParameters:(MSURLParameters *)parameters {
    return [[self alloc]initRequestWithParameters:parameters];
}

- (instancetype)initRequestWithParameters:(MSURLParameters *)parameters {
    self = [super init];
    if (self) {
        self.urlParameters = parameters;
    }
    return self;
}

@end
