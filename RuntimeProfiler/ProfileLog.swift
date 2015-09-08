//
//  ProfilingProvider.swift
//  RuntimeProfiler
//
//  Created by Eric Internicola on 9/6/15.
//  Copyright (c) 2015 iColasoft. All rights reserved.
//

import Foundation

public class ProfileLog: NSObject {
    private var startTime: CFAbsoluteTime? = nil
    private var endTime: CFAbsoluteTime? = nil
    private var className: String? = nil
    private var methodName: String? = nil
    private var totalTimeInMs: Int64? = nil
    
    /** Used to construct this ProfileLog object with a class and method only - and it will automatically set the startTime.  */
    public init(className: String, methodName: String) {
        self.className = className
        self.methodName = methodName
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    /** Completes the profiling for you.  */
    public func completeProfiling() {
        self.endTime = CFAbsoluteTimeGetCurrent()
        self.totalTimeInMs = (Int64)((self.endTime! - self.startTime!) * 1000);
    }
    
    /** Gets you the unique "class + method" name.  */
    public func getProfileLogName() -> String {
        return "\(self.className):\(self.methodName)"
    }
    
    /** Gets you the total time in milliseconds betwen the start and end time.  */
    public func getTotalTimeInMs() -> Int64? {
        return self.totalTimeInMs
    }
}
