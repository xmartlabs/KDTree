//
//  PerformanceTests.swift
//  KDTree
//
//  Created by Konrad Feiler on 09.04.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import KDTree

class PerformanceTests: XCTestCase {
    
    let testSteps: [Int] = Array(1...5).map({ num in  1000 * num}) as [Int]
        + Array(2...5).map({ num in    5000 * num}) as [Int]
        + Array(2...8).map({ num in   25000 * num}) as [Int]
        + Array(3...10).map({ num in 100000 * num}) as [Int]
    let testRepeats = 1000
    let testRepeatsBruteForce = 50
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func measureAndReturn(_ block: @escaping () -> Void) -> TimeInterval {
        let before = Date()
        block()
        let after = Date()
        return after.timeIntervalSince(before)
    }
    
    func testPerformanceExample() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            
        }
        var testResults: [[TimeInterval]] = []
        
        for testSize in testSteps {
            print("Running test for \(testSize)")
            
            let points = (0..<testSize).map({_ in CGPoint(x: CGFloat.random(), y: CGFloat.random())})
            let testPoints = (0..<testRepeats).map({_ in CGPoint(x: CGFloat.random(), y: CGFloat.random())})
            var tree: KDTree<CGPoint>?
            
            XCTAssertEqual(points.count, testSize)
            
            let treeBuildTime = measureAndReturn {
                tree = KDTree(values: points)
            }
            
            var nearestPoints = [CGPoint]()
            let searchPointTotalTime = measureAndReturn {
                nearestPoints = testPoints.flatMap({ (point) -> CGPoint? in
                    return tree?.nearest(toElement: point)
                })
            }
            XCTAssertEqual(nearestPoints.count, testPoints.count)
            
            var nearestPointsBruteForce = [CGPoint]()
            let bruteForceSearch = measureAndReturn {
                nearestPointsBruteForce = testPoints[0..<self.testRepeatsBruteForce].map { (searchPoint: CGPoint) -> CGPoint in
                    var bestDistance = Double.infinity
                    let nearest = points.reduce(CGPoint.zero) { (bestPoint: CGPoint, testPoint: CGPoint) -> CGPoint in
                        let testDistance = searchPoint.squaredDistance(to: testPoint)
                        if testDistance < bestDistance {
                            bestDistance = testDistance
                            return testPoint
                        }
                        return bestPoint
                    }
                    return nearest
                }
            }
            
            XCTAssertEqual(nearestPointsBruteForce.prefix(self.testRepeatsBruteForce),
                           nearestPoints.prefix(self.testRepeatsBruteForce))
            
            testResults.append([treeBuildTime,
                                searchPointTotalTime/Double(nearestPoints.count),
                                bruteForceSearch/Double(nearestPointsBruteForce.count)])

            if let element = testResults.last {
                print("build tree in \(element[0])s, find nearest in \(element[1])s, exhaustive search: \(element[2])s")
            }
        }
        
        print("#points,build_tree,nearestNeighbour,LinearSearch")
        for value in testResults.enumerated() {
            print("\(testSteps[value.offset]),\(value.element[0]),\(value.element[1]),\(value.element[2])")
        }
        
        XCTAssertEqual(testResults.count, testSteps.count)
    }
    
}
