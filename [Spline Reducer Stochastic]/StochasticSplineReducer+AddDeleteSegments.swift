//
//  StochasticSplineReducer+AddDeleteSegments.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension StochasticSplineReducer {
    
    func addSegment(_ segment: StochasticSplineReducerSegment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    func purgeSegments() {
        for segmentIndex in 0..<segmentCount {
            let segment = segments[segmentIndex]
            StochasticSplineReducerPartsFactory.shared.depositSegment(segment)
        }
        segmentCount = 0
    }
    
}
