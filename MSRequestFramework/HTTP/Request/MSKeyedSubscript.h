//
//  MSKeyedSubscript.h
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//  工具类(字典)：参数

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSKeyedSubscript : NSObject

+ (instancetype)subscript;
+ (instancetype)subscriptWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)forKeyedSubscript:(id<NSCopying>)key;

- (NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
