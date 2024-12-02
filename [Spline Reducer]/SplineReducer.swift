//
//  SplineReducer.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 4/27/24.
//
//  Not Verified
//

import Foundation

class SplineReducer {
    
    let splineReducerSegmentBucket = SplineReducerSegmentBucket()
    
    var splineReducerSegments = [SplineReducerSegment]()
    var splineReducerSegmentCount = 0
    
    static let sampleMinimumCount = 4
    
    static let sampleEstimationStride = Float(3.0)
    static let sampleEstimationCount = 10
    
    static let toleranceTight = Float(2.0)
    static let toleranceTightSquared = (toleranceTight * toleranceTight)
    
    static let toleranceLoose = Float(3.0)
    static let toleranceLooseSquared = (toleranceLoose * toleranceLoose)
    
    static let bucketBoundary = (toleranceLoose + toleranceLoose)
    
    func removeSplineReducerSegment(_ splineReducerSegment: SplineReducerSegment) {
        for checkIndex in 0..<splineReducerSegmentCount {
            if splineReducerSegments[checkIndex] === splineReducerSegment {
                removeSplineReducerSegment(checkIndex)
                return
            }
        }
    }

    func removeSplineReducerSegment(_ index: Int) {
        if index >= 0 && index < splineReducerSegmentCount {
            let splineReducerSegmentCount1 = splineReducerSegmentCount - 1
            var splineReducerSegmentIndex = index
            while splineReducerSegmentIndex < splineReducerSegmentCount1 {
                splineReducerSegments[splineReducerSegmentIndex] = splineReducerSegments[splineReducerSegmentIndex + 1]
                splineReducerSegmentIndex += 1
            }
            splineReducerSegmentCount -= 1
        }
    }

    func addSplineReducerSegment(_ splineReducerSegment: SplineReducerSegment) {
        while splineReducerSegments.count <= splineReducerSegmentCount {
            splineReducerSegments.append(splineReducerSegment)
        }
        splineReducerSegments[splineReducerSegmentCount] = splineReducerSegment
        splineReducerSegmentCount += 1
    }

    func purgeSplineReducerSegments() {
        for splineReducerSegmentIndex in 0..<splineReducerSegmentCount {
            let splineReducerSegment = splineReducerSegments[splineReducerSegmentIndex]
            SplineReducerPartsFactory.shared.depositSplineReducerSegment(splineReducerSegment)
        }
        splineReducerSegmentCount = 0
    }
    
    var tempSpline = ManualSpline()
    
    func reduce(inputSpline: ManualSpline, 
                outputSpline: ManualSpline,
                numberOfTriesTight: Int,
                numberOfTriesLoose: Int) {
        
        purgeSplineReducerSegments()
        
        guard inputSpline.count >= 3 else {
            return
        }
        
        // Always 8?
        let numberOfStepsPerIndex = 8
        
        calculateSplineReducerSegments(inputSpline: inputSpline, numberOfStepsPerIndex: numberOfStepsPerIndex)
        buildSplineReducerSegmentBucket()
        
        outputSpline.readFromSpline(spline: inputSpline)
        outputSpline.solve(closed: true)
        
        for _ in 0..<numberOfTriesTight {
            
            if outputSpline.count <= 3 {
                break
            }
            
            // Right now, outputSpline has the answer.
            // We copy it to "tempSpline".
            tempSpline.readFromSpline(spline: outputSpline)
            
            // If we fail to reduce, then copy back
            // from "tempSpline" to "outputSpline"
            if !attemptReduce(outputSpline: outputSpline, isTight: true) {
                outputSpline.readFromSpline(spline: tempSpline)
                outputSpline.solve(closed: true)
            }
        }
        
        for _ in 0..<numberOfTriesLoose {
            
            if outputSpline.count <= 3 {
                break
            }
            
            // Right now, outputSpline has the answer.
            // We copy it to "tempSpline".
            tempSpline.readFromSpline(spline: outputSpline)
            
            // If we fail to reduce, then copy back
            // from "tempSpline" to "outputSpline"
            if !attemptReduce(outputSpline: outputSpline, isTight: false) {
                outputSpline.readFromSpline(spline: tempSpline)
                outputSpline.solve(closed: true)
            }
        }
    }
    
