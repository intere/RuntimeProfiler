//
//  Swizzler.swift
//  RuntimeProfiler
//
//  Created by Eric Internicola on 9/7/15.
//  Copyright (c) 2015 iColasoft. All rights reserved.
//

import Foundation

/**
 * Swizzler provides you some helper methods for Swizzling.
 */
public class Swizzler: NSObject {
    /**
     * Give me an array of method names for the given class.
     */
    @objc
    public static func getMethodsForClass(clazz: AnyClass) -> NSArray {
        let methods = getMethodMapForClass(clazz)
        var methodList: Array<String> = []
        
        for(key, value) in methods {
            methodList.append(key)
        }
        
        return methodList as NSArray
    }
    
    public static func profileAllClassMethods(clazz: AnyClass) {
        
    }
    
    /**
     * Give me a class, and I'll give you the methods in a map.
     */
    public static func getMethodMapForClass(clazz: AnyClass) -> Dictionary<String, Method> {
        var methods: Dictionary<String, Method> = [:]
        var mc:CUnsignedInt = 0
        var mlist:UnsafeMutablePointer<Method> = class_copyMethodList(clazz, &mc);
        
        for var i:CUnsignedInt = 0; i < mc; i++ {
            let methodSelector = method_getName(mlist.memory)
            let methodName = methodSelector.description
            // Cache the method (name / method)
            methods[methodName] = mlist.memory
            mlist = mlist.successor()
        }
        return methods
    }
    
    /** Gives you back a Method for the specified class and method name.  */
    @objc public static func getSpecificMethodForClass(clazz: AnyClass, methodName: String) -> Method {
        return class_getClassMethod(clazz, Selector(methodName))
    }
}
