//
//  StatsProvider.swift
//  RuntimeProfiler
//
//  Created by Eric Internicola on 9/6/15.
//  Copyright (c) 2015 iColasoft. All rights reserved.
//

import Foundation

public class StatsProvider: NSObject {
    public static let MAIN_THREAD = "Main thread"
    public static let instance = StatsProvider.new()
    private var alertThreshold: Int64 = 500    // If something takes half of a second or longer, we want to know about it
    private var threadProfiles: Dictionary<String, ThreadContext> = [:]
    
    public func reset() {
        threadProfiles.removeAll(keepCapacity: false)
    }
    
    /** Adds the provided ProfileLog object to the map - and completes it for you.  */
    public func addPerformanceLog(profileLog: ProfileLog?) -> Void {
        if nil != profileLog {
            // TODO
            let currentThread = NSThread.currentThread()
            let threadInfo = currentThread.threadDictionary
            if nil == threadInfo["number"] {
                let threadNum = parseThreadNumber()
                threadInfo["number"] = threadNum
                threadInfo["name"] = currentThread.name
                if nil == currentThread.name || currentThread.name.isEmpty {
                    threadInfo["name"] = "Thread \(threadNum)"
                }
            }
            let threadNumber = threadInfo["number"] as! String
            if nil == threadProfiles[threadNumber] {
                threadProfiles[threadNumber] = ThreadContext(threadDictionary: threadInfo)
            }
            
            addProfileLogForContext(profileLog!, context: threadProfiles[threadNumber]!)
        }
    }
    
    /** Here you go Objective-C.  */
    public static func getSharedInstance() -> StatsProvider {
        return self.instance
    }
    
    /** Adds the provided ProfileLog to the provided ThreadContext. */
    private func addProfileLogForContext(profileLog: ProfileLog, context: ThreadContext) {
        profileLog.completeProfiling()
        let profileName = profileLog.getProfileLogName()
        if nil == context.profileMap[profileName] {
            context.profileMap[profileName] = []
        }
        
        context.profileMap[profileName]?.append(profileLog)
        
        // Now see if we should be alerting:
        if profileLog.getTotalTimeInMs() >= alertThreshold {
            context.alerts.append(profileLog)
            println("PROFILE ALERT: \(profileName) - \(profileLog.getTotalTimeInMs()) ms")
        }
    }
    
    /** Prints a stats overview of all threads (in numeric thread order) */
    public func printStatisticsOverview() {
        var keys = threadProfiles.keys.array
        keys.sort { (id1, id2) -> Bool in
            return id1.toInt()! < id2.toInt()!
        }
        
        for(key) in keys {
            printStatisticsOverview(threadProfiles[key]!)
        }
    }
    
    /** Print out an overview of the collected stats.  */
    public func printStatisticsOverview(context: ThreadContext) {
        var statLogs: Array<Summary> = []
        
        for(classMethodName, logs) in context.profileMap {
            let averageTime = computeAverage(logs)
            let totalTime = computeTotal(logs)
            statLogs.append(Summary(averageTime: averageTime, totalTime: totalTime, count: logs.count, classMethodName: classMethodName))
        }
        
        printBreak()
        println("Method Profiler Statistics: \(context.threadName)")
        println("Averages: ")
        statLogs.sort { (stat1: Summary, stat2: Summary) -> Bool in stat1.averageTime > stat2.averageTime }
        for(summary) in statLogs {
            println("\t\(summary.classMethodName) \(summary.averageTime) ms \(summary.count) runs")
        }
        
        println("Totals:")
        statLogs.sort { (stat1: Summary, stat2: Summary) -> Bool in stat1.totalTime > stat2.totalTime }
        for(summary) in statLogs {
            println("\t\(summary.classMethodName) \(summary.totalTime) ms (\(summary.count) runs)")
        }
        printBreak()
    }
    
    public func printAlerts() {
        // TODO
    }
    
