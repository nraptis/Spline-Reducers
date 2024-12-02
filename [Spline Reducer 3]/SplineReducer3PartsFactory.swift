//
//  SplineReducer3PartsFactory.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer3PartsFactory {
    
    nonisolated(unsafe) static let shared = SplineReducer3PartsFactory()
    
    private init() {
        
    }
    
    ////////////////
    ///
    ///
    private var segments = [SplineReducer3Segment]()
    var segmentCount = 0
    func depositSegment(_ segment: SplineReducer3Segment) {
        segment.isIllegal = false
        segment.isBucketed = false // This may well have been the midding nugget
        
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    func withdrawSegment() -> SplineReducer3Segment {
        if segmentCount > 0 {
            segmentCount -= 1
            return segments[segmentCount]
        }
        return SplineReducer3Segment()
    }
    ///
    ///
    ////////////////
    
    
    
    ////////////////
    ///
    ///
    var zipperPouches = [SplineReducer3ZipperPouch]()
    var zipperPouchCount = 0
    
    func depositZipperPouch(_ zipperPouch: SplineReducer3ZipperPouch) {
        while zipperPouches.count <= zipperPouchCount {
            zipperPouches.append(zipperPouch)
        }
        
        zipperPouch.reset()
        zipperPouches[zipperPouchCount] = zipperPouch
        zipperPouchCount += 1
    }
    func withdrawZipperPouch() -> SplineReducer3ZipperPouch {
        if zipperPouchCount > 0 {
            zipperPouchCount -= 1
            return zipperPouches[zipperPouchCount]
        }
        return SplineReducer3ZipperPouch()
    }
    
    ///
    ///
    ////////////////
    
    ////////////////
    ///
    ///
    
    private var weightPoints = [SplineReducer3WeightPoint]()
    var weightPointCount = 0
    func depositWeightPoint(_ weightPoint: SplineReducer3WeightPoint) {
        while weightPoints.count <= weightPointCount {
            weightPoints.append(weightPoint)
        }
        weightPoints[weightPointCount] = weightPoint
        weightPointCount += 1
    }
    
    func withdrawWeightPoint() -> SplineReducer3WeightPoint {
        if weightPointCount > 0 {
            weightPointCount -= 1
            return weightPoints[weightPointCount]
        }
        return SplineReducer3WeightPoint()
    }
    
    ///
    ///
    ////////////////
    ///

    
}
