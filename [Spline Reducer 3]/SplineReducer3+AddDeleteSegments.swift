//
//  SplineReducer3+AddDeleteSegments.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension SplineReducer3 {
    
    func removeSegment(_ segment: SplineReducer3Segment) {
        for checkIndex in 0..<segmentCount {
            if segments[checkIndex] === segment {
                removeSegment(checkIndex)
                return
            }
        }
    }
    
    func removeSegment(_ index: Int) {
        if index >= 0 && index < segmentCount {
            let segmentCount1 = segmentCount - 1
            var segmentIndex = index
            while segmentIndex < segmentCount1 {
                segments[segmentIndex] = segments[segmentIndex + 1]
                segmentIndex += 1
            }
            segmentCount -= 1
        }
    }
    
    func addSegment(_ segment: SplineReducer3Segment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func purgeSegments() {
        for segmentIndex in 0..<segmentCount {
            let segment = segments[segmentIndex]
            SplineReducer3PartsFactory.shared.depositSegment(segment)
        }
        segmentCount = 0
    }
    
    func addTestSegment(_ segment: SplineReducer3Segment) {
        while testSegments.count <= testSegmentCount {
            testSegments.append(segment)
        }
        testSegments[testSegmentCount] = segment
        testSegmentCount += 1
    }
    
    
    
    
    
    
    
    func addHealedSegment(_ segment: SplineReducer3Segment) {
        while healedSegments.count <= healedSegmentCount {
            healedSegments.append(segment)
        }
        healedSegments[healedSegmentCount] = segment
        healedSegmentCount += 1
    }
    
    func purgeHealedSegments() {
        for healedSegmentIndex in 0..<healedSegmentCount {
            let segment = healedSegments[healedSegmentIndex]
            SplineReducer3PartsFactory.shared.depositSegment(segment)
        }
        healedSegmentCount = 0
    }
    
}
