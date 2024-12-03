//
//  SplineReducer6.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer6 {
    
    static let minZipperPouchCount = 8
    static let minNumberOfSamples = 3
    
    var healedSegments = [SplineReducer6Segment]()
    var healedSegmentCount = 0
    
    var segments = [SplineReducer6Segment]()
    var segmentCount = 0
    
    var testSegmentsA = [SplineReducer6Segment]()
    var testSegmentCountA = 0
    
    var testSegmentsB = [SplineReducer6Segment]()
    var testSegmentCountB = 0
    
    var zipperPouches = [SplineReducer6ZipperPouch]()
    var zipperPouchCount = 0
    
    var tempZipperPouches = [SplineReducer6ZipperPouch]()
    var tempZipperPouchIndices = [Int]()
    var tempZipperPouchCount = 0
    
    var testPointCountA = 0
    var testPointCapacityA = 0
    var testPointsXA = [Float]()
    var testPointsYA = [Float]()
    
    var testPointCountB = 0
    var testPointCapacityB = 0
    var testPointsXB = [Float]()
    var testPointsYB = [Float]()

    var internalSpline = AutomaticSpline()
    
    func clear() {
        testPointCountA = 0
        testPointCountB = 0
        testSegmentCountA = 0
        testSegmentCountB = 0
        
        purgeZipperPouches()
        purgeSegments()
        purgeHealedSegments()
    }
    
    func reduce(inputSpline: ManualSpline,
                outputSpline: ManualSpline,
                numberOfPointsSampledForEachControlPoint: Int,
                programmableCommands: [SplineReducer6Command]) {
        
        clear()
        
        readInputSpline(inputSpline: inputSpline,
                        numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint)
        
        for programmableCommand in programmableCommands {
            switch programmableCommand {
            case .reduceFrontAndBack(let reductionData):
                executeCommand_ReduceDouble(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                            tryCount: reductionData.tryCount,
                                            maxCombinedPouches: reductionData.maxCombinedPouches,
                                            tolerance: reductionData.tolerance)
            case .reduceBackOnly(let reductionData):
                executeCommand_ReduceSingle(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                            tryCount: reductionData.tryCount,
                                            maxCombinedPouches: reductionData.maxCombinedPouches,
                                            tolerance: reductionData.tolerance)
            }
        }
        
        outputSpline.removeAll(keepingCapacity: true)
        for zipperPouchIndex in 0..<zipperPouchCount {
            let zipperPouch = zipperPouches[zipperPouchIndex]
            outputSpline.addControlPoint(zipperPouch.x, zipperPouch.y)
            zipperPouch.purgeHealedSegments()
        }
        outputSpline.solve(closed: true)
        
        
        TEST_ZP_TO_ZPHS(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint, outputSpline: outputSpline)
        
        //TEST_TP_TO_SRHS(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint)
        
        //
        // Maybe we do not want to see the test segments, etc.
        //
        
        testPointCountA = 0
        testPointCountB = 0
        testSegmentCountA = 0
        testSegmentCountB = 0
        
    }
    
    func unvisitBothNeighbors(zipperPouchIndex: Int) {
        if zipperPouchIndex < 0 {
            print("FATAL: Attempting to unvisit zipperPouchIndex = \(zipperPouchIndex) / \(zipperPouchCount)")
            return
        }
        if zipperPouchIndex >= zipperPouchCount {
            print("FATAL: Attempting to unvisit zipperPouchIndex = \(zipperPouchIndex) / \(zipperPouchCount)")
            return
        }
        var indexBck1 = zipperPouchIndex - 1
        if indexBck1 == -1 { indexBck1 = zipperPouchCount - 1 }
        var indexFwd1 = zipperPouchIndex + 1
        if indexFwd1 == zipperPouchCount { indexFwd1 = 0 }
        zipperPouches[indexBck1].isVisited = false
        zipperPouches[indexFwd1].isVisited = false
    }
    
    func TEST_TP_TO_SRHS(numberOfPointsSampledForEachControlPoint: Int) {
        
        purgeHealedSegments()
        if testPointCountA > 0 {
            var prevX = testPointsXA[0]
            var prevY = testPointsYA[0]
            
            for testPointsIndex in 1..<testPointCountA {
                let x = testPointsXA[testPointsIndex]
                let y = testPointsYA[testPointsIndex]
                let segment = SplineReducer6PartsFactory.shared.withdrawSegment()
                addHealedSegment(segment)
                segment.isFlagged = false
                segment.x1 = prevX;segment.y1 = prevY
                segment.x2 = x;segment.y2 = y
                segment.precompute()
                prevX = x; prevY = y
            }
        }
        if testPointCountB > 0 {
            var prevX = testPointsXB[0]
            var prevY = testPointsYB[0]
            
            for testPointsIndex in 1..<testPointCountB {
                let x = testPointsXB[testPointsIndex]
                let y = testPointsYB[testPointsIndex]
                let segment = SplineReducer6PartsFactory.shared.withdrawSegment()
                addHealedSegment(segment)
                segment.isFlagged = true
                segment.x1 = prevX;segment.y1 = prevY
                segment.x2 = x;segment.y2 = y
                segment.precompute()
                prevX = x; prevY = y
            }
        }
    }
    
    
    func TEST_ZP_TO_ZPHS(numberOfPointsSampledForEachControlPoint: Int,
                          outputSpline: ManualSpline) {
        
        for zipperPouchIndex in 0..<zipperPouchCount {
            
            var nextZipperPouchIndex = zipperPouchIndex + 1
            if nextZipperPouchIndex == zipperPouchCount {
                nextZipperPouchIndex = 0
            }
            
            let currentZipperPouch = zipperPouches[zipperPouchIndex]
            let nextZipperPouch = zipperPouches[nextZipperPouchIndex]
            
            currentZipperPouch.purgeHealedSegments()
            
            let numberOfCombinedPouches = currentZipperPouch.numberOfCombinedZipperPouches + nextZipperPouch.numberOfCombinedZipperPouches
            let numberOfPointsToCheck = numberOfCombinedPouches * numberOfPointsSampledForEachControlPoint
            
            var pointIndexA = 1
            while pointIndexA <= numberOfPointsToCheck {
                
                let previousPercent = Float(pointIndexA - 1) / Float(numberOfPointsToCheck)
                let currentPercent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x1 = outputSpline.getX(index: zipperPouchIndex, percent: previousPercent)
                let y1 = outputSpline.getY(index: zipperPouchIndex, percent: previousPercent)
                
                let x2 = outputSpline.getX(index: zipperPouchIndex, percent: currentPercent)
                let y2 = outputSpline.getY(index: zipperPouchIndex, percent: currentPercent)
                
                //print("@ \(zipperPouchIndex) / \(zipperPouchCount) x1 = \(x1), y1 = \(y1), p1 = \(previousPercent)")
                //print("@ \(zipperPouchIndex) / \(zipperPouchCount) x2 = \(x2), y2 = \(y2), p2 = \(currentPercent)")
                
                let segment = SplineReducer6PartsFactory.shared.withdrawSegment()
                
                if pointIndexA == 1 {
                    segment.isFlagged = true
                } else {
                    segment.isFlagged = false
                }
                
                currentZipperPouch.addHealedSegment(segment)
                
                
                segment.x1 = x1
                segment.y1 = y1
                
                segment.x2 = x2
                segment.y2 = y2
                
                segment.precompute()
                
                pointIndexA += 1
            }
            
        }
        
    }
    
    
    func addHealedSegment(_ segment: SplineReducer6Segment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            SplineReducer6PartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
}
