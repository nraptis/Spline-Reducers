//
//  StochasticSplineReducer+AddDeleteBucketes.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension StochasticSplineReducer {
    
    // @Precondition: index1 != index2
    // @Precondition: index1 in range 0..<bucketCount
    // @Precondition: index2 in range 0..<bucketCount
    // @Precondition: bucketCount >= 2
    func removeBucketTwo(index1: Int, index2: Int) {
        StochasticSplineReducerPartsFactory.shared.depositBucket(bucketes[index1])
        StochasticSplineReducerPartsFactory.shared.depositBucket(bucketes[index2])
        
        let lowerIndex = min(index1, index2)
        let higherIndex = max(index1, index2) - 1
        
        var bucketIndex = lowerIndex
        while bucketIndex < higherIndex {
            bucketes[bucketIndex] = bucketes[bucketIndex + 1]
            bucketIndex += 1
        }
        
        let bucketCount2 = bucketCount - 2
        while bucketIndex < bucketCount2 {
            bucketes[bucketIndex] = bucketes[bucketIndex + 2]
            bucketIndex += 1
        }
        bucketCount -= 2
    }
    
    // @Precondition: index in range 0..<bucketCount
    // @Precondition: bucketCount >= 1
    func removeBucketOne(index: Int) {
        StochasticSplineReducerPartsFactory.shared.depositBucket(bucketes[index])
        let bucketCount1 = bucketCount - 1
        var bucketIndex = index
        while bucketIndex < bucketCount1 {
            bucketes[bucketIndex] = bucketes[bucketIndex + 1]
            bucketIndex += 1
        }
        bucketCount -= 1
    }
    
    func purgeBucketes() {
        for bucketIndex in 0..<bucketCount {
            let bucket = bucketes[bucketIndex]
            StochasticSplineReducerPartsFactory.shared.depositBucket(bucket)
        }
        bucketCount = 0
    }
    
    func addBucket(bucket: StochasticSplineReducerBucket) {
        while bucketes.count <= bucketCount {
            bucketes.append(bucket)
        }
        bucketes[bucketCount] = bucket
        bucketCount += 1
    }
    
    
    func addTempBucket(bucket: StochasticSplineReducerBucket, bucketIndex: Int) {
        while tempBucketes.count <= tempBucketCount {
            tempBucketes.append(bucket)
        }
        while tempBucketIndices.count <= tempBucketCount {
            tempBucketIndices.append(bucketIndex)
        }
        
        tempBucketes[tempBucketCount] = bucket
        tempBucketIndices[tempBucketCount] = bucketIndex
        
        tempBucketCount += 1
    }
    
}
