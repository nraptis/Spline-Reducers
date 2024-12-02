//
//  SplineReducer2PartsFactory.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer2PartsFactory {
    
    nonisolated(unsafe) static let shared = SplineReducer2PartsFactory()
    
    private init() {
        
    }
    
    ////////////////
    ///
    ///
    private var controlPoints = [SplineReducer2ControlPoint]()
    var controlPointCount = 0
    func depositControlPoint(_ controlPoint: SplineReducer2ControlPoint) {
        while controlPoints.count <= controlPointCount {
            controlPoints.append(controlPoint)
        }
        controlPoints[controlPointCount] = controlPoint
        controlPointCount += 1
    }
    func withdrawControlPoint() -> SplineReducer2ControlPoint {
        if controlPointCount > 0 {
            controlPointCount -= 1
            return controlPoints[controlPointCount]
        }
        return SplineReducer2ControlPoint()
    }
    ///
    ///
    ////////////////
    
    ////////////////
    ///
    ///
    private var segments = [SplineReducer2Segment]()
    var segmentCount = 0
    func depositSegment(_ segment: SplineReducer2Segment) {
        segment.isIllegal = false
        segment.isBucketed = false // This may well have been the midding nugget
        
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    func withdrawSegment() -> SplineReducer2Segment {
        if segmentCount > 0 {
            segmentCount -= 1
            return segments[segmentCount]
        }
        return SplineReducer2Segment()
    }
    ///
    ///
    ////////////////
    
    
    
    ////////////////
    ///
    ///
    var zipperPouches = [SplineReducer2ZipperPouch]()
    var zipperPouchCount = 0
    
    func depositZipperPouch(_ zipperPouch: SplineReducer2ZipperPouch) {
        while zipperPouches.count <= zipperPouchCount {
            zipperPouches.append(zipperPouch)
        }
        
        zipperPouch.reset()
        zipperPouches[zipperPouchCount] = zipperPouch
        zipperPouchCount += 1
    }
    func withdrawZipperPouch() -> SplineReducer2ZipperPouch {
        if zipperPouchCount > 0 {
            zipperPouchCount -= 1
            return zipperPouches[zipperPouchCount]
        }
        return SplineReducer2ZipperPouch()
    }
    
    ///
    ///
    ////////////////
    
    
}
