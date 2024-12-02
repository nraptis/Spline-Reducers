//
//  SplineReducerPartsFactory.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 4/27/24.
//

import Foundation

class SplineReducerPartsFactory {
    
    nonisolated(unsafe) static let shared = SplineReducerPartsFactory()
    
    private init() {
        
    }
    
    ////////////////
    ///
    ///
    private var splineReducerPoints = [SplineReducerPoint]()
    var splineReducerPointCount = 0
    var _maxSplineReducerPointCount = 0
    func depositSplineReducerPoint(_ splineReducerPoint: SplineReducerPoint) {
        while splineReducerPoints.count <= splineReducerPointCount {
            splineReducerPoints.append(splineReducerPoint)
        }
        splineReducerPoints[splineReducerPointCount] = splineReducerPoint
        splineReducerPointCount += 1
    }
    func withdrawSplineReducerPoint() -> SplineReducerPoint {
        if splineReducerPointCount > 0 {
            splineReducerPointCount -= 1
            return splineReducerPoints[splineReducerPointCount]
        }
        return SplineReducerPoint()
    }
    ///
    ///
    ////////////////
    
    
    ////////////////
    ///
    ///
    private var splineReducerSegments = [SplineReducerSegment]()
    var splineReducerSegmentCount = 0
    var _maxSplineReducerSegmentsCount = 0
    func depositSplineReducerSegment(_ splineReducerSegment: SplineReducerSegment) {
        splineReducerSegment.isIllegal = false
        splineReducerSegment.isBucketed = false // This may well have been the midding nugget
        
        while splineReducerSegments.count <= splineReducerSegmentCount {
            splineReducerSegments.append(splineReducerSegment)
        }
        splineReducerSegments[splineReducerSegmentCount] = splineReducerSegment
        splineReducerSegmentCount += 1
    }
    func withdrawSplineReducerSegment() -> SplineReducerSegment {
        if splineReducerSegmentCount > 0 {
            splineReducerSegmentCount -= 1
            return splineReducerSegments[splineReducerSegmentCount]
        }
        return SplineReducerSegment()
    }
    ///
    ///
    ////////////////
    
}
