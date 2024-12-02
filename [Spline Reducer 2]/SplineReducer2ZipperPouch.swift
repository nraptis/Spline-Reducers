//
//  SplineReducer2ZipperPouch.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer2ZipperPouch {
    
    var segments = [SplineReducer2Segment]()
    var segmentCount = 0
    
    var currentControlPoint: SplineReducer2ControlPoint?
    var nextControlPoint: SplineReducer2ControlPoint?
    
    var numberOfCombinedZipperPouches = 1
    
    func addSegment(_ segment: SplineReducer2Segment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func reset() {
        segmentCount = 0
    }
    
    static func transferAllSegments(from fromPouch: SplineReducer2ZipperPouch,
                                    to toPouch: SplineReducer2ZipperPouch) {
        for segmentIndex in 0..<fromPouch.segmentCount {
            let segment = fromPouch.segments[segmentIndex]
            toPouch.addSegment(segment)
        }
        fromPouch.segmentCount = 0
    }
    
}
