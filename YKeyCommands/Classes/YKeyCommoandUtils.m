//
//  YKeyCommoandUtils.m
//  Pods
//
//  Created by 李遵源 on 2017/9/29.
//
//

#import "YKeyCommoandUtils.h"

@implementation YKeyCommoandUtils


BOOL YIsMainQueue()
{
    static void *mainQueueKey = &mainQueueKey;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_set_specific(dispatch_get_main_queue(),
                                    mainQueueKey, mainQueueKey, NULL);
    });
    return dispatch_get_specific(mainQueueKey) == mainQueueKey;
}

@end
