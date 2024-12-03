//
//  StochasticSplineReducer.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class StochasticSplineReducer {
    
    static let minBucketCount = 8
    static let minNumberOfSamples = 3
    
    var healedSegments = [StochasticSplineReducerSegment]()
    var healedSegmentCount = 0
    
    var segments = [StochasticSplineReducerSegment]()
    var segmentCount = 0
    
    var testSegmentsA = [StochasticSplineReducerSegment]()
    var testSegmentCountA = 0
    
    var testSegmentsB = [StochasticSplineReducerSegment]()
    var testSegmentCountB = 0
    
    var bucketes = [StochasticSplineReducerBucket]()
    var bucketCount = 0
    
    var tempBucketes = [StochasticSplineReducerBucket]()
    var tempBucketIndices = [Int]()
    var tempBucketCount = 0
    
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
        
        purgeBucketes()
        purgeSegments()
        purgeHealedSegments()
    }
    
    func reduce(inputSpline: ManualSpline,
                outputSpline: ManualSpline,
                numberOfPointsSampledForEachControlPoint: Int,
                programmableCommands: [StochasticSplineReducerCommand]) {
        
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
        for bucketIndex in 0..<bucketCount {
            let bucket = bucketes[bucketIndex]
            outputSpline.addControlPoint(bucket.x, bucket.y)
            bucket.purgeHealedSegments()
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
    
    func unvisitBothNeighbors(bucketIndex: Int) {
        if bucketIndex < 0 {
            print("FATAL: Attempting to unvisit bucketIndex = \(bucketIndex) / \(bucketCount)")
            return
        }
        if bucketIndex >= bucketCount {
            print("FATAL: Attempting to unvisit bucketIndex = \(bucketIndex) / \(bucketCount)")
            return
        }
        var indexBck1 = bucketIndex - 1
        if indexBck1 == -1 { indexBck1 = bucketCount - 1 }
        var indexFwd1 = bucketIndex + 1
        if indexFwd1 == bucketCount { indexFwd1 = 0 }
        bucketes[indexBck1].isVisited = false
        bucketes[indexFwd1].isVisited = false
    }
    
    func TEST_TP_TO_SRHS(numberOfPointsSampledForEachControlPoint: Int) {
        
        purgeHealedSegments()
        if testPointCountA > 0 {
            var prevX = testPointsXA[0]
            var prevY = testPointsYA[0]
            
            for testPointsIndex in 1..<testPointCountA {
                let x = testPointsXA[testPointsIndex]
                let y = testPointsYA[testPointsIndex]
                let segment = StochasticSplineReducerPartsFactory.shared.withdrawSegment()
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
                let segment = StochasticSplineReducerPartsFactory.shared.withdrawSegment()
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
        
        for bucketIndex in 0..<bucketCount {
            
            var nextBucketIndex = bucketIndex + 1
            if nextBucketIndex == bucketCount {
                nextBucketIndex = 0
            }
            
            let currentBucket = bucketes[bucketIndex]
            let nextBucket = bucketes[nextBucketIndex]
            
            currentBucket.purgeHealedSegments()
            
            let numberOfCombinedPouches = currentBucket.numberOfCombinedBucketes + nextBucket.numberOfCombinedBucketes
            let numberOfPointsToCheck = numberOfCombinedPouches * numberOfPointsSampledForEachControlPoint
            
            var pointIndexA = 1
            while pointIndexA <= numberOfPointsToCheck {
                
                let previousPercent = Float(pointIndexA - 1) / Float(numberOfPointsToCheck)
                let currentPercent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x1 = outputSpline.getX(index: bucketIndex, percent: previousPercent)
                let y1 = outputSpline.getY(index: bucketIndex, percent: previousPercent)
                
                let x2 = outputSpline.getX(index: bucketIndex, percent: currentPercent)
                let y2 = outputSpline.getY(index: bucketIndex, percent: currentPercent)
                
                //print("@ \(bucketIndex) / \(bucketCount) x1 = \(x1), y1 = \(y1), p1 = \(previousPercent)")
                //print("@ \(bucketIndex) / \(bucketCount) x2 = \(x2), y2 = \(y2), p2 = \(currentPercent)")
                
                let segment = StochasticSplineReducerPartsFactory.shared.withdrawSegment()
                
                if pointIndexA == 1 {
                    segment.isFlagged = true
                } else {
                    segment.isFlagged = false
                }
                
                currentBucket.addHealedSegment(segment)
                
                segment.x1 = x1
                segment.y1 = y1
                
                segment.x2 = x2
                segment.y2 = y2
                
                segment.precompute()
                
                pointIndexA += 1
            }
            
        }
        
    }
    
    
    func addHealedSegment(_ segment: StochasticSplineReducerSegment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            StochasticSplineReducerPartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
}