    func attemptReduce(outputSpline: ManualSpline, isTight: Bool) -> Bool {
        
        let indexToRemove = Int.random(in: 0..<outputSpline.count)
        //let indexToRemove = outputSpline.count - 1
        
        outputSpline.remove(at: indexToRemove)
        outputSpline.solve(closed: true)
        
        sampleCount = 0
        
        var previousIndex1 = indexToRemove - 1
        if previousIndex1 < 0 {
            previousIndex1 = outputSpline.count - 1
        }
        sample(at: previousIndex1, inputSpline: outputSpline)
        
        var previousIndex2 = previousIndex1 - 1
        if previousIndex2 < 0 {
            previousIndex2 = outputSpline.count - 1
        }
        sample(at: previousIndex2, inputSpline: outputSpline)
        
        var previousIndex3 = previousIndex2 - 1
        if previousIndex3 < 0 {
            previousIndex3 = outputSpline.count - 1
        }
        sample(at: previousIndex3, inputSpline: outputSpline)
        
        var nextIndex1 = indexToRemove
        if nextIndex1 >= outputSpline.count {
            nextIndex1 = 0
        }
        sample(at: nextIndex1, inputSpline: outputSpline)
        
        var nextIndex2 = nextIndex1 + 1
        if nextIndex2 >= outputSpline.count {
            nextIndex2 = 0
        }
        sample(at: nextIndex2, inputSpline: outputSpline)
        
        guard sampleCount > 0 else {
            return false
        }
        
        var sampleMinX = sampleX[0]
        var sampleMinY = sampleY[0]
        var sampleMaxX = sampleX[0]
        var sampleMaxY = sampleY[0]
        
        for sampleIndex in 0..<sampleCount {
            let x = sampleX[sampleIndex]
            let y = sampleY[sampleIndex]
            if x < sampleMinX { sampleMinX = x }
            if y < sampleMinY { sampleMinY = y }
            if x > sampleMaxX { sampleMaxX = x }
            if y > sampleMaxY { sampleMaxY = y }
        }
        
        splineReducerSegmentBucket.query(minX: sampleMinX - Self.bucketBoundary,
                                         maxX: sampleMaxX + Self.bucketBoundary,
                                         minY: sampleMinY - Self.bucketBoundary,
                                         maxY: sampleMaxY + Self.bucketBoundary)
        
        for sampleIndex in 0..<sampleCount {
            let x = sampleX[sampleIndex]
            let y = sampleY[sampleIndex]
            
            
            var closestSegmentDistanceSquared = Float(100_000_000.0)
            
            for bucketIndex in 0..<splineReducerSegmentBucket.splineReducerSegmentCount {
                let splineReducerSegment = splineReducerSegmentBucket.splineReducerSegments[bucketIndex]
                let distanceSquaredToClosestPoint = splineReducerSegment.distanceSquaredToClosestPoint(x, y)
                if distanceSquaredToClosestPoint < closestSegmentDistanceSquared {
                    closestSegmentDistanceSquared = distanceSquaredToClosestPoint
                }
            }
            
            if isTight {
                if closestSegmentDistanceSquared >= Self.toleranceTightSquared {
                    //print("for tight \(indexToRemove), closestSegmentDistanceSquared was \(sqrtf(closestSegmentDistanceSquared)), and expected \(sqrtf(Self.toleranceTightSquared))")
                    return false
                }
            } else {
                if closestSegmentDistanceSquared >= Self.toleranceLooseSquared {
                    //print("for loose \(indexToRemove), closestSegmentDistanceSquared was \(sqrtf(closestSegmentDistanceSquared)), and expected \(sqrtf(Self.toleranceLooseSquared))")
                    return false
                }
            }
        }
        
        return true
    }
    
