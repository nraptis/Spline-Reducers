//
//  SplineReducer4.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation


// So, in this case, we will need
// 6 points at least

class SplineReducer4 {
    
    
    // 1.0, 1.25, 1.5, 1.75, 2.0
    static let magnitudeFactorMin = Float(1.0)
    static let magnitudeFactorMax = Float(2.0)
    static let magnitudeTestSteps = 5
    
    static let rotationWiggleSpan = Math.pi_4
    static let rotationWiggleSteps = 24
    
    
    var healedSegments = [SplineReducer4Segment]()
    var healedSegmentCount = 0
    
    var segments = [SplineReducer4Segment]()
    var segmentCount = 0
    
    var testSegmentsA = [SplineReducer4Segment]()
    var testSegmentCountA = 0
    
    
    var testSegmentsB = [SplineReducer4Segment]()
    var testSegmentCountB = 0
    
    
    var controlPoints = [SplineReducer4ControlPoint]()
    var controlPointCount = 0
    
    var zipperPouches = [SplineReducer4ZipperPouch]()
    var zipperPouchCount = 0
    
    private var sampleCountA = 0
    private var sampleCapacityA = 0
    private var sampleXA = [Float]()
    private var sampleYA = [Float]()
    
    
    private var sampleCountB = 0
    private var sampleCapacityB = 0
    private var sampleXB = [Float]()
    private var sampleYB = [Float]()
    
    
    // The idea here is zipperPouchIndex could be anything,
    // but zipperPouchIndex + 1 is a mono-point, not yet combined...
    
    // this will work best always starting from 0...
    
