//
//  SplineReducer5PartsFactory.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer5PartsFactory {
    
    nonisolated(unsafe) static let shared = SplineReducer5PartsFactory()
    
    private init() {
        
    }
    
    ////////////////
    ///
    ///
    private var controlPoints = [SplineReducer5ControlPoint]()
    var controlPointCount = 0
    func depositControlPoint(_ controlPoint: SplineReducer5ControlPoint) {
        while controlPoints.count <= controlPointCount {
            controlPoints.append(controlPoint)
        }
        controlPoints[controlPointCount] = controlPoint
        controlPointCount += 1
    }
    func withdrawControlPoint() -> SplineReducer5ControlPoint {
        if controlPointCount > 0 {
            controlPointCount -= 1
            return controlPoints[controlPointCount]
        }
        return SplineReducer5ControlPoint()
    }
    ///
    ///
    ////////////////
    
    ////////////////
    ///
    ///
    private var segments = [SplineReducer5Segment]()
    var segmentCount = 0
    func depositSegment(_ segment: SplineReducer5Segment) {
        segment.isIllegal = false
        segment.isBucketed = false // This may well have been the midding nugget
        
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    func withdrawSegment() -> SplineReducer5Segment {
        if segmentCount > 0 {
            segmentCount -= 1
            return segments[segmentCount]
        }
        return SplineReducer5Segment()
    }
    ///
    ///
    ////////////////
    
    
    
    ////////////////
    ///
    ///
    var zipperPouches = [SplineReducer5ZipperPouch]()
    var zipperPouchCount = 0
    
    func depositZipperPouch(_ zipperPouch: SplineReducer5ZipperPouch) {
        while zipperPouches.count <= zipperPouchCount {
            zipperPouches.append(zipperPouch)
        }
        
        zipperPouch.reset()
        zipperPouches[zipperPouchCount] = zipperPouch
        zipperPouchCount += 1
    }
    func withdrawZipperPouch() -> SplineReducer5ZipperPouch {
        if zipperPouchCount > 0 {
            zipperPouchCount -= 1
            return zipperPouches[zipperPouchCount]
        }
        return SplineReducer5ZipperPouch()
    }
    
    ///
    ///
    ////////////////
    
    
}
