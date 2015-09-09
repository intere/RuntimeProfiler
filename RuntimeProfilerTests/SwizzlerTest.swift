//
//  SwizzlerTest.swift
//  RuntimeProfiler
//
//  Created by Eric Internicola on 9/8/15.
//  Copyright (c) 2015 iColasoft. All rights reserved.
//

import UIKit
import XCTest
import RuntimeProfiler

class SwizzlerTest: XCTestCase {
    private var instance: NSMutableArray? = nil

    override func setUp() {
        super.setUp()
        self.instance = NSMutableArray()
        StatsProvider.instance.reset()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testProfilingViewWillAppear() {
        Swizzler.profileAllInstanceMethods(instance!)
        instance!.removeAllObjects()
        let results = StatsProvider.instance.getMethodStats("removeAllObjects")
        XCTAssertNotNil(results)
        if nil != results {
            XCTAssert(results!.count == 1)
        }
    }
}
