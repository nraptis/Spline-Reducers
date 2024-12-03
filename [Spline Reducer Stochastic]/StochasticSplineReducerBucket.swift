//
//  StochasticSplineReducerBucket.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class StochasticSplineReducerBucket {
    
    var isVisited = false
    
    var healedSegments = [StochasticSplineReducerSegment]()
    var healedSegmentCount = 0
    
    var segments = [StochasticSplineReducerSegment]()
    var segmentCount = 0
    
    var x = Float(0.0)
    var y = Float(0.0)
    
    var numberOfCombinedBucketes = 1
    
    func addSegment(_ segment: StochasticSplineReducerSegment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func reset() {
        segmentCount = 0
    }
    
    static func transferAllSegments(from fromPouch: StochasticSplineReducerBucket,
                                    to toPouch: StochasticSplineReducerBucket) {
        for segmentIndex in 0..<fromPouch.segmentCount {
            let segment = fromPouch.segments[segmentIndex]
            toPouch.addSegment(segment)
        }
        fromPouch.segmentCount = 0
    }
    
    func addHealedSegment(_ segment: StochasticSplineReducerSegment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            StochasticSplineReducerPartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
}