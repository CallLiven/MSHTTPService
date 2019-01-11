//
//  MSURLParameters.m
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "MSURLParameters.h"

@implementation MSURLParameters

+ (instancetype)urlParametersWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    return [[self alloc] initWithUrlParametersWithMethod:method path:path parameters:parameters];
}


- (instancetype)initWithUrlParametersWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    self = [super init];
    if (self) {
        self.method = method;
        self.path = path;
        self.paramters = parameters;
        self.extendsParameters = [[MSURLExtendsParameters alloc]init];
    }
    return self;
}


@end



@implementation MSURLExtendsParameters

+ (instancetype)entextsParameters {
    return [[self alloc]init];
}

- (NSString *)ver {
    static NSString *version = nil;
    if (version == nil) {
        version = [NSBundle mainBundle].infoDictionary[@""];
    }
    return version;
}

- (NSString *)token {
    return @"";
}

- (NSString *)deviceid {
    return @""; 
}

- (NSString *)platform {
    return @"iOS";
}

- (NSString *)channel {
    return @"AppStore";
}

- (NSString *)t {
    return [NSString stringWithFormat:@"%.f",[NSDate date].timeIntervalSince1970];
}

@end
