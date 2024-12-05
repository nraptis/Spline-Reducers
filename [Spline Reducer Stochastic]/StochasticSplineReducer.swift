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
    
    var buckets = [StochasticSplineReducerBucket]()
    var bucketCount = 0
    
    var testBuckets = [StochasticSplineReducerBucket]()
    var _testBucketCapacity = 0
    var _testBucketCount = 0
    
    
    var tempBuckets = [StochasticSplineReducerBucket]()
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
    
    let pathChopper = StochasticSplineReducerPathChopper()
    let exploredPool = StochasticSplineReducerExploredPool()
    
    var chopperBestPath = [Int]()
    var chopperBestPathCount = 0
    
    var DISZZZ = Float(0.0)
    
    func clear() {
        testPointCountA = 0
        testPointCountB = 0
        testSegmentCountA = 0
        testSegmentCountB = 0
        
        purgeBuckets()
        purgeSegments()
        purgeHealedSegments()
        purgeTestBuckets()
    }
    
    // Here we would need to account for self-intersect.
    func reduceChopper(numberOfPointsSampledForEachControlPoint: Int,
                       bestDistanceSquaredSoFar: Float) -> StochasticSplineReducerResponse {
        
        internalSpline.removeAll(keepingCapacity: true)
        for testBucketIndex in 0..<_testBucketCount {
            let testBucket = testBuckets[testBucketIndex]
            internalSpline.addControlPoint(testBucket.x, testBucket.y)
        }
        internalSpline.solve(closed: true)
        
        
        
        var greatestDistanceSquaredSoFar = Float(0.0)
        
        for testBucketIndex in 0..<_testBucketCount {
            
            testPointCountA = 0
            testSegmentCountA = 0
            
            let testBucket = testBuckets[testBucketIndex]
            for segmentIndex in 0..<testBucket.segmentCount {
                let segment = testBucket.segments[segmentIndex]
                addTestSegmentA(segment)
            }
            
            let numberOfCombinedBuckets = testBucket.numberOfCombinedbuckets
            let numberOfPoints = numberOfCombinedBuckets * numberOfPointsSampledForEachControlPoint
            for pointIndex in 1..<numberOfPoints {
                let percent = Float(pointIndex) / Float(numberOfPoints)
                let x = internalSpline.getX(index: testBucketIndex, percent: percent)
                let y = internalSpline.getY(index: testBucketIndex, percent: percent)
                addPointTestPointsA(x: x, y: y)
            }
            
            //try with opposite, should be interesting backward bal
            //if !isTestPointsComplexA() { return StochasticSplineReducerResponse.complex }
            
            
            var error = false
            let distanceA = getMaximumDistanceFromTestPointsToSegmentsA(isError: &error)
            if error { return StochasticSplineReducerResponse.failure }
            if distanceA > bestDistanceSquaredSoFar { return .overweight }
            if distanceA > greatestDistanceSquaredSoFar { greatestDistanceSquaredSoFar = distanceA }
        }
        
        chopperBestPathCount = pathChopper.pathCount
        while chopperBestPath.count < chopperBestPathCount {
            chopperBestPath.append(0)
        }
        for pathIndex in 0..<pathChopper.pathCount {
            chopperBestPath[pathIndex] = pathChopper.path[pathIndex]
        }
        return StochasticSplineReducerResponse.validNewBestMatch(greatestDistanceSquaredSoFar)
    }
        
    func executeCommand_ReduceChopper(numberOfPointsSampledForEachControlPoint: Int,
                                      minimumStep: Int,
                                      maximumStep: Int,
                                      tryCount: Int,
                                      dupeOrInvalidRetryCount: Int,
                                      tolerance: Float) {
        
        
        for bucketIndex in 0..<bucketCount {
            let bucket = buckets[bucketIndex]
            if bucket.numberOfCombinedbuckets > 1 {
                print("SKIPPING! We can only do ReduceChopper on buckets with exactly one combined bucket.")
                return
            }
        }
        
        let toleranceSquared = tolerance * tolerance
        
        if !pathChopper.build(pathLength: bucketCount,
                              minimumStep: minimumStep,
                              maximumStep: maximumStep) {
            print("Path chopper could not build!")
        }
        
        exploredPool.clear()
        
        chopperBestPathCount = 0
        
        var KP_tryCount = 0
        var KP_attemptCount = 0
        var KP_complexCount = 0
        var KP_invalidRetryCount = 0
        var KP_dupeRetryCount = 0
        var KP_successCount = 0
        var KP_failureCount = 0
        
        var bestDistanceSquaredSoFar = Float(100_000_000.0)
        
        for _ in 0..<tryCount {
            KP_tryCount += 1
            
            var isValidPath = false
            for _ in 0..<dupeOrInvalidRetryCount {
                pathChopper.solve()
                if pathChopper.pathCount <= 3 {
                    KP_invalidRetryCount += 1
                    continue
                }
                if exploredPool.contains(chopper: pathChopper) {
                    KP_dupeRetryCount += 1
                    continue
                }
                
                isValidPath = true
                break
            }
            
            if isValidPath == false {
                KP_failureCount += 1
                break
            }
            
            KP_attemptCount += 1
            
            exploredPool.ingest(chopper: pathChopper)
            
            if !loadUpTestBucketsFromPathChopperPath() {
                print("FATAL ERROR: We should not fail to load the test buckets")
                KP_failureCount += 1
                continue
            }
            
            let response = reduceChopper(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                         bestDistanceSquaredSoFar: bestDistanceSquaredSoFar)
            switch response {
            case .validNewBestMatch(let distanceSquared):
                bestDistanceSquaredSoFar = distanceSquared
                KP_successCount += 1
            case .complex:
                KP_complexCount += 1
            case .overweight:
                KP_failureCount += 1
            case .failure:
                KP_failureCount += 1
            }
        }
        
        if chopperBestPathCount > 0 {
            print("***COMPLETE (CHOPPER)*** ===> SUCCESS!")
        } else {
            print("***COMPLETE (CHOPPER)*** ===> FAILURE!")
        }
        
        print("(CHOPPER) => KP_tryCount = \(KP_tryCount) / \(tryCount) (min = \(minimumStep), max = \(maximumStep))")
        //print("ReduceChopper => KP_attemptCount = \(KP_attemptCount)")
        //print("ReduceChopper => KP_successCount = \(KP_successCount)")
        //print("ReduceChopper => KP_failureCount = \(KP_failureCount)")
        //print("ReduceChopper => KP_complexCount = \(KP_complexCount)")
        //print("ReduceChopper => KP_invalidRetryCount = \(KP_invalidRetryCount)")
        //print("ReduceChopper => KP_dupeRetryCount = \(KP_dupeRetryCount)")
        
        
        DISZZZ = bestDistanceSquaredSoFar
        if DISZZZ > Math.epsilon {
            DISZZZ = sqrtf(DISZZZ)
        }
        
        
        if chopperBestPathCount > 0 {
            if bestDistanceSquaredSoFar < toleranceSquared {
                loadUpTestBucketsFromPathBestPath()
                transferTestBucketsToBuckets()
            }
        }
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
            case .chopper(let reductionData):
                executeCommand_ReduceChopper(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                             minimumStep: reductionData.minimumStep,
                                             maximumStep: reductionData.maximumStep,
                                             tryCount: reductionData.tryCount,
                                             dupeOrInvalidRetryCount: reductionData.dupeOrInvalidRetryCount,
                                             tolerance: reductionData.tolerance)
            }
        }
        
        outputSpline.removeAll(keepingCapacity: true)
        for bucketIndex in 0..<bucketCount {
            let bucket = buckets[bucketIndex]
            outputSpline.addControlPoint(bucket.x, bucket.y)
            bucket.purgeHealedSegments()
        }
        outputSpline.solve(closed: true)
        
        
        //TEST_ZP_TO_ZPHS(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint, outputSpline: outputSpline)
        
        //TEST_TP_TO_SRHS(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint)
        
        //
        // Maybe we do not want to see the test segments, etc.
        //
        
        //testPointCountA = 0
        //testPointCountB = 0
        //testSegmentCountA = 0
        //testSegmentCountB = 0
        
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
        buckets[indexBck1].isVisited = false
        buckets[indexFwd1].isVisited = false
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
    
    func TEST_TZP_T22(numberOfPointsSampledForEachControlPoint: Int) {
        
        
        
        for bucketIndex in 0..<_testBucketCount {
            
            var nextBucketIndex = bucketIndex + 1
            if nextBucketIndex == _testBucketCount {
                nextBucketIndex = 0
            }
            
            let currentBucket = testBuckets[bucketIndex]
            let nextBucket = testBuckets[nextBucketIndex]
            
            currentBucket.purgeHealedSegments()
            
            let numberOfCombinedPouches = currentBucket.numberOfCombinedbuckets
            let numberOfPointsToCheck = numberOfCombinedPouches * numberOfPointsSampledForEachControlPoint
            
            var pointIndexA = 1
            while pointIndexA <= numberOfPointsToCheck {
                
                let previousPercent = Float(pointIndexA - 1) / Float(numberOfPointsToCheck)
                let currentPercent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x1 = internalSpline.getX(index: bucketIndex, percent: previousPercent)
                let y1 = internalSpline.getY(index: bucketIndex, percent: previousPercent)
                
                let x2 = internalSpline.getX(index: bucketIndex, percent: currentPercent)
                let y2 = internalSpline.getY(index: bucketIndex, percent: currentPercent)
                
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
    
    func TEST_ZP_TO_ZPHS(numberOfPointsSampledForEachControlPoint: Int,
                         outputSpline: ManualSpline) {
        
        for bucketIndex in 0..<bucketCount {
            
            var nextBucketIndex = bucketIndex + 1
            if nextBucketIndex == bucketCount {
                nextBucketIndex = 0
            }
            
            let currentBucket = buckets[bucketIndex]
            let nextBucket = buckets[nextBucketIndex]
            
            currentBucket.purgeHealedSegments()
            
            let numberOfCombinedPouches = currentBucket.numberOfCombinedbuckets
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
