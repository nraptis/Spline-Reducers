//
//  SplineReducer4PartsFactory.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer4PartsFactory {
    
    nonisolated(unsafe) static let shared = SplineReducer4PartsFactory()
    
    private init() {
        
    }
    
    ////////////////
    ///
    ///
    private var controlPoints = [SplineReducer4ControlPoint]()
    var controlPointCount = 0
    func depositControlPoint(_ controlPoint: SplineReducer4ControlPoint) {
        while controlPoints.count <= controlPointCount {
            controlPoints.append(controlPoint)
        }
        controlPoints[controlPointCount] = controlPoint
        controlPointCount += 1
    }
    func withdrawControlPoint() -> SplineReducer4ControlPoint {
        if controlPointCount > 0 {
            controlPointCount -= 1
            return controlPoints[controlPointCount]
        }
        return SplineReducer4ControlPoint()
    }
    ///
    ///
    ////////////////
    
    ////////////////
    ///
    ///
    private var segments = [SplineReducer4Segment]()
    var segmentCount = 0
    func depositSegment(_ segment: SplineReducer4Segment) {
        segment.isIllegal = false
        segment.isBucketed = false // This may well have been the midding nugget
        
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    func withdrawSegment() -> SplineReducer4Segment {
        if segmentCount > 0 {
            segmentCount -= 1
            return segments[segmentCount]
        }
        return SplineReducer4Segment()
    }
    ///
    ///
    ////////////////
    
    
    
    ////////////////
    ///
    ///
    var zipperPouches = [SplineReducer4ZipperPouch]()
    var zipperPouchCount = 0
    
    func depositZipperPouch(_ zipperPouch: SplineReducer4ZipperPouch) {
        while zipperPouches.count <= zipperPouchCount {
            zipperPouches.append(zipperPouch)
        }
        
        zipperPouch.reset()
        zipperPouches[zipperPouchCount] = zipperPouch
        zipperPouchCount += 1
    }
    func withdrawZipperPouch() -> SplineReducer4ZipperPouch {
        if zipperPouchCount > 0 {
            zipperPouchCount -= 1
            return zipperPouches[zipperPouchCount]
        }
        return SplineReducer4ZipperPouch()
    }
    
    ///
    ///
    ////////////////
    
    
}
