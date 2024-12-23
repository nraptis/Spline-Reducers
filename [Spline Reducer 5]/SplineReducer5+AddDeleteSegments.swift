//
//  SplineReducer5+AddDeleteSegments.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension SplineReducer5 {
    
    func removeSegment(_ segment: SplineReducer5Segment) {
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
    
    func addSegment(_ segment: SplineReducer5Segment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func purgeSegments() {
        for segmentIndex in 0..<segmentCount {
            let segment = segments[segmentIndex]
            SplineReducer5PartsFactory.shared.depositSegment(segment)
        }
        segmentCount = 0
    }
    
    func addTestSegmentA(_ segment: SplineReducer5Segment) {
        while testSegmentsA.count <= testSegmentCountA {
            testSegmentsA.append(segment)
        }
        testSegmentsA[testSegmentCountA] = segment
        testSegmentCountA += 1
    }

    
}
