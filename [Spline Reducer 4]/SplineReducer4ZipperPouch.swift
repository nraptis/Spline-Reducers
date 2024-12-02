//
//  SplineReducer4ZipperPouch.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer4ZipperPouch {
    
    var healedSegments = [SplineReducer4Segment]()
    var healedSegmentCount = 0
    
    var segments = [SplineReducer4Segment]()
    var segmentCount = 0
    
    var currentControlPoint: SplineReducer4ControlPoint?
    var nextControlPoint: SplineReducer4ControlPoint?
    
    var numberOfCombinedZipperPouches = 1
    
    func addSegment(_ segment: SplineReducer4Segment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func reset() {
        segmentCount = 0
    }
    
    static func transferAllSegments(from fromPouch: SplineReducer4ZipperPouch,
                                    to toPouch: SplineReducer4ZipperPouch) {
        for segmentIndex in 0..<fromPouch.segmentCount {
            let segment = fromPouch.segments[segmentIndex]
            toPouch.addSegment(segment)
        }
        fromPouch.segmentCount = 0
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
