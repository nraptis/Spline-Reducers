//
//  SplineReducer5ZipperPouch.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer5ZipperPouch {
    
    var isVisitedPassA = false
    var isVisitedPassB = false
    
    var healedSegments = [SplineReducer5Segment]()
    var healedSegmentCount = 0
    
    var segments = [SplineReducer5Segment]()
    var segmentCount = 0
    
    var currentControlPoint: SplineReducer5ControlPoint?
    var nextControlPoint: SplineReducer5ControlPoint?
    
    var numberOfCombinedZipperPouches = 1
    
    func addSegment(_ segment: SplineReducer5Segment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func reset() {
        segmentCount = 0
    }
    
    static func transferAllSegments(from fromPouch: SplineReducer5ZipperPouch,
                                    to toPouch: SplineReducer5ZipperPouch) {
        for segmentIndex in 0..<fromPouch.segmentCount {
            let segment = fromPouch.segments[segmentIndex]
            toPouch.addSegment(segment)
        }
        fromPouch.segmentCount = 0
    }
    
    
    
    func addHealedSegment(_ segment: SplineReducer5Segment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            SplineReducer5PartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
}
