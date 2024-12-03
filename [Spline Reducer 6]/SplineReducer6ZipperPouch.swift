//
//  SplineReducer6ZipperPouch.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer6ZipperPouch {
    
    var isVisited = false
    
    var healedSegments = [SplineReducer6Segment]()
    var healedSegmentCount = 0
    
    var segments = [SplineReducer6Segment]()
    var segmentCount = 0
    
    var x = Float(0.0)
    var y = Float(0.0)
    
    var numberOfCombinedZipperPouches = 1
    
    func addSegment(_ segment: SplineReducer6Segment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func reset() {
        segmentCount = 0
    }
    
    static func transferAllSegments(from fromPouch: SplineReducer6ZipperPouch,
                                    to toPouch: SplineReducer6ZipperPouch) {
        for segmentIndex in 0..<fromPouch.segmentCount {
            let segment = fromPouch.segments[segmentIndex]
            toPouch.addSegment(segment)
        }
        fromPouch.segmentCount = 0
    }
    
    func addHealedSegment(_ segment: SplineReducer6Segment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            SplineReducer6PartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
}