    func attemptToReduce(zipperPouchIndex: Int,
                         numberOfSamplesAtEachControlPoint: Int) -> Bool {
        
        if zipperPouchIndex < 0 {
            return false
        }
        if zipperPouchIndex >= zipperPouchCount {
            return false
        }
        
        var previousZipperPouchIndex = zipperPouchIndex - 1
        if previousZipperPouchIndex == -1 {
            previousZipperPouchIndex = zipperPouchCount - 1
        }
        
        var nextZipperPouchIndex = zipperPouchIndex + 1
        if nextZipperPouchIndex == zipperPouchCount {
            nextZipperPouchIndex = 0
        }
        
        let previousZipperPouch = zipperPouches[previousZipperPouchIndex]
        let currentZipperPouch = zipperPouches[zipperPouchIndex]
        let nextZipperPouch = zipperPouches[nextZipperPouchIndex]
        
        guard let previousControlPoint = previousZipperPouch.currentControlPoint else {
            print("FATAL A: previousZipperPouch.currentControlPoint should b set...")
            return false
        }
        
        guard let currentControlPoint = currentZipperPouch.currentControlPoint else {
            print("FATAL A: currentZipperPouch.currentControlPoint should b set...")
            return false
        }
        
        guard let nextControlPoint = nextZipperPouch.nextControlPoint else {
            print("FATAL A: nextZipperPouch.nextControlPoint should b set...")
            return false
        }
        
        if currentControlPoint.isValid == false {
            print("FATAL A: currentControlPoint.isValid should b tru...")
            return false
        }
        
        if nextControlPoint.isValid == false {
            print("FATAL A: nextControlPoint.isValid should b tru...")
            return false
        }
        
        testSegmentCountA = 0
        
        for segmentIndex in 0..<previousZipperPouch.segmentCount {
            let segment = previousZipperPouch.segments[segmentIndex]
            addTestSegmentA(segment)
        }
        
        testSegmentCountB = 0
        
        for segmentIndex in 0..<currentZipperPouch.segmentCount {
            let segment = currentZipperPouch.segments[segmentIndex]
            addTestSegmentB(segment)
        }
        
        for segmentIndex in 0..<nextZipperPouch.segmentCount {
            let segment = nextZipperPouch.segments[segmentIndex]
            addTestSegmentB(segment)
        }
        
        for segmentIndex in 0..<testSegmentCountA {
            let segment = testSegmentsA[segmentIndex]
            segment.isFlagged = true
        }
        
        for segmentIndex in 0..<testSegmentCountB {
            let segment = testSegmentsB[segmentIndex]
            segment.isFlagged = false
        }
        
        let numberOfCombinedPouchesPrevious = previousZipperPouch.numberOfCombinedZipperPouches
        let numberOfPointsToCheckPrevious = numberOfCombinedPouchesPrevious * numberOfSamplesAtEachControlPoint
        
        let numberOfCombinedPouchesCurrent = currentZipperPouch.numberOfCombinedZipperPouches + nextZipperPouch.numberOfCombinedZipperPouches
        let numberOfPointsToCheckCurrent = numberOfCombinedPouchesCurrent * numberOfSamplesAtEachControlPoint
        
        
        let currentRotationMin = currentControlPoint.tanDirection - Self.rotationWiggleSpan
        let currentRotationMax = currentControlPoint.tanDirection + Self.rotationWiggleSpan
        
        // We concerned with next in tan...
        let nextInTanMin = nextControlPoint.tanMagnitudeInOriginal * Self.magnitudeFactorMin
        let nextInTanMax = nextControlPoint.tanMagnitudeInOriginal * Self.magnitudeFactorMax
        
        // We concerned with current out tan...
        let currentOutTanMin = nextControlPoint.tanMagnitudeOutOriginal * Self.magnitudeFactorMin
        let currentOutTanMax = nextControlPoint.tanMagnitudeOutOriginal * Self.magnitudeFactorMax
        
        // We concerned with current in tan...
        let currentInTanMin = nextControlPoint.tanMagnitudeInOriginal * Self.magnitudeFactorMin
        let currentInTanMax = nextControlPoint.tanMagnitudeInOriginal * Self.magnitudeFactorMax
        
        
        var bestDistanceSquared = Float(100_000_000.0)
        
        var bestInTan = Float(0.0)
        var bestCurrentOutTan = Float(0.0)
        var bestCurrentInTan = Float(0.0)
        
        var bestCurrentRotation = Float(0.0)
        var isAnyReadingValid = false
        
        
        for currentRotationIndex in 0..<Self.rotationWiggleSteps {
            let currentRotationPercent = Float(currentRotationIndex) / Float(Self.rotationWiggleSteps - 1)
            let currentRotation = currentRotationMin + (currentRotationMax - currentRotationMin) * currentRotationPercent
            let currentTanDirOutX = sinf(currentRotation)
            let currentTanDirOutY = -cosf(currentRotation)
            let currentTanDirInX = -currentTanDirOutX
            let currentTanDirInY = -currentTanDirOutY
            
            for currentInControlIndex in 0..<Self.magnitudeTestSteps {
                let currentInControlPercent = Float(currentInControlIndex) / Float(Self.magnitudeTestSteps - 1)
                let currentInTan = currentInTanMin + (currentInTanMax - currentInTanMin) * currentInControlPercent
                
                currentControlPoint.testInTanX = currentTanDirInX * currentInTan
                currentControlPoint.testInTanY = currentTanDirInY * currentInTan
                
                previousControlPoint.computeTest(nextControlPoint: currentControlPoint)
                
                for currentOutControlIndex in 0..<Self.magnitudeTestSteps {
                    let currentOutControlPercent = Float(currentOutControlIndex) / Float(Self.magnitudeTestSteps - 1)
                    let currentOutTan = currentOutTanMin + (currentOutTanMax - currentOutTanMin) * currentOutControlPercent
                    
                    currentControlPoint.testOutTanX = currentTanDirOutX * currentOutTan
                    currentControlPoint.testOutTanY = currentTanDirOutY * currentOutTan
                    
                    
                    for nextControlIndex in 0..<Self.magnitudeTestSteps {
                        let nextControlPercent = Float(nextControlIndex) / Float(Self.magnitudeTestSteps - 1)
                        let nextInTan = nextInTanMin + (nextInTanMax - nextInTanMin) * nextControlPercent
                        
                        nextControlPoint.testInTanX = nextControlPoint.inTanDirXOriginal * nextInTan
                        nextControlPoint.testInTanY = nextControlPoint.inTanDirYOriginal * nextInTan
                        
                        currentControlPoint.computeTest(nextControlPoint: nextControlPoint)
                        
                        var maxDistanceSquaredFromAnyPointToMinAtAnySegment = Float(0.0)
                        
                        populateSamplePointsWithTest(previousControlPoint: previousControlPoint,
                                                     currentControlPoint: currentControlPoint,
                                                     nextControlPoint: nextControlPoint,
                                                     numberOfPointsPrevious: numberOfPointsToCheckPrevious,
                                                     numberOfPointsCurrent: numberOfPointsToCheckCurrent)
                        
                        if sampleCountA <= 0 {
                            print("FATAL: Expected sampleCountA >= 0")
                            return false
                        }
                        
                        if sampleCountB <= 0 {
                            print("FATAL: Expected sampleCountA >= 0")
                            return false
                        }
                        
                        if isSamplePointListComplexA() {
                            break
                        }
                        
                        if isSamplePointListComplexB() {
                            break
                        }
                        
                        var pointIndexA = 1
                        while pointIndexA < sampleCountA {
                            let x = sampleXA[pointIndexA]
                            let y = sampleYA[pointIndexA]
                            var minDistanceSquaredToAnySegment = Float(100_000_000.0)
                            for segmentIndex in 0..<testSegmentCountA {
                                let segment = testSegmentsA[segmentIndex]
                                let distanceSquared = segment.distanceSquaredToClosestPoint(x, y)
                                if distanceSquared < minDistanceSquaredToAnySegment {
                                    minDistanceSquaredToAnySegment = distanceSquared
                                }
                            }
                            if minDistanceSquaredToAnySegment > maxDistanceSquaredFromAnyPointToMinAtAnySegment {
                                maxDistanceSquaredFromAnyPointToMinAtAnySegment = minDistanceSquaredToAnySegment
                            }
                            pointIndexA += 1
                        }
                        
                        
                        var pointIndexB = 1
                        while pointIndexB < sampleCountB {
                            let x = sampleXB[pointIndexB]
                            let y = sampleYB[pointIndexB]
                            var minDistanceSquaredToAnySegment = Float(100_000_000.0)
                            for segmentIndex in 0..<testSegmentCountB {
                                let segment = testSegmentsB[segmentIndex]
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
                            bestCurrentOutTan = currentOutTan
                            bestCurrentInTan = currentOutTan
                            
                            bestCurrentRotation = currentRotation
                            isAnyReadingValid = true
                        }
                        
                    }
                }
            }
        }
        
        if isAnyReadingValid {
            
            let currentTanDirOutX = sinf(bestCurrentRotation)
            let currentTanDirOutY = -cosf(bestCurrentRotation)
            let currentTanDirInX = -currentTanDirOutX
            let currentTanDirInY = -currentTanDirOutY
            
            currentControlPoint.tanDirection = bestCurrentRotation
            
            currentControlPoint.outTanX = currentTanDirOutX * bestCurrentOutTan
            currentControlPoint.outTanY = currentTanDirOutY * bestCurrentOutTan
            currentControlPoint.inTanX = currentTanDirInX * bestCurrentInTan
            currentControlPoint.inTanY = currentTanDirInY * bestCurrentInTan
            
            nextControlPoint.inTanX = nextControlPoint.inTanDirXOriginal * bestInTan
            nextControlPoint.inTanY = nextControlPoint.inTanDirYOriginal * bestInTan
            
            currentZipperPouch.nextControlPoint = nextZipperPouch.nextControlPoint
            
            currentZipperPouch.numberOfCombinedZipperPouches += nextZipperPouch.numberOfCombinedZipperPouches
            
            SplineReducer4ZipperPouch.transferAllSegments(from: nextZipperPouch,
                                                          to: currentZipperPouch)
            
            removeZipperPouch(nextZipperPouchIndex)
            
            return true
        } else {
            
            let currentTanDirOutX = sinf(currentControlPoint.tanDirectionOriginal)
            let currentTanDirOutY = -cosf(currentControlPoint.tanDirectionOriginal)
            let currentTanDirInX = -currentTanDirOutX
            let currentTanDirInY = -currentTanDirOutY
            
            currentControlPoint.outTanX = currentTanDirOutX * currentControlPoint.tanMagnitudeOutOriginal
            currentControlPoint.outTanY = currentTanDirOutY * currentControlPoint.tanMagnitudeOutOriginal
            currentControlPoint.inTanX = currentTanDirInX * currentControlPoint.tanMagnitudeInOriginal
            currentControlPoint.inTanY = currentTanDirInY * currentControlPoint.tanMagnitudeInOriginal
            
            nextControlPoint.inTanX = nextControlPoint.inTanDirXOriginal * nextControlPoint.tanMagnitudeInOriginal
            nextControlPoint.inTanY = nextControlPoint.inTanDirYOriginal * nextControlPoint.tanMagnitudeInOriginal
            
            return false
        }
    }
    
    func reduce(inputSpline: ManualSpline,
                outputSpline: ManualSpline,
                numberOfSamplesAtEachControlPoint: Int) {
        
        
        purgeZipperPouches()
        purgeControlPoints()
        purgeSegments()
        
        read(inputSpline: inputSpline,
             numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        

        
        
        /*
        _ = attemptToReduce(zipperPouchIndex: 0,
                            numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        
        _ = attemptToReduce(zipperPouchIndex: 4,
                            numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        
        _ = attemptToReduce(zipperPouchIndex: 8,
                            numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        
        
        _ = attemptToReduce(zipperPouchIndex: 18,
                            numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        
        */
        
         
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
        
        for zipperPouchIndex in 0..<zipperPouchCount {
            
            var nextZipperPouchIndex = zipperPouchIndex + 1
            if nextZipperPouchIndex == zipperPouchCount {
                nextZipperPouchIndex = 0
            }
            
            let currentZipperPouch = zipperPouches[zipperPouchIndex]
            let nextZipperPouch = zipperPouches[nextZipperPouchIndex]
            
            currentZipperPouch.purgeHealedSegments()
            
            guard let currentControlPoint = currentZipperPouch.currentControlPoint else {
                print("FATAL ABC: currentZipperPouch.currentControlPoint should b set...")
                return
            }
            
            guard let nextControlPoint = currentZipperPouch.nextControlPoint else {
                print("FATAL ABC: nextZipperPouch.nextControlPoint should b set...")
                return
            }
            
            let numberOfCombinedPouches = currentZipperPouch.numberOfCombinedZipperPouches + nextZipperPouch.numberOfCombinedZipperPouches
            let numberOfPointsToCheck = numberOfCombinedPouches * numberOfSamplesAtEachControlPoint
            
            currentControlPoint.compute(nextControlPoint: nextControlPoint)
            
            var pointIndexA = 1
            while pointIndexA <= numberOfPointsToCheck {
                
                let previousPercent = Float(pointIndexA - 1) / Float(numberOfPointsToCheck)
                let currentPercent = Float(pointIndexA) / Float(numberOfPointsToCheck)
                
                let x1 = currentControlPoint.getX(percent: previousPercent)
                let y1 = currentControlPoint.getY(percent: previousPercent)
                
                let x2 = currentControlPoint.getX(percent: currentPercent)
                let y2 = currentControlPoint.getY(percent: currentPercent)
                
                //print("@ \(zipperPouchIndex) / \(zipperPouchCount) x1 = \(x1), y1 = \(y1), p1 = \(previousPercent)")
                //print("@ \(zipperPouchIndex) / \(zipperPouchCount) x2 = \(x2), y2 = \(y2), p2 = \(currentPercent)")
                
                let segment = SplineReducer4PartsFactory.shared.withdrawSegment()
                
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
        
        
        /*
        purgeHealedSegments()
        if sampleCountA > 0 {
            var prevX = sampleXA[0]
            var prevY = sampleYA[0]
            
            for sampleIndex in 1..<sampleCountA {
                let x = sampleXA[sampleIndex]
                let y = sampleYA[sampleIndex]
                
                let segment = SplineReducer4PartsFactory.shared.withdrawSegment()

                
                addHealedSegment(segment)
                
                segment.isFlagged = false
                
                segment.x1 = prevX
                segment.y1 = prevY
                
                segment.x2 = x
                segment.y2 = y
                
                segment.precompute()
                
                
                prevX = x
                prevY = y
                
                
            }
            
            
        }
        
        if sampleCountB > 0 {
            var prevX = sampleXB[0]
            var prevY = sampleYB[0]
            
            for sampleIndex in 1..<sampleCountB {
                let x = sampleXB[sampleIndex]
                let y = sampleYB[sampleIndex]
                
                let segment = SplineReducer4PartsFactory.shared.withdrawSegment()

                
                addHealedSegment(segment)
                
                segment.isFlagged = true
                
                segment.x1 = prevX
                segment.y1 = prevY
                
                segment.x2 = x
                segment.y2 = y
                
                segment.precompute()
                
                
                prevX = x
                prevY = y
                
                
            }
            
            
        }
        
        */
        
        outputSpline.solve(closed: inputSpline.closed)
        
    }
    
    private func populateSamplePointsWithTest(previousControlPoint: SplineReducer4ControlPoint,
                                              currentControlPoint: SplineReducer4ControlPoint,
                                              nextControlPoint: SplineReducer4ControlPoint,
                                              numberOfPointsPrevious: Int,
                                              numberOfPointsCurrent: Int) {
        
        sampleCountA = 0
        
        addPointSampleA(x: previousControlPoint.x,
                        y: previousControlPoint.y)
        
        var pointIndex = 1
        while pointIndex < numberOfPointsPrevious {
            let percent = Float(pointIndex) / Float(numberOfPointsPrevious)
            let x = previousControlPoint.getTestX(percent: percent)
            let y = previousControlPoint.getTestY(percent: percent)
            addPointSampleA(x: x,
                            y: y)
            
            pointIndex += 1
        }
        
        addPointSampleA(x: currentControlPoint.x,
                        y: currentControlPoint.y)
        
        
        sampleCountB = 0
        
        
        addPointSampleB(x: currentControlPoint.x,
                        y: currentControlPoint.y)
        
        
        pointIndex = 1
        while pointIndex < numberOfPointsCurrent {
            let percent = Float(pointIndex) / Float(numberOfPointsCurrent)
            let x = currentControlPoint.getTestX(percent: percent)
            let y = currentControlPoint.getTestY(percent: percent)
            addPointSampleB(x: x,
                            y: y)
            
            pointIndex += 1
        }
        
        addPointSampleB(x: nextControlPoint.x,
                        y: nextControlPoint.y)
        
    }
    
    private func isSamplePointListComplexA() -> Bool {
        
        if sampleCountA > 3 {
            
            var seekIndex = 0
            let seekCeiling = (sampleCountA - 2)
            let checkCeiling = (sampleCountA - 1)
            
            while seekIndex < seekCeiling {
                
                // we check if
                // seekIndex, seekIndex + 1
                // collide with
                // seekIndex + 2...end-1
                // seekIndex + 3...end
                
                let l1_x1 = sampleXA[seekIndex]
                let l1_y1 = sampleYA[seekIndex]
                let l1_x2 = sampleXA[seekIndex + 1]
                let l1_y2 = sampleYA[seekIndex + 1]
                var checkIndex = seekIndex + 2
                while checkIndex < checkCeiling {
                    let l2_x1 = sampleXA[checkIndex]
                    let l2_y1 = sampleYA[checkIndex]
                    let l2_x2 = sampleXA[checkIndex + 1]
                    let l2_y2 = sampleYA[checkIndex + 1]
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
    
    private func isSamplePointListComplexB() -> Bool {
        
        if sampleCountB > 3 {
            
            var seekIndex = 0
            let seekCeiling = (sampleCountB - 2)
            let checkCeiling = (sampleCountB - 1)
            
            while seekIndex < seekCeiling {
                
                // we check if
                // seekIndex, seekIndex + 1
                // collide with
                // seekIndex + 2...end-1
                // seekIndex + 3...end
                
                let l1_x1 = sampleXB[seekIndex]
                let l1_y1 = sampleYB[seekIndex]
                let l1_x2 = sampleXB[seekIndex + 1]
                let l1_y2 = sampleYB[seekIndex + 1]
                var checkIndex = seekIndex + 2
                while checkIndex < checkCeiling {
                    let l2_x1 = sampleXB[checkIndex]
                    let l2_y1 = sampleYB[checkIndex]
                    let l2_x2 = sampleXB[checkIndex + 1]
                    let l2_y2 = sampleYB[checkIndex + 1]
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
            
            let controlPoint = SplineReducer4PartsFactory.shared.withdrawControlPoint()
            addControlPoint(controlPoint)
            
            controlPoint.x = inputSpline._x[splineIndex]
            controlPoint.y = inputSpline._y[splineIndex]
            let inTanX = inputSpline.inTanX[splineIndex]
            let inTanY = inputSpline.inTanY[splineIndex]
            let outTanX = inputSpline.outTanX[splineIndex]
            let outTanY = inputSpline.outTanY[splineIndex]
            
            controlPoint.readIn(inTanX: inTanX,
                                inTanY: inTanY,
                                outTanX: outTanX,
                                outTanY: outTanY)
            
        }
        
        if controlPointCount <= 0 {
            return
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
            
            sampleCountA = 0
            for percentIndex in 0..<numberOfSamplesAtEachControlPoint {
                let percent = Float(percentIndex) / sampleCount1f
                let x = controlPoint.getX(percent: percent)
                let y = controlPoint.getY(percent: percent)
                addPointSampleA(x: x, y: y)
            }
            
            let zipperPouch = SplineReducer4PartsFactory.shared.withdrawZipperPouch()
            
            zipperPouch.numberOfCombinedZipperPouches = 1
            zipperPouch.currentControlPoint = controlPoint
            zipperPouch.nextControlPoint = nextControlPoint
            
            addZipperPouch(zipperPouch)
            
            var sampleIndex = 1
            var previousX = sampleXA[0]
            var previousY = sampleYA[0]
            
            while sampleIndex < sampleCountA {
                let currentX = sampleXA[sampleIndex]
                let currentY = sampleYA[sampleIndex]
                
                let segment = SplineReducer4PartsFactory.shared.withdrawSegment()
                
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
    
    func addPointSampleA(x: Float, y: Float) {
        if sampleCountA >= sampleCapacityA {
            reserveCapacitySampleA(minimumCapacity: sampleCountA + (sampleCountA >> 1) + 1)
        }
        sampleXA[sampleCountA] = x
        sampleYA[sampleCountA] = y
        sampleCountA += 1
    }
    
    private func reserveCapacitySampleA(minimumCapacity: Int) {
        if minimumCapacity > sampleCapacityA {
            sampleXA.reserveCapacity(minimumCapacity)
            sampleYA.reserveCapacity(minimumCapacity)
            while sampleXA.count < minimumCapacity {
                sampleXA.append(0.0)
            }
            while sampleYA.count < minimumCapacity {
                sampleYA.append(0.0)
            }
            sampleCapacityA = minimumCapacity
        }
    }
    
    func addPointSampleB(x: Float, y: Float) {
            if sampleCountB >= sampleCapacityB {
                reserveCapacitySampleB(minimumCapacity: sampleCountB + (sampleCountB >> 1) + 1)
            }
            sampleXB[sampleCountB] = x
            sampleYB[sampleCountB] = y
            sampleCountB += 1
        }
        
        private func reserveCapacitySampleB(minimumCapacity: Int) {
            if minimumCapacity > sampleCapacityB {
                sampleXB.reserveCapacity(minimumCapacity)
                sampleYB.reserveCapacity(minimumCapacity)
                while sampleXB.count < minimumCapacity {
                    sampleXB.append(0.0)
                }
                while sampleYB.count < minimumCapacity {
                    sampleYB.append(0.0)
                }
                sampleCapacityB = minimumCapacity
            }
        }
    
    
    func addHealedSegment(_ segment: SplineReducer4Segment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            SplineReducer4PartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
}
