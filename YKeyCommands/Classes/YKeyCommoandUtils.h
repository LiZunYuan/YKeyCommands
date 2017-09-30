//
//  YKeyCommoandUtils.h
//  Pods
//
//  Created by 李遵源 on 2017/9/29.
//
//

#import <Foundation/Foundation.h>

@interface YKeyCommoandUtils : NSObject

#define YAssertMainQueue() NSAssert(YIsMainQueue(), @"This function must be called on the main queue")

extern BOOL YIsMainQueue();

@end
