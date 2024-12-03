//
//  StochasticSplineReducerPartsFactory.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class StochasticSplineReducerPartsFactory {
    
    nonisolated(unsafe) static let shared = StochasticSplineReducerPartsFactory()
    
    private init() {
        
    }
    
    ////////////////
    ///
    ///
    private var segments = [StochasticSplineReducerSegment]()
    var segmentCount = 0
    func depositSegment(_ segment: StochasticSplineReducerSegment) {
        segment.isIllegal = false
        
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    func withdrawSegment() -> StochasticSplineReducerSegment {
        if segmentCount > 0 {
            segmentCount -= 1
            return segments[segmentCount]
        }
        return StochasticSplineReducerSegment()
    }
    ///
    ///
    ////////////////
    
    
    
    ////////////////
    ///
    ///
    var bucketes = [StochasticSplineReducerBucket]()
    var bucketCount = 0
    
    func depositBucket(_ bucket: StochasticSplineReducerBucket) {
        while bucketes.count <= bucketCount {
            bucketes.append(bucket)
        }
        
        bucket.reset()
        bucket.purgeHealedSegments()
        
        bucketes[bucketCount] = bucket
        bucketCount += 1
    }
    func withdrawBucket() -> StochasticSplineReducerBucket {
        if bucketCount > 0 {
            bucketCount -= 1
            return bucketes[bucketCount]
        }
        return StochasticSplineReducerBucket()
    }
    
    ///
    ///
    ////////////////
    
    
}
