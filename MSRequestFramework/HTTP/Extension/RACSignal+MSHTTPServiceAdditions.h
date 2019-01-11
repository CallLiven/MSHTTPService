//
//  RACSignal+MSHTTPServiceAdditions.h
//  MSRequestFramework
//
//  Created by 詹前力 on 2019/1/6.
//  Copyright © 2019年 Liven. All rights reserved.
//

#import <ReactiveObjC/ReactiveObjC.h>

// Convenience category to retreive parsedResults from MHHTTPResponses.
@interface RACSignal (MSHTTPServiceAdditions)
// This method assumes that the receiver is a signal of MHHTTPResponses.
//
// Returns a signal that maps the receiver to become a signal of
// MHHTTPResponses.parsedResult.
- (RACSignal *)mh_parsedResults;
@end