    /** Prints out an overview of all of the alerts.  */
    public func printAlerts(ctx: ThreadContext) {
        printBreak()
        if ctx.alerts.count > 0 {
            printGiantAlertText()
            for(index, log) in enumerate(ctx.alerts) {
                println("\(log.getProfileLogName()) took \(log.getTotalTimeInMs()) ms")
            }
        } else {
            println("There are no alerts")
        }
        printBreak()
    }
    
    
    
    /** Inner class for tracking summary statistics.  */
    public class Summary {
        private var averageTime: Int64
        private var totalTime: Int64
        private var count: Int
        private var classMethodName: String
        
        init(averageTime: Int64, totalTime: Int64, count: Int, classMethodName: String) {
            self.averageTime = averageTime
            self.totalTime = totalTime
            self.count = count
            self.classMethodName = classMethodName
        }
    }
    
    /** Inner class for keeping track of Thread Context. */
    public class ThreadContext {
        private let threadNumber: Int
        private let threadName: String
        private var profileMap: Dictionary<String, Array<ProfileLog>> = [:]
        private var alerts: Array<ProfileLog> = []
        
        public init(threadDictionary: NSDictionary) {
            self.threadNumber = (threadDictionary["number"] as! String).toInt()!
            self.threadName = threadDictionary["name"] as! String
        }
    }
    
    public class Spy {
        private var classType: AnyClass
        private var methodCount: UnsafeMutablePointer<UInt32>
        private var methodList: UnsafeMutablePointer<Method>
        
        public init(classType: AnyClass) {
            self.classType = classType
            self.methodCount = UnsafeMutablePointer<UInt32>()
            self.methodList = class_copyMethodList(classType, methodCount)
        }
    }
    
    // MARK: Helper Methods
    
    private func printBreak() {
        println("******************************************************************************")
    }
    
    private func printGiantAlertText() {
        let alertsString =
            " █████╗ ██╗     ███████╗██████╗ ████████╗███████╗\n" +
            "██╔══██╗██║     ██╔════╝██╔══██╗╚══██╔══╝██╔════╝\n" +
            "███████║██║     █████╗  ██████╔╝   ██║   ███████╗\n" +
            "██╔══██║██║     ██╔══╝  ██╔══██╗   ██║   ╚════██║\n" +
            "██║  ██║███████╗███████╗██║  ██║   ██║   ███████║\n" +
            "╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝\n"
        println(alertsString)
    }
    
    /** Computes the average time for the given set of logs.  */
    private func computeAverage(logs: Array<ProfileLog>) -> Int64 {
        return (computeTotal(logs) / Int64(logs.count))
    }
    
    /** Computes the total time for the given set of logs.  */
    private func computeTotal(logs: Array<ProfileLog>) -> Int64 {
        var totalTime: Int64 = 0
        for(index, log) in enumerate(logs) {
            if nil != log.getTotalTimeInMs() {
                totalTime += log.getTotalTimeInMs()!
            }
        }
        return totalTime
    }
    
    /**
    * Parses the Thread description to get the Thread number.
    */
    private func parseThreadNumber() -> String {
        var number = "-1"
        var description = NSThread.currentThread().description
        var ierror: NSError?
        var regex:NSRegularExpression = NSRegularExpression(pattern: "<NSThread: 0x[0-9a-f]+>", options: NSRegularExpressionOptions.CaseInsensitive, error: &ierror)!
        description = regex.stringByReplacingMatchesInString(description, options: nil, range: NSMakeRange(0, description.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), withTemplate: "")
        regex = NSRegularExpression(pattern: "[{}]", options: NSRegularExpressionOptions.CaseInsensitive, error: &ierror)!
        description = regex.stringByReplacingMatchesInString(description, options: nil, range: NSMakeRange(0, description.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), withTemplate: "")
        
        let keyValuePairs: Array<String> = description.componentsSeparatedByString(",")
        
        for(keyValuePair) in keyValuePairs {
            let valuePair = keyValuePair.componentsSeparatedByString(" = ")
            let key: String = valuePair[0]
            let value: String = valuePair[1]
            
            if "number" == key {
                number = value
            }
        }
        
        return number
    }
}