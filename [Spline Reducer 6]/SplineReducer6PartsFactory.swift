//
//  SplineReducer6PartsFactory.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer6PartsFactory {
    
    nonisolated(unsafe) static let shared = SplineReducer6PartsFactory()
    
    private init() {
        
    }
    
    ////////////////
    ///
    ///
    private var segments = [SplineReducer6Segment]()
    var segmentCount = 0
    func depositSegment(_ segment: SplineReducer6Segment) {
        segment.isIllegal = false
        
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    func withdrawSegment() -> SplineReducer6Segment {
        if segmentCount > 0 {
            segmentCount -= 1
            return segments[segmentCount]
        }
        return SplineReducer6Segment()
    }
    ///
    ///
    ////////////////
    
    
    
    ////////////////
    ///
    ///
    var zipperPouches = [SplineReducer6ZipperPouch]()
    var zipperPouchCount = 0
    
    func depositZipperPouch(_ zipperPouch: SplineReducer6ZipperPouch) {
        while zipperPouches.count <= zipperPouchCount {
            zipperPouches.append(zipperPouch)
        }
        
        zipperPouch.reset()
        zipperPouch.purgeHealedSegments()
        
        zipperPouches[zipperPouchCount] = zipperPouch
        zipperPouchCount += 1
    }
    func withdrawZipperPouch() -> SplineReducer6ZipperPouch {
        if zipperPouchCount > 0 {
            zipperPouchCount -= 1
            return zipperPouches[zipperPouchCount]
        }
        return SplineReducer6ZipperPouch()
    }
    
    ///
    ///
    ////////////////
    
    
}