    func calculateSplineReducerSegments(inputSpline: ManualSpline, numberOfStepsPerIndex: Int) {
        purgeSplineReducerSegments()
        
        let numberOfStepsPerIndex1 = (numberOfStepsPerIndex - 1)
        
        var didLoop = false
        var previousX = Float(0.0)
        var previousY = Float(0.0)
        for index in 0..<inputSpline.maxIndex {
            
            for percentIndex in 0..<numberOfStepsPerIndex {
                
                let percent = Float(percentIndex) / Float(numberOfStepsPerIndex1)
                let x = inputSpline.getX(index: index, percent: percent)
                let y = inputSpline.getY(index: index, percent: percent)
                if didLoop {
                    let splineReducerSegment = SplineReducerPartsFactory.shared.withdrawSplineReducerSegment()
                    splineReducerSegment.x1 = previousX
                    splineReducerSegment.y1 = previousY
                    splineReducerSegment.x2 = x
                    splineReducerSegment.y2 = y
                    
                    splineReducerSegment.precompute()
                    if splineReducerSegment.isIllegal {
                        SplineReducerPartsFactory.shared.depositSplineReducerSegment(splineReducerSegment)
                    } else {
                        addSplineReducerSegment(splineReducerSegment)
                    }
                }
                previousX = x
                previousY = y
                didLoop = true
            }
        }
    }
    
    func buildSplineReducerSegmentBucket() {
        splineReducerSegmentBucket.build(splineReducerSegments: splineReducerSegments,
                                         splineReducerSegmentCount: splineReducerSegmentCount)
    }
    
    func sample(at index: Int, inputSpline: ManualSpline) {
        
        
        let samplePointCount = estimatePointCount(at: index, inputSpline: inputSpline)
        let samplePointCount1 = (samplePointCount - 1)
        let samplePointCount1f = Float(samplePointCount1)
        
        for sampleIndex in 0..<samplePointCount {
            let percent = Float(sampleIndex) / samplePointCount1f
            let x = inputSpline.getX(index: index, percent: percent)
            let y = inputSpline.getY(index: index, percent: percent)
            addPointSample(x: x, y: y)
        }
    }
    
    func estimatePointCount(at index: Int, inputSpline: ManualSpline) -> Int {
        tempCount = 0
        
        for tempIndex in 0..<Self.sampleEstimationCount {
            let percent = Float(tempIndex) / Float(Self.sampleEstimationCount - 1)
            let x = inputSpline.getX(index: index, percent: percent)
            let y = inputSpline.getY(index: index, percent: percent)
            addPointTemp(x: x, y: y)
        }
        
        var estimatedLength = Float(0.0)
        if tempCount > 0 {
            var previousX = tempX[0]
            var previousY = tempY[0]
            var tempIndex = 1
            while tempIndex < tempCount {
                let x = tempX[tempIndex]
                let y = tempY[tempIndex]
                let diffX = x - previousX
                let diffY = y - previousY
                
                let distanceSquared = diffX * diffX + diffY * diffY
                if distanceSquared > Math.epsilon {
                    let distance = sqrtf(distanceSquared)
                    estimatedLength += distance
                }
                tempIndex += 1
                previousX = x
                previousY = y
            }
            
            let sampleCountf = estimatedLength / Self.sampleEstimationStride
            let sampleCount = Int(sampleCountf + 0.5)
            if sampleCount < Self.sampleMinimumCount {
                return Self.sampleMinimumCount
            } else {
                return sampleCount
            }
        } else {
            return Self.sampleMinimumCount
        }
    }
    
    private(set) var sampleCount = 0
    private(set) var sampleCapacity = 0
    private(set) var sampleX = [Float]()
    private(set) var sampleY = [Float]()
    
    private func addPointSample(x: Float, y: Float) {
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
    
    private(set) var tempCount = 0
    private(set) var tempCapacity = 0
    private(set) var tempX = [Float]()
    private(set) var tempY = [Float]()
    
    private func addPointTemp(x: Float, y: Float) {
        if tempCount >= tempCapacity {
            reserveCapacityTemp(minimumCapacity: tempCount + (tempCount >> 1) + 1)
        }
        tempX[tempCount] = x
        tempY[tempCount] = y
        tempCount += 1
    }
    
    private func reserveCapacityTemp(minimumCapacity: Int) {
        if minimumCapacity > tempCapacity {
            tempX.reserveCapacity(minimumCapacity)
            tempY.reserveCapacity(minimumCapacity)
            while tempX.count < minimumCapacity {
                tempX.append(0.0)
            }
            while tempY.count < minimumCapacity {
                tempY.append(0.0)
            }
            tempCapacity = minimumCapacity
        }
    }
}
