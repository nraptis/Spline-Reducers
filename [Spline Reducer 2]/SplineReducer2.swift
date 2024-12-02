//
//  SplineReducer2.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer2 {
    
    
    // 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5
    static let magnitudeFactorMin = Float(1.0)
    static let magnitudeFactorMax = Float(2.5)
    static let magnitudeTestSteps = 7
    
    let splineReducerSegmentBucket = SplineReducer2SegmentBucket()
    
    var segments = [SplineReducer2Segment]()
    var segmentCount = 0
    
    var testSegments = [SplineReducer2Segment]()
    var testSegmentCount = 0
    
    var controlPoints = [SplineReducer2ControlPoint]()
    var controlPointCount = 0
    
    var zipperPouches = [SplineReducer2ZipperPouch]()
    var zipperPouchCount = 0
    
    private var sampleCount = 0
    private var sampleCapacity = 0
    private var sampleX = [Float]()
    private var sampleY = [Float]()
    
    func attemptToReduce(zipperPouchIndex: Int,
                         numberOfSamplesAtEachControlPoint: Int,
                         toleranceSquared: Float) -> Bool {
        
        var nextZipperPouchIndex = zipperPouchIndex + 1
        if nextZipperPouchIndex == zipperPouchCount {
            nextZipperPouchIndex = 0
        }
        
        let currentZipperPouch = zipperPouches[zipperPouchIndex]
        let nextZipperPouch = zipperPouches[nextZipperPouchIndex]
        
        guard let currentControlPoint = currentZipperPouch.currentControlPoint else {
            print("FATAL A: currentZipperPouch.currentControlPoint should b set...")
            return false
        }
        
        guard let nextControlPoint = nextZipperPouch.nextControlPoint else {
            print("FATAL A: nextZipperPouch.nextControlPoint should b set...")
            return false
        }
        
        testSegmentCount = 0
        
        for segmentIndex in 0..<currentZipperPouch.segmentCount {
            let segment = currentZipperPouch.segments[segmentIndex]
            addTestSegment(segment)
        }
        
        for segmentIndex in 0..<nextZipperPouch.segmentCount {
            let segment = nextZipperPouch.segments[segmentIndex]
            addTestSegment(segment)
        }
        
        for segmentIndex in 0..<testSegmentCount {
            let segment = testSegments[segmentIndex]
            segment.isFlagged = true
        }
        
        let numberOfCombinedPouches = currentZipperPouch.numberOfCombinedZipperPouches + nextZipperPouch.numberOfCombinedZipperPouches
        let numberOfPointsToCheck = numberOfCombinedPouches * numberOfSamplesAtEachControlPoint
        
        // We concerned with next in tan...
        let nextInTanMin = nextControlPoint.tanMagnitudeInOriginal * Self.magnitudeFactorMin
        let nextInTanMax = nextControlPoint.tanMagnitudeInOriginal * Self.magnitudeFactorMax
        
        // We concerned with current out tan...
        let currentOutTanMin = nextControlPoint.tanMagnitudeOutOriginal * Self.magnitudeFactorMin
        let currentOutTanMax = nextControlPoint.tanMagnitudeOutOriginal * Self.magnitudeFactorMax
        
        var bestDistanceSquared = Float(100_000_000.0)
        
        var bestInTan = Float(0.0)
        var bestOutTan = Float(0.0)
        
        for currentControlIndex in 0..<Self.magnitudeTestSteps {
            let currentControlPercent = Float(currentControlIndex) / Float(Self.magnitudeTestSteps - 1)
            let currentOutTan = currentOutTanMin + (currentOutTanMax - currentOutTanMin) * currentControlPercent
            
            currentControlPoint.testOutTanX = -currentControlPoint.tanDirX * currentOutTan
            currentControlPoint.testOutTanY = -currentControlPoint.tanDirY * currentOutTan
            
            for nextControlIndex in 0..<Self.magnitudeTestSteps {
                let nextControlPercent = Float(nextControlIndex) / Float(Self.magnitudeTestSteps - 1)
                let nextInTan = nextInTanMin + (nextInTanMax - nextInTanMin) * nextControlPercent
                
                nextControlPoint.testInTanX = nextControlPoint.tanDirX * nextInTan
                nextControlPoint.testInTanY = nextControlPoint.tanDirY * nextInTan
                
                currentControlPoint.computeTest(nextControlPoint: nextControlPoint)
                
                var maxDistanceSquaredFromAnyPointToMinAtAnySegment = Float(0.0)
                
                populateWeightPointsWithTest(currentControlPoint: currentControlPoint,
                                             nextControlPoint: nextControlPoint,
                                             numberOfPoints: numberOfPointsToCheck)
                
                if isSamplePointListComplex() {
                    break
                }
                
                var pointIndexB = 1
                while pointIndexB < sampleCount {
                    let x = sampleX[pointIndexB]
                    let y = sampleY[pointIndexB]
                    var minDistanceSquaredToAnySegment = Float(100_000_000.0)
                    for segmentIndex in 0..<testSegmentCount {
                        let segment = testSegments[segmentIndex]
                        let distanceSquared = segment.distanceSquaredToClosestPoint(x, y)
                        if distanceSquared < minDistanceSquaredToAnySegment {
                            minDistanceSquaredToAnySegment = distanceSquared
                        }
                    }
                    if minDistanceSquaredToAnySegment > maxDistanceSquaredFromAnyPointToMinAtAnySegment {
                        maxDistanceSquaredFromAnyPointToMinAtAnySegment = minDistanceSquaredToAnySegment
                    }
                    pointIndexB += 1
                }
                
                
                if maxDistanceSquaredFromAnyPointToMinAtAnySegment < bestDistanceSquared {
                    bestDistanceSquared = maxDistanceSquaredFromAnyPointToMinAtAnySegment
                    
                    bestInTan = nextInTan
                    bestOutTan = currentOutTan
                    
                    //bestInPercent = nextControlPercent
                    //bestOutPercent = currentControlPercent
                }
                
                //print("coefs: \(currentControlPoint.coefXC), \(currentControlPoint.coefXD), maxDistanceFromAnyPointToMinAtAnySegment = \(sqrtf(maxDistanceFromAnyPointToMinAtAnySegment))")
                
            }
            
            //bestDistance
            
         
        }

        if bestDistanceSquared < toleranceSquared {
            
            currentControlPoint.outTanX = -currentControlPoint.tanDirX * bestOutTan
            currentControlPoint.outTanY = -currentControlPoint.tanDirY * bestOutTan
            
            nextControlPoint.inTanX = nextControlPoint.tanDirX * bestInTan
            nextControlPoint.inTanY = nextControlPoint.tanDirY * bestInTan
            
            
            currentZipperPouch.nextControlPoint = nextZipperPouch.nextControlPoint
            
            currentZipperPouch.numberOfCombinedZipperPouches += nextZipperPouch.numberOfCombinedZipperPouches
            
            SplineReducer2ZipperPouch.transferAllSegments(from: nextZipperPouch,
                                                          to: currentZipperPouch)
            
            removeZipperPouch(nextZipperPouchIndex)
            
            return true
            
            /*
            currentControlPoint.compute(nextControlPoint: nextControlPoint)
            
            var pointIndexA = 1
            while pointIndexA <= numberOfPointsToCheck {
                
                let previousPercent = Float(pointIndexA - 1) / Float(numberOfPointsToCheck)
                let currentPercent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x1 = currentControlPoint.getX(percent: previousPercent)
                let y1 = currentControlPoint.getY(percent: previousPercent)
                
                let x2 = currentControlPoint.getX(percent: currentPercent)
                let y2 = currentControlPoint.getY(percent: currentPercent)
                
                print("x1 = \(x1), y1 = \(y1), p1 = \(previousPercent)")
                print("x2 = \(x2), y2 = \(y2), p2 = \(currentPercent)")
                
                
                let segment = SplineReducer2PartsFactory.shared.withdrawSegment()
                
                addHealedSegment(segment)
                
                segment.x1 = x1
                segment.y1 = y1
                
                segment.x2 = x2
                segment.y2 = y2
                
                segment.precompute()
                
                pointIndexA += 1
            }
            */
            
        } else {
            return false
        }
    }
    
    func reduceWithCurves(inputSpline: ManualSpline,
                          outputSpline: ManualSpline,
                          attemptCountA: Int,
                          attemptCountB: Int,
                          attemptCountC: Int,
                          numberOfSamplesAtEachControlPoint: Int,
                          toleranceA: Float,
                          toleranceB: Float,
                          toleranceC: Float) {
        
        purgeZipperPouches()
        purgeControlPoints()
        purgeSegments()
        
        read(inputSpline: inputSpline,
             numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        
        let toleranceSquaredA = toleranceA * toleranceA
        let toleranceSquaredB = toleranceB * toleranceB
        let toleranceSquaredC = toleranceB * toleranceC
        
        
        for attemptIndex in 0..<attemptCountA {
            if zipperPouchCount <= 3 {
                break
            }
            
            // On each attempt, we will try all the indices...
            
            let startIndex = Int.random(in: 0..<zipperPouchCount)
            var tryIndex = startIndex
            var isSuccessful = false
            
            while tryIndex < zipperPouchCount && !isSuccessful {
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSquaredA) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            tryIndex = 0
            while tryIndex < startIndex && !isSuccessful {
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSquaredA) {
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
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSquaredB) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            tryIndex = 0
            while tryIndex < startIndex && !isSuccessful {
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSquaredB) {
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
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSquaredC) {
                    isSuccessful = true
                }
                tryIndex += 1
            }
            
            tryIndex = 0
            while tryIndex < startIndex && !isSuccessful {
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSquaredC) {
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
            
            guard let currentControlPoint = zipperPouch.currentControlPoint else {
                print("FATAL B: currentZipperPouch.currentControlPoint should b set...")
                return
            }
            
            outputSpline.addControlPoint(currentControlPoint.x,
                                         currentControlPoint.y)
            
            
        }
        
        for zipperPouchIndex in 0..<zipperPouchCount {
            
            
            let zipperPouch = zipperPouches[zipperPouchIndex]
            
            guard let currentControlPoint = zipperPouch.currentControlPoint else {
                print("FATAL B: currentZipperPouch.currentControlPoint should b set...")
                return
            }
            
            outputSpline.enableManualControlTan(at: zipperPouchIndex,
                                                inTanX: currentControlPoint.inTanX,
                                                inTanY: currentControlPoint.inTanY,
                                                outTanX: currentControlPoint.outTanX,
                                                outTanY: currentControlPoint.outTanY)
        }
        
        outputSpline.solve(closed: inputSpline.closed)
        
    }
    
    private func populateWeightPointsWithTest(currentControlPoint: SplineReducer2ControlPoint,
                                              nextControlPoint: SplineReducer2ControlPoint,
                                              numberOfPoints: Int) {
        
        sampleCount = 0
        
        addPointSample(x: currentControlPoint.x,
                       y: currentControlPoint.y)
        
        var pointIndexA = 1
        while pointIndexA < numberOfPoints {
            let percent = Float(pointIndexA) / Float(numberOfPoints)
            let x = currentControlPoint.getTestX(percent: percent)
            let y = currentControlPoint.getTestY(percent: percent)
            addPointSample(x: x,
                           y: y)
            
            pointIndexA += 1
        }
        
        addPointSample(x: nextControlPoint.x,
                       y: nextControlPoint.y)
        
    }
    
    private func isSamplePointListComplex() -> Bool {
        
        if sampleCount > 3 {
            
            var seekIndex = 0
            let seekCeiling = (sampleCount - 2)
            let checkCeiling = (sampleCount - 1)
            
            while seekIndex < seekCeiling {
                
                // we check if
                // seekIndex, seekIndex + 1
                // collide with
                // seekIndex + 2...end-1
                // seekIndex + 3...end
                
                let l1_x1 = sampleX[seekIndex]
                let l1_y1 = sampleY[seekIndex]
                let l1_x2 = sampleX[seekIndex + 1]
                let l1_y2 = sampleY[seekIndex + 1]
                var checkIndex = seekIndex + 2
                while checkIndex < checkCeiling {
                    let l2_x1 = sampleX[checkIndex]
                    let l2_y1 = sampleY[checkIndex]
                    let l2_x2 = sampleX[checkIndex + 1]
                    let l2_y2 = sampleY[checkIndex + 1]
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
        
        // We follow "G.I.G.O. (Garbage In Garbage Out)
        // Action Plan for Results
        
        let maxIndex = inputSpline.maxIndex
        for splineIndex in 0..<maxIndex {
            
            let controlPoint = SplineReducer2PartsFactory.shared.withdrawControlPoint()
            addControlPoint(controlPoint)
            
            controlPoint.x = inputSpline._x[splineIndex]
            controlPoint.y = inputSpline._y[splineIndex]
            controlPoint.inTanX = inputSpline.inTanX[splineIndex]
            controlPoint.inTanY = inputSpline.inTanY[splineIndex]
            controlPoint.outTanX = inputSpline.outTanX[splineIndex]
            controlPoint.outTanY = inputSpline.outTanY[splineIndex]
        }
        
        
        
        if controlPointCount <= 0 {
            return
        }
        
        for controlPointIndex in 0..<controlPointCount {
            let controlPoint = controlPoints[controlPointIndex]
            let inTanX = controlPoint.inTanX
            let inTanY = controlPoint.inTanY
            let distanceSquared = inTanX * inTanX + inTanY * inTanY
            if distanceSquared > Math.epsilon {
                let distance = sqrtf(distanceSquared)
                controlPoint.tanDirX = inTanX / distance
                controlPoint.tanDirY = inTanY / distance
                controlPoint.tanMagnitudeInOriginal = distance
                controlPoint.tanMagnitudeOutOriginal = distance
                
            } else {
                controlPoint.tanDirX = 0.0
                controlPoint.tanDirY = -1.0
                controlPoint.tanMagnitudeInOriginal = 0.0
                controlPoint.tanMagnitudeOutOriginal = 0.0
            }
        }
        
        for controlPointIndex in 0..<controlPointCount {
            let controlPoint = controlPoints[controlPointIndex]
            var nextControlPointIndex = (controlPointIndex + 1)
            if nextControlPointIndex >= controlPointCount {
                nextControlPointIndex = 0
            }
            
            let nextControlPoint = controlPoints[nextControlPointIndex]
            controlPoint.compute(nextControlPoint: nextControlPoint)
        }
        
        let sampleCount1 = (numberOfSamplesAtEachControlPoint - 1)
        let sampleCount1f = Float(sampleCount1)
        

        for controlPointIndex in 0..<controlPointCount {
            let controlPoint = controlPoints[controlPointIndex]
            var nextControlPointIndex = (controlPointIndex + 1)
            if nextControlPointIndex >= controlPointCount {
                nextControlPointIndex = 0
            }
            let nextControlPoint = controlPoints[nextControlPointIndex]
            
            sampleCount = 0
            for percentIndex in 0..<numberOfSamplesAtEachControlPoint {
                let percent = Float(percentIndex) / sampleCount1f
                let x = controlPoint.getX(percent: percent)
                let y = controlPoint.getY(percent: percent)
                addPointSample(x: x, y: y)
            }
            
            let zipperPouch = SplineReducer2PartsFactory.shared.withdrawZipperPouch()
            
            zipperPouch.numberOfCombinedZipperPouches = 1
            zipperPouch.currentControlPoint = controlPoint
            zipperPouch.nextControlPoint = nextControlPoint
            
            addZipperPouch(zipperPouch)
            
            var sampleIndex = 1
            var previousX = sampleX[0]
            var previousY = sampleY[0]
            
            while sampleIndex < sampleCount {
                let currentX = sampleX[sampleIndex]
                let currentY = sampleY[sampleIndex]
                
                let segment = SplineReducer2PartsFactory.shared.withdrawSegment()
                
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
