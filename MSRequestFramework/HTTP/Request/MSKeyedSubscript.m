//
//  MSKeyedSubscript.m
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import "MSKeyedSubscript.h"

@interface MSKeyedSubscript()
@property (nonatomic, strong, readwrite) NSMutableDictionary *kvs;
@end


@implementation MSKeyedSubscript

+ (instancetype)subscript {
    return [[self alloc]init];
}

+ (instancetype)subscriptWithDictionary:(NSDictionary *)dict {
    return [[self alloc]initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.kvs = [NSMutableDictionary dictionary];
        if ([dict count]) {
            [self.kvs addEntriesFromDictionary:dict];
        }
    }
    return self;
}

- (id)objectForKeyedSubscript:(id)key {
    return key ? [self.kvs objectForKey:key] : nil;
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    if (key) {
        if (obj) {
            [self.kvs setObject:obj forKey:key];
        }else{
            [self.kvs removeObjectForKey:key];
        }
    }
}

- (NSDictionary *)dictionary {
    return self.kvs.copy;
}

@end
