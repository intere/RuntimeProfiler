//
//  ObjectSwizzler.h
//  RuntimeProfiler
//
//  Created by Eric Internicola on 9/7/15.
//  Copyright (c) 2015 iColasoft. All rights reserved.
//

#import "Profiler.h"

@interface ObjectSwizzler : NSObject

/**
 * Adds profiling to all instance methods of the provided object.
 */
+(void)profileAllInstanceMethods:(NSObject *)objectToProfile;

/**
 * Adds profiling to all methods of the provided class.
 */
+(void)profileAllMethods:(Class)clazz;


@end
