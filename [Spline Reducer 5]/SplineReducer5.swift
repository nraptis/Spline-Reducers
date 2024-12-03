//
//  SplineReducer5.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation


// So, in this case, we will need
// 6 points at least

class SplineReducer5 {
    
    
    // 1.0, 1.5, 2.0, 2.5, 3.0,
    static let magnitudeFactorMin = Float(1.0)
    static let magnitudeFactorMax = Float(3.0)
    static let magnitudeTestSteps = 6
    
    static let rotationWiggleSpan = Math.pi_6
    static let rotationWiggleSteps = 5
    
    var healedSegments = [SplineReducer5Segment]()
    var healedSegmentCount = 0
    
    var segments = [SplineReducer5Segment]()
    var segmentCount = 0
    
    var testSegmentsA = [SplineReducer5Segment]()
    var testSegmentCountA = 0
    
    var controlPoints = [SplineReducer5ControlPoint]()
    var controlPointCount = 0
    
    var zipperPouches = [SplineReducer5ZipperPouch]()
    var zipperPouchCount = 0
    
    private var sampleCountA = 0
    private var sampleCapacityA = 0
    private var sampleXA = [Float]()
    private var sampleYA = [Float]()
    
    private var _inRotation = [Float](repeating: 0.0, count: SplineReducer5.rotationWiggleSteps)
    private var _inDirX = [Float](repeating: 0.0, count: SplineReducer5.rotationWiggleSteps)
    private var _inDirY = [Float](repeating: 0.0, count: SplineReducer5.rotationWiggleSteps)
    
    private var _outRotation = [Float](repeating: 0.0, count: SplineReducer5.rotationWiggleSteps)
    private var _outDirX = [Float](repeating: 0.0, count: SplineReducer5.rotationWiggleSteps)
    private var _outDirY = [Float](repeating: 0.0, count: SplineReducer5.rotationWiggleSteps)
    
    private var _inMagnitude = [Float](repeating: 0.0, count: SplineReducer5.magnitudeTestSteps)
    private var _outMagnitude = [Float](repeating: 0.0, count: SplineReducer5.magnitudeTestSteps)
    private var _samplePercent = [Float](repeating: 0.0, count: 32)
    
