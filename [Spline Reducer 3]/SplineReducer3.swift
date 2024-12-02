//
//  SplineReducer3.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer3 {
    
    let splineReducerSegmentBucket = SplineReducer3SegmentBucket()
    
    var segments = [SplineReducer3Segment]()
    var segmentCount = 0
    
    var healedSegments = [SplineReducer3Segment]()
    var healedSegmentCount = 0
    
    var testSegments = [SplineReducer3Segment]()
    var testSegmentCount = 0
    
    var weightPoints = [SplineReducer3WeightPoint]()
    var weightPointCount = 0
    
    var zipperPouches = [SplineReducer3ZipperPouch]()
    var zipperPouchCount = 0
    
    private var sampleCount = 0
    private var sampleCapacity = 0
    private var sampleX = [Float]()
    private var sampleY = [Float]()
    
    private var internalSpline = AutomaticSpline()
    
    //
    // Note: This only works for a closed spline...
    //
    func attemptToReduce(inputSpline: ManualSpline,
                         zipperPouchIndex: Int,
                         numberOfSamplesAtEachControlPoint: Int,
                         toleranceSquared: Float) -> Bool {
        
        print("REDUCE @ \(zipperPouchIndex)")
        
        
        var previousZipperPouchIndex = zipperPouchIndex - 1
        if previousZipperPouchIndex == -1 {
            previousZipperPouchIndex = (zipperPouchCount - 1)
        }
        
        var nextZipperPouchIndex = zipperPouchIndex + 1
        if nextZipperPouchIndex == zipperPouchCount {
            nextZipperPouchIndex = 0
        }
        
        var twopZipperPouchIndex = nextZipperPouchIndex + 1
        if twopZipperPouchIndex == zipperPouchCount {
            twopZipperPouchIndex = 0
        }
        
        let previousZipperPouch = zipperPouches[previousZipperPouchIndex]
        let currentZipperPouch = zipperPouches[zipperPouchIndex]
        let nextZipperPouch = zipperPouches[nextZipperPouchIndex]
        let twopZipperPouch = zipperPouches[twopZipperPouchIndex]
        
        
        testSegmentCount = 0
        
        // back 1
        for segmentIndex in 0..<previousZipperPouch.segmentCount {
            let segment = previousZipperPouch.segments[segmentIndex]
            addTestSegment(segment)
        }
        
        // this guy
        for segmentIndex in 0..<currentZipperPouch.segmentCount {
            let segment = currentZipperPouch.segments[segmentIndex]
            addTestSegment(segment)
        }
        
        // forward 1
        for segmentIndex in 0..<nextZipperPouch.segmentCount {
            let segment = nextZipperPouch.segments[segmentIndex]
            addTestSegment(segment)
        }
        
        // forward 2
        for segmentIndex in 0..<twopZipperPouch.segmentCount {
            let segment = twopZipperPouch.segments[segmentIndex]
            addTestSegment(segment)
        }
        
        for segmentIndex in 0..<testSegmentCount {
            let segment = testSegments[segmentIndex]
            segment.isFlagged = true
        }
        
        
        internalSpline.removeAll(keepingCapacity: true)
        for index in 0..<zipperPouchCount {
            if index != zipperPouchIndex {
                let zipperPouch = zipperPouches[index]
                internalSpline.addControlPoint(zipperPouch.x, zipperPouch.y)
            }
        }
        
        internalSpline.solve(closed: true)
        
        if internalSpline.maxIndex <= 1 { return false }
        
        
        purgeHealedSegments()
        

        
        for pissIndex in 0...internalSpline.maxIndex {
            var percent = Float(0.02)
            while percent <= 1.0 {
                
                let x1 = internalSpline.getX(index: pissIndex, percent: percent - 0.02)
                let y1 = internalSpline.getY(index: pissIndex, percent: percent - 0.02)
                
                let x2 = internalSpline.getX(index: pissIndex, percent: percent)
                let y2 = internalSpline.getY(index: pissIndex, percent: percent)
                
                let segment = SplineReducer3PartsFactory.shared.withdrawSegment()
                
                addHealedSegment(segment)
                
                segment.x1 = x1
                segment.y1 = y1
                
                segment.x2 = x2
                segment.y2 = y2
                
                percent += 0.02
            }
        }
        
        
        
        // internalSpline has exactly (zipperPouchCount - 1) points...
        
        sampleCount = 0
        
        
        let zipperPouchCount1 = (zipperPouchCount - 1)
        
        // What could have happened, this was the last index and we removed first point...
        var runningZipperPouchIndex = zipperPouchIndex - 1
        if runningZipperPouchIndex < 0 {
            runningZipperPouchIndex = zipperPouchCount - 2
        }

        
        
        
        // Add the weight points from the previous segment...
        if true {
            let numberOfPointsToCheck = previousZipperPouch.numberOfCombinedZipperPouches * numberOfSamplesAtEachControlPoint
            
            
            print("[TTT]-A For Prev, runningZipperPouchIndex = \(runningZipperPouchIndex), internalSpline.maxIndex = \(internalSpline.maxIndex), original zpi = \(zipperPouchIndex)")
            
            var pointIndexA = 1
            while pointIndexA < numberOfPointsToCheck {
                let percent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x = internalSpline.getX(index: runningZipperPouchIndex,
                                                    percent: percent)
                let y = internalSpline.getY(index: runningZipperPouchIndex,
                                                    percent: percent)
                addPointSample(x: x, y: y)
                
                pointIndexA += 1
            }
            
            print("On Spat A, We Add \(numberOfPointsToCheck) Points...")
            
        }
        
        // What could have happened, this loops past the end.
        runningZipperPouchIndex += 1
        if runningZipperPouchIndex >= zipperPouchCount1 {
            runningZipperPouchIndex = 0
        }
        
        // Add the weight points from the current segment...
        if true {
            
            print("[TTT]-B For Prev, runningZipperPouchIndex = \(runningZipperPouchIndex), internalSpline.maxIndex = \(internalSpline.maxIndex), original zpi = \(zipperPouchIndex)")
            
            let numberOfCombinedPouches = currentZipperPouch.numberOfCombinedZipperPouches + nextZipperPouch.numberOfCombinedZipperPouches
            let numberOfPointsToCheck = numberOfCombinedPouches * numberOfSamplesAtEachControlPoint
            
            var pointIndexA = 0
            while pointIndexA < numberOfPointsToCheck {
                let percent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x = internalSpline.getX(index: runningZipperPouchIndex,
                                                    percent: percent)
                let y = internalSpline.getY(index: runningZipperPouchIndex,
                                                    percent: percent)
                addPointSample(x: x, y: y)
                
                pointIndexA += 1
            }
            
            print("On Spat B, We Add \(numberOfPointsToCheck) Points...")
            
        }
        
        // What could have happened, this loops past the end.
        runningZipperPouchIndex += 1
        if runningZipperPouchIndex >= zipperPouchCount1 {
            runningZipperPouchIndex = 0
        }
        
        
        // Add the weight points from the next segment...
        if true {
            
            print("[TTT]-C For Prev, runningZipperPouchIndex = \(runningZipperPouchIndex), internalSpline.maxIndex = \(internalSpline.maxIndex), original zpi = \(zipperPouchIndex)")
            
            let numberOfPointsToCheck = nextZipperPouch.numberOfCombinedZipperPouches * numberOfSamplesAtEachControlPoint
            
            var pointIndexA = 0
            while pointIndexA < numberOfPointsToCheck {
                let percent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                let weightPoint = SplineReducer3PartsFactory.shared.withdrawWeightPoint()
                
                let x = internalSpline.getX(index: runningZipperPouchIndex,
                                                    percent: percent)
                let y = internalSpline.getY(index: runningZipperPouchIndex,
                                                    percent: percent)
                addPointSample(x: x, y: y)
                
                
                //addWeightPoint(weightPoint)
                //weightPoint.isFlagged = false
                
                pointIndexA += 1
            }
            
            print("On Spat C, We Add \(numberOfPointsToCheck) Points...")
        }
        

        
        
        
        
        // we make weight points into the heae segment.
        
        

        
        
        var greatestDistanceFromAnyPointSquared = Float(0.0)
        
        for sampleIndex in 0..<sampleCount {
            let x = sampleX[sampleIndex]
            let y = sampleY[sampleIndex]
            
            var smallestDistanceFromAnyLineSegmentSquared = Float(100_000_000.0)
            
            for testSegmentIndex in 0..<testSegmentCount {
                let testSegment = testSegments[testSegmentIndex]
                let distanceSquared = testSegment.distanceSquaredToClosestPoint(x, y)
                if distanceSquared < smallestDistanceFromAnyLineSegmentSquared {
                    smallestDistanceFromAnyLineSegmentSquared = distanceSquared
                }
            }
            
            if smallestDistanceFromAnyLineSegmentSquared > greatestDistanceFromAnyPointSquared {
                greatestDistanceFromAnyPointSquared = smallestDistanceFromAnyLineSegmentSquared
            }
        }
        
        if greatestDistanceFromAnyPointSquared < toleranceSquared {
            print("We can remove at \(zipperPouchIndex) => YES (\(greatestDistanceFromAnyPointSquared))")
            currentZipperPouch.numberOfCombinedZipperPouches += nextZipperPouch.numberOfCombinedZipperPouches
            SplineReducer3ZipperPouch.transferAllSegments(from: nextZipperPouch,
                                                          to: currentZipperPouch)
            removeZipperPouch(nextZipperPouchIndex)
            
            return true
        } else {
            print("We can remove at \(zipperPouchIndex) => NO (\(greatestDistanceFromAnyPointSquared))")
            return false
        }
    }
    
    func reduceWithoutCurves(inputSpline: ManualSpline,
                             outputSpline: ManualSpline,
                             attemptCountA: Int,
                             attemptCountB: Int,
                             attemptCountC: Int,
                             numberOfSamplesAtEachControlPoint: Int,
                             toleranceA: Float,
                             toleranceB: Float,
                             toleranceC: Float) {
        
        purgeZipperPouches()
        
        purgeSegments()
        purgeHealedSegments()
        
        read(inputSpline: inputSpline,
             numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        
        let toleranceASquared = toleranceA * toleranceA
        let toleranceBSquared = toleranceB * toleranceB
        let toleranceCSquared = toleranceC * toleranceC
        
        for attemptIndex in 0..<attemptCountA {
            if zipperPouchCount <= 3 {
                break
            }
            
            // On each attempt, we will try all the indices...
            
            let startIndex = Int.random(in: 0..<zipperPouchCount)
            var tryIndex = startIndex
            var isSuccessful = false
            
            while tryIndex < zipperPouchCount && !isSuccessful {
                if attemptToReduce(inputSpline: inputSpline,
                                   zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceASquared) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            tryIndex = 0
            while tryIndex < startIndex && !isSuccessful {
                if attemptToReduce(inputSpline: inputSpline,
                                   zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceASquared) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            if isSuccessful == false {
                break
            }
        }
        
        for attemptIndex in 0..<attemptCountB {
            if zipperPouchCount <= 3 {
                break
            }
            
            // On each attempt, we will try all the indices...
            
            let startIndex = Int.random(in: 0..<zipperPouchCount)
            var tryIndex = startIndex
            var isSuccessful = false
            
            while tryIndex < zipperPouchCount && !isSuccessful {
                if attemptToReduce(inputSpline: inputSpline,
                                   zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceBSquared) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            tryIndex = 0
            while tryIndex < startIndex && !isSuccessful {
                if attemptToReduce(inputSpline: inputSpline,
                                   zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceBSquared) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            if isSuccessful == false {
                break
            }
        }
        
        
        for attemptIndex in 0..<attemptCountC {
            if zipperPouchCount <= 3 {
                break
            }
            
            // On each attempt, we will try all the indices...
            
            let startIndex = Int.random(in: 0..<zipperPouchCount)
            var tryIndex = startIndex
            var isSuccessful = false
            
            while tryIndex < zipperPouchCount && !isSuccessful {
                if attemptToReduce(inputSpline: inputSpline,
                                   zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceCSquared) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            tryIndex = 0
            while tryIndex < startIndex && !isSuccessful {
                if attemptToReduce(inputSpline: inputSpline,
                                   zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceCSquared) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            if isSuccessful == false {
                break
            }
        }
        
        
        
        
        
        
        outputSpline.removeAll(keepingCapacity: true)
        for zipperPouchIndex in 0..<zipperPouchCount {
            let zipperPouch = zipperPouches[zipperPouchIndex]
            outputSpline.addControlPoint(zipperPouch.x, zipperPouch.y)
        }
        outputSpline.solve(closed: inputSpline.closed)
        
        
        
        for zipperPouchIndex in 0..<zipperPouchCount {
            let zipperPouch = zipperPouches[zipperPouchIndex]
            zipperPouch.purgeHealedSegments()
            
            let numberOfPointsToCheck = zipperPouch.numberOfCombinedZipperPouches * numberOfSamplesAtEachControlPoint
            
            
            var prevX = outputSpline.getX(index: zipperPouchIndex, percent: 0.0)
            var prevY = outputSpline.getY(index: zipperPouchIndex, percent: 0.0)
            
            var pointIndexA = 1
            while pointIndexA <= numberOfPointsToCheck {
                let percent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x = outputSpline.getX(index: zipperPouchIndex, percent: percent)
                let y = outputSpline.getY(index: zipperPouchIndex, percent: percent)
                
                let segment = SplineReducer3PartsFactory.shared.withdrawSegment()
                
                if pointIndexA == 1 {
                    segment.isFlagged = true
                } else {
                    segment.isFlagged = false
                }
                
                zipperPouch.addHealedSegment(segment)
                
                segment.x1 = prevX
                segment.y1 = prevY
                
                segment.x2 = x
                segment.y2 = y
                
                prevX = x
                prevY = y
                
                pointIndexA += 1
            }
            
            
        }
        
        
    }
    
    /*
    private func populateWeightPointsWithTest(controlPointBack1: SplineReducer3ControlPoint,
                                              controlPointCurrent: SplineReducer3ControlPoint,
                                              controlPointForward1: SplineReducer3ControlPoint,
                                              controlPointForward2: SplineReducer3ControlPoint) {
        
                                              
        currentControlPoint: SplineReducer3ControlPoint,
                                              nextControlPoint: SplineReducer3ControlPoint,
                                              numberOfPoints: Int) {
        purgeWeightPoints()
        
        let firstWeightPoint = SplineReducer3PartsFactory.shared.withdrawWeightPoint()
        firstWeightPoint.x = currentControlPoint.x
        firstWeightPoint.y = currentControlPoint.y
        addWeightPoint(firstWeightPoint)
        
        var pointIndexA = 1
        while pointIndexA < numberOfPoints {
            let percent = Float(pointIndexA) / Float(numberOfPoints)
            let x = currentControlPoint.getTestX(percent: percent)
            let y = currentControlPoint.getTestY(percent: percent)
            let weightPoint = SplineReducer3PartsFactory.shared.withdrawWeightPoint()
            weightPoint.x = x
            weightPoint.y = y
            addWeightPoint(weightPoint)
            pointIndexA += 1
        }
        
        let lastWeightPoint = SplineReducer3PartsFactory.shared.withdrawWeightPoint()
        lastWeightPoint.x = nextControlPoint.x
        lastWeightPoint.y = nextControlPoint.y
        addWeightPoint(lastWeightPoint)
    }
    */
    
    private func isSamplePointListComplex() -> Bool {
        
        if weightPointCount > 3 {
            
            var seekIndex = 0
            let seekCeiling = (weightPointCount - 2)
            let checkCeiling = (weightPointCount - 1)
            
            while seekIndex < seekCeiling {
                
                // we check if
                // seekIndex, seekIndex + 1
                // collide with
                // seekIndex + 2...end-1
                // seekIndex + 3...end
                
                let l1_x1 = weightPoints[seekIndex].x
                let l1_y1 = weightPoints[seekIndex].y
                let l1_x2 = weightPoints[seekIndex + 1].x
                let l1_y2 = weightPoints[seekIndex + 1].y
                var checkIndex = seekIndex + 2
                while checkIndex < checkCeiling {
                    let l2_x1 = weightPoints[checkIndex].x
                    let l2_y1 = weightPoints[checkIndex].y
                    let l2_x2 = weightPoints[checkIndex + 1].x
                    let l2_y2 = weightPoints[checkIndex + 1].y
                    if Math.lineSegmentIntersectsLineSegment(line1Point1X: l1_x1,
                                                             line1Point1Y: l1_y1,
                                                             line1Point2X: l1_x2,
                                                             line1Point2Y: l1_y2,
                                                             line2Point1X: l2_x1,
                                                             line2Point1Y: l2_y1,
                                                             line2Point2X: l2_x2,
                                                             line2Point2Y: l2_y2) {
                        return true
                    }
                    
                    checkIndex += 1
                }
                seekIndex += 1
            }
        }
        return false
    }
    
    private func read(inputSpline: ManualSpline,
                      numberOfSamplesAtEachControlPoint: Int) {
        
        if inputSpline.maxIndex <= 2 { return }
        
        // We follow "G.I.G.O. (Garbage In Garbage Out)
        // Action Plan for Results
        
        for splineIndex in 0..<inputSpline.count {
            let zipperPouch = SplineReducer3PartsFactory.shared.withdrawZipperPouch()
            addZipperPouch(zipperPouch)
            zipperPouch.x = inputSpline._x[splineIndex]
            zipperPouch.y = inputSpline._y[splineIndex]
        }
        
        if zipperPouchCount <= 3 {
            return
        }
        
        let sampleCount1 = (numberOfSamplesAtEachControlPoint - 1)
        let sampleCount1f = Float(sampleCount1)
        

        for zipperPouchIndex in 0..<zipperPouchCount {
            let zipperPouch = zipperPouches[zipperPouchIndex]
            
            
            sampleCount = 0
            for percentIndex in 0..<numberOfSamplesAtEachControlPoint {
                let percent = Float(percentIndex) / sampleCount1f
                let x = inputSpline.getX(index: zipperPouchIndex, percent: percent)
                let y = inputSpline.getY(index: zipperPouchIndex, percent: percent)
                addPointSample(x: x, y: y)
            }
            
            zipperPouch.numberOfCombinedZipperPouches = 1
            
            var sampleIndex = 1
            var previousX = sampleX[0]
            var previousY = sampleY[0]
            
            while sampleIndex < sampleCount {
                let currentX = sampleX[sampleIndex]
                let currentY = sampleY[sampleIndex]
                
                let segment = SplineReducer3PartsFactory.shared.withdrawSegment()
                
                segment.isFlagged = false
                
                zipperPouch.addSegment(segment)
                
                addSegment(segment)
                
                segment.x1 = previousX
                segment.y1 = previousY
                
                segment.x2 = currentX
                segment.y2 = currentY
                
                segment.precompute()
                
                previousX = currentX
                previousY = currentY
                
                sampleIndex += 1
            }
        }
    }
    
    func addPointSample(x: Float, y: Float) {
        if sampleCount >= sampleCapacity {
            reserveCapacitySample(minimumCapacity: sampleCount + (sampleCount >> 1) + 1)
        }
        sampleX[sampleCount] = x
        sampleY[sampleCount] = y
        sampleCount += 1
    }
    
    private func reserveCapacitySample(minimumCapacity: Int) {
        if minimumCapacity > sampleCapacity {
            sampleX.reserveCapacity(minimumCapacity)
            sampleY.reserveCapacity(minimumCapacity)
            while sampleX.count < minimumCapacity {
                sampleX.append(0.0)
            }
            while sampleY.count < minimumCapacity {
                sampleY.append(0.0)
            }
            sampleCapacity = minimumCapacity
        }
    }
}
