//
//  SplineReducer6+AddDeleteSegments.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension SplineReducer6 {
    
    func addSegment(_ segment: SplineReducer6Segment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func purgeSegments() {
        for segmentIndex in 0..<segmentCount {
            let segment = segments[segmentIndex]
            SplineReducer6PartsFactory.shared.depositSegment(segment)
        }
        segmentCount = 0
    }
    
}