    func attemptToReduce(zipperPouchIndex: Int,
                         numberOfSamplesAtEachControlPoint: Int,
                         toleranceSquared: Float,
                         isSoft: Bool) -> Bool {
        
        if zipperPouchIndex < 0 {
            return false
        }
        if zipperPouchIndex >= zipperPouchCount {
            return false
        }
        
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
        
        if currentControlPoint.isValid == false {
            print("FATAL A: currentControlPoint.isValid should b tru...")
            return false
        }
        
        if nextControlPoint.isValid == false {
            print("FATAL A: nextControlPoint.isValid should b tru...")
            return false
        }
        
        testSegmentCountA = 0
        
        for segmentIndex in 0..<currentZipperPouch.segmentCount {
            let segment = currentZipperPouch.segments[segmentIndex]
            addTestSegmentA(segment)
        }
        
        for segmentIndex in 0..<nextZipperPouch.segmentCount {
            let segment = nextZipperPouch.segments[segmentIndex]
            addTestSegmentA(segment)
        }
        
        for segmentIndex in 0..<testSegmentCountA {
            let segment = testSegmentsA[segmentIndex]
            segment.isFlagged = true
        }
        
        let numberOfPouchesA = currentZipperPouch.numberOfCombinedZipperPouches
        let numberOfPouchesB = nextZipperPouch.numberOfCombinedZipperPouches
        let numberOfPouches = numberOfPouchesA + numberOfPouchesB
        let numberOfPoints = numberOfPouches * numberOfSamplesAtEachControlPoint
        let numberOfPointsf = Float(numberOfPoints)
        if numberOfPoints <= 1 {
            print("FATAL: numberOfPoints <= 1")
            return false
        }
        
        // The sample percents, we just move out of loop.
        while _samplePercent.count <= numberOfPoints {
            _samplePercent.append(0.0)
        }
        for pointIndex in 0...numberOfPoints {
            let percent = Float(pointIndex) / numberOfPointsf
            _samplePercent[pointIndex] = percent
        }
        
        // The *OUT* angle is from the *ME* control point...
        let angleOutMin = currentControlPoint.originalTanAngleOut - Self.rotationWiggleSpan
        let angleOutMax = currentControlPoint.originalTanAngleOut + Self.rotationWiggleSpan
        for rotationIndex in 0..<Self.rotationWiggleSteps {
            let rotationPercent = Float(rotationIndex) / Float(Self.rotationWiggleSteps - 1)
            let rotation = angleOutMin + (angleOutMax - angleOutMin) * rotationPercent
            let tanDirOutX = sinf(rotation)
            let tanDirOutY = -cosf(rotation)
            _outRotation[rotationIndex] = rotation
            _outDirX[rotationIndex] = tanDirOutX
            _outDirY[rotationIndex] = tanDirOutY
        }
        
        // The *IN* angle is from the *NEXT* control point...
        let angleInMin = nextControlPoint.originalTanAngleIn - Self.rotationWiggleSpan
        let angleInMax = nextControlPoint.originalTanAngleIn + Self.rotationWiggleSpan
        for rotationIndex in 0..<Self.rotationWiggleSteps {
            let rotationPercent = Float(rotationIndex) / Float(Self.rotationWiggleSteps - 1)
            let rotation = angleInMin + (angleInMax - angleInMin) * rotationPercent
            let tanDirInX = -sinf(rotation)
            let tanDirInY = cosf(rotation)
            _inRotation[rotationIndex] = rotation
            _inDirX[rotationIndex] = tanDirInX
            _inDirY[rotationIndex] = tanDirInY
        }
        
        // The *OUT* magnitude is from the *ME* control point...
        let magnitudeOutMin = currentControlPoint.originalTanMagnitudeOut * Self.magnitudeFactorMin
        let magnitudeOutMax = currentControlPoint.originalTanMagnitudeOut * Self.magnitudeFactorMax
        for magnitudeIndex in 0..<Self.magnitudeTestSteps {
            let magnitudePercent = Float(magnitudeIndex) / Float(Self.magnitudeTestSteps - 1)
            let magnitude = magnitudeOutMin + (magnitudeOutMax - magnitudeOutMin) * magnitudePercent
            _outMagnitude[magnitudeIndex] = magnitude
        }
        
        // The *IN* magnitude is from the *NEXT* control point...
        let magnitudeInMin = nextControlPoint.originalTanMagnitudeIn * Self.magnitudeFactorMin
        let magnitudeInMax = nextControlPoint.originalTanMagnitudeIn * Self.magnitudeFactorMax
        for magnitudeIndex in 0..<Self.magnitudeTestSteps {
            let magnitudePercent = Float(magnitudeIndex) / Float(Self.magnitudeTestSteps - 1)
            let magnitude = magnitudeInMin + (magnitudeInMax - magnitudeInMin) * magnitudePercent
            _inMagnitude[magnitudeIndex] = magnitude
        }
        
        var bestAngleInIndex = -1
        var bestAngleOutIndex = -1
        var bestMagnitudeInIndex = -1
        var bestMagnitudeOutIndex = -1
        
        var bestDistanceSquared = toleranceSquared
        
        var loopCount = 0
        
        for inMagnitudeIndex in 0..<Self.magnitudeTestSteps {
            let inMagnitude = _inMagnitude[inMagnitudeIndex]
            for inRotationIndex in 0..<Self.rotationWiggleSteps {
                let inDirX = _inDirX[inRotationIndex]
                let inDirY = _inDirY[inRotationIndex]
                nextControlPoint.inTanX = inDirX * inMagnitude
                nextControlPoint.inTanY = inDirY * inMagnitude
                for outMagnitudeIndex in 0..<Self.magnitudeTestSteps {
                    let outMagnitude = _outMagnitude[outMagnitudeIndex]
                    for outRotationIndex in 0..<Self.rotationWiggleSteps {
                        
                        loopCount += 1
                        
                        let outDirX = _outDirX[outRotationIndex]
                        let outDirY = _outDirY[outRotationIndex]
                        currentControlPoint.outTanX = outDirX * outMagnitude
                        currentControlPoint.outTanY = outDirY * outMagnitude
                        currentControlPoint.compute(nextControlPoint: nextControlPoint)
                        
                        sampleCountA = 0
                        addPointSampleA(x: currentControlPoint.x,
                                        y: currentControlPoint.y)
                        for pointIndex in 1..<numberOfPoints {
                            let percent = _samplePercent[pointIndex]
                            let x = currentControlPoint.getX(percent: percent)
                            let y = currentControlPoint.getY(percent: percent)
                            addPointSampleA(x: x, y: y)
                        }
                        addPointSampleA(x: nextControlPoint.x,
                                        y: nextControlPoint.y)
                        
                        
                        var maxDistanceSquaredFromAnyPointToMinAtAnySegment = Float(0.0)
                        
                        //if isSamplePointListComplexA() {
                        //    break
                        //}
                        
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
                        
                        if maxDistanceSquaredFromAnyPointToMinAtAnySegment < bestDistanceSquared {
                            bestDistanceSquared = maxDistanceSquaredFromAnyPointToMinAtAnySegment
                            bestAngleInIndex = inRotationIndex
                            bestAngleOutIndex = outRotationIndex
                            bestMagnitudeInIndex = inMagnitudeIndex
                            bestMagnitudeOutIndex = outMagnitudeIndex
                        }
                    }
                }
            }
        }
        
        if bestAngleInIndex != -1 {
            
            
            let inMagnitude = _inMagnitude[bestMagnitudeInIndex]
            let inDirX = _inDirX[bestAngleInIndex]
            let inDirY = _inDirY[bestAngleInIndex]
            nextControlPoint.inTanX = inDirX * inMagnitude
            nextControlPoint.inTanY = inDirY * inMagnitude
            
            let outMagnitude = _outMagnitude[bestMagnitudeOutIndex]
            let outDirX = _outDirX[bestAngleOutIndex]
            let outDirY = _outDirY[bestAngleOutIndex]
            currentControlPoint.outTanX = outDirX * outMagnitude
            currentControlPoint.outTanY = outDirY * outMagnitude
            currentControlPoint.compute(nextControlPoint: nextControlPoint)
            
            currentZipperPouch.nextControlPoint = nextZipperPouch.nextControlPoint
            currentZipperPouch.numberOfCombinedZipperPouches += nextZipperPouch.numberOfCombinedZipperPouches
            SplineReducer5ZipperPouch.transferAllSegments(from: nextZipperPouch, to: currentZipperPouch)
            removeZipperPouch(nextZipperPouchIndex)
            
            return true
            
        } else {
            nextControlPoint.inTanX = nextControlPoint.originalInTanX
            nextControlPoint.inTanY = nextControlPoint.originalInTanY
            currentControlPoint.outTanX = currentControlPoint.originalOutTanX
            currentControlPoint.outTanY = currentControlPoint.originalOutTanY
            currentControlPoint.compute(nextControlPoint: nextControlPoint)
            return false
        }
    }
    
