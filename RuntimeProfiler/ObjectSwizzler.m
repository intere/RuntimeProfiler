//
//  ObjectSwizzler.m
//  RuntimeProfiler
//
//  Created by Eric Internicola on 9/7/15.
//  Copyright (c) 2015 iColasoft. All rights reserved.
//

#import "ObjectSwizzler.h"
#import "Profiler.h"

@implementation ObjectSwizzler

+(void)profileAllInstanceMethods:(NSObject *)objectToProfile {
    NSArray *methodList = [Swizzler getMethodsForClass:[objectToProfile class]];
    
    for (NSString *methodName in methodList) {
        if(![self isBlacklisted:methodName]) {
            [self profileInstance:objectToProfile methodNamed:methodName];
        }
    }
}

+(void)profileAllMethods:(Class)clazz {
    NSArray *methodList = [Swizzler getMethodsForClass:clazz];
    
    for(NSString *methodName in methodList) {
        [self profileClass:clazz methodNamed:methodName];
    }
}

+(void)profileClass:(Class)clazz methodNamed:(NSString *)methodName {
    __block ProfileLog *profiler = nil;
    
    id beforeBlock = ^{
        profiler = [[ProfileLog alloc]initWithClassName:[clazz description] methodName:methodName];
    };
    
    id afterBlock = ^{
        [[StatsProvider getSharedInstance] addPerformanceLog:profiler];
    };
    
    [clazz aspect_hookSelector:NSSelectorFromString(methodName) withOptions:AspectPositionBefore usingBlock:beforeBlock error:nil];
    [clazz aspect_hookSelector:NSSelectorFromString(methodName) withOptions:AspectPositionAfter usingBlock:afterBlock error:nil];
}

+(void)profileInstance:(NSObject *)objectToProfile methodNamed:(NSString *)methodName {
    __block NSString *localMethodName = [methodName copy];
    __block ProfileLog *profiler = nil;
    
    id beforeBlock = ^{
        profiler = [[ProfileLog alloc]initWithClassName:[[objectToProfile class] description] methodName:localMethodName];
    };
    
    id afterBlock = ^{
        [[StatsProvider getSharedInstance] addPerformanceLog:profiler];
    };
    
    NSLog(@"Profiling Method: %@", localMethodName);
    
    [objectToProfile aspect_hookSelector:NSSelectorFromString(localMethodName) withOptions:AspectPositionBefore usingBlock:beforeBlock error:nil];
    [objectToProfile aspect_hookSelector:NSSelectorFromString(localMethodName) withOptions:AspectPositionAfter usingBlock:afterBlock error:nil];
}


+(BOOL) isBlacklisted:(NSString *)methodName {
    NSArray *METHOD_BLACKLIST = @[ @"respondsToSelector:", @"class", @"aspect_hookSelector:withOptions:usingBlock:error:" ];
    
    for (NSString *blacklistMethod in METHOD_BLACKLIST) {
        if ([blacklistMethod isEqualToString:methodName]) {
            return YES;
        }
    }
    
    return NO;
}

@end