    func reduce(inputSpline: ManualSpline,
                outputSpline: ManualSpline,
                numberOfSamplesAtEachControlPoint: Int,
                maxCombinedPouches: Int,
                toleranceForced: Float,
                toleranceSoft: Float) {
        
        purgeZipperPouches()
        purgeControlPoints()
        purgeSegments()
        
        read(inputSpline: inputSpline,
             numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint)
        
        
        let toleranceForcedSquared = toleranceForced * toleranceForced
        let toleranceSoftSquared = toleranceSoft * toleranceSoft
        
        
        // The first step is to force-combine points too close and stuff...
        
        var forceMergeIndex = 0
        while forceMergeIndex < zipperPouchCount {
            if attemptToReduce(zipperPouchIndex: forceMergeIndex,
                               numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                               toleranceSquared: toleranceForcedSquared,
                               isSoft: false) {
                print("force merge at \(forceMergeIndex), yes")
                //forceMergeIndex += 2
            } else {
                print("force merge at \(forceMergeIndex), NO!")
                
            }
            forceMergeIndex += 1
            
        }
        
        for controlPointIndex in 0..<controlPointCount {
            let controlPoint = controlPoints[controlPointIndex]
            controlPoint.readIn2(inTanX: controlPoint.inTanX,
                                 inTanY: controlPoint.inTanY,
                                 outTanX: controlPoint.outTanX,
                                 outTanY: controlPoint.outTanY)
        }
        
        
        
        while true {
            if zipperPouchCount <= 3 {
                break
            }
            
            // On each attempt, we will try all the indices...
            
            let startIndex = Int.random(in: 0..<zipperPouchCount)
            var tryIndex = startIndex
            var isSuccessful = false
            
            while tryIndex < zipperPouchCount && !isSuccessful {
                if zipperPouches[tryIndex].isVisitedPassB {
                    tryIndex += 1
                    continue
                }
                if zipperPouches[tryIndex].numberOfCombinedZipperPouches >= maxCombinedPouches {
                    tryIndex += 1
                    continue
                }
                
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSoftSquared,
                                   isSoft: true) {
                    print("a soft merge at \(tryIndex), yes")
                    isSuccessful = true
                } else {
                    print("a soft merge at \(tryIndex), NO!")
                    zipperPouches[tryIndex].isVisitedPassB = true
                    tryIndex += 1
                }
            }
            
            
            tryIndex = 0
            while tryIndex < startIndex && !isSuccessful {
                if zipperPouches[tryIndex].isVisitedPassB {
                    tryIndex += 1
                    continue
                }
                if zipperPouches[tryIndex].numberOfCombinedZipperPouches >= maxCombinedPouches {
                    tryIndex += 1
                    continue
                }
                
                if attemptToReduce(zipperPouchIndex: tryIndex,
                                   numberOfSamplesAtEachControlPoint: numberOfSamplesAtEachControlPoint,
                                   toleranceSquared: toleranceSoftSquared,
                                   isSoft: true) {
                    //print("b soft merge at \(tryIndex), yes")
                    isSuccessful = true
                } else {
                    //print("b soft merge at \(tryIndex), NO!")
                    zipperPouches[tryIndex].isVisitedPassB = true
                    tryIndex += 1
                }
            }
            
            if isSuccessful == false {
                break
            }
        }
        
        
        
        /*
         
         
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
                
                let segment = SplineReducer5PartsFactory.shared.withdrawSegment()
                
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
                
                let segment = SplineReducer5PartsFactory.shared.withdrawSegment()
                
                
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
        */
        
        outputSpline.solve(closed: inputSpline.closed)
        
    }
    
    private func populateSamplePoints(currentControlPoint: SplineReducer5ControlPoint,
                                      nextControlPoint: SplineReducer5ControlPoint,
                                      numberOfSamplePoints: Int) {
        sampleCountA = 0
        addPointSampleA(x: currentControlPoint.x,
                        y: currentControlPoint.y)
        var pointIndex = 1
        while pointIndex < numberOfSamplePoints {
            let percent = Float(pointIndex) / Float(numberOfSamplePoints)
            let x = currentControlPoint.getX(percent: percent)
            let y = currentControlPoint.getY(percent: percent)
            addPointSampleA(x: x,
                            y: y)
            
            pointIndex += 1
        }
        addPointSampleA(x: nextControlPoint.x,
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
    
    private func read(inputSpline: ManualSpline,
                      numberOfSamplesAtEachControlPoint: Int) {
        
        // We follow "G.I.G.O. (Garbage In Garbage Out)
        // Action Plan for Results
        
        let maxIndex = inputSpline.maxIndex
        for splineIndex in 0..<maxIndex {
            
            let controlPoint = SplineReducer5PartsFactory.shared.withdrawControlPoint()
            addControlPoint(controlPoint)
            
            controlPoint.x = inputSpline._x[splineIndex]
            controlPoint.y = inputSpline._y[splineIndex]
            let inTanX = inputSpline.inTanX[splineIndex]
            let inTanY = inputSpline.inTanY[splineIndex]
            let outTanX = inputSpline.outTanX[splineIndex]
            let outTanY = inputSpline.outTanY[splineIndex]
            
            controlPoint.readIn1(inTanX: inTanX,
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
            
            let zipperPouch = SplineReducer5PartsFactory.shared.withdrawZipperPouch()
            
            zipperPouch.numberOfCombinedZipperPouches = 1
            zipperPouch.currentControlPoint = controlPoint
            zipperPouch.nextControlPoint = nextControlPoint
            zipperPouch.isVisitedPassA = false
            zipperPouch.isVisitedPassB = false
            
            addZipperPouch(zipperPouch)
            
            var sampleIndex = 1
            var previousX = sampleXA[0]
            var previousY = sampleYA[0]
            
            while sampleIndex < sampleCountA {
                let currentX = sampleXA[sampleIndex]
                let currentY = sampleYA[sampleIndex]
                
                let segment = SplineReducer5PartsFactory.shared.withdrawSegment()
                
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
    
    func addHealedSegment(_ segment: SplineReducer5Segment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            SplineReducer5PartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
}
