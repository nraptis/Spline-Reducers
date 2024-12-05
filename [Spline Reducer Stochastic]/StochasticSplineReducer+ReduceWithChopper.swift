//
//  StochasticSplineReducer+ReduceWithChopper.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 12/4/24.
//

import Foundation

extension StochasticSplineReducer {
    
    func transferTestBucketsToBuckets() {
        
        purgeBuckets()
        
        for bucketIndex in 0..<_testBucketCount {
            let bucket = testBuckets[bucketIndex]
            addBucket(bucket: bucket)
        }
        
        for bucketIndex in _testBucketCount..<_testBucketCapacity {
            StochasticSplineReducerPartsFactory.shared.depositBucket(testBuckets[bucketIndex])
        }
        _testBucketCapacity = 0
        _testBucketCount = 0
        
    }
    
    // [S.R. Czech] 12-4-2024: This function works as intended.
    func loadUpTestBucketsFromPathChopperPath() -> Bool {
        
        _testBucketCount = pathChopper.pathCount
        
        if pathChopper.pathCount < 3 {
            print("FATAL: pathChopper.pathCount < 3 (\(pathChopper.pathCount))")
            return false
        }
        
        // Ensure we have enough test buckets for
        // the path. There should be a minimum of
        // a 1-1 mapping from path => testBuckets...
        while _testBucketCapacity < pathChopper.pathCount {
            let testBucket = StochasticSplineReducerPartsFactory.shared.withdrawBucket()
            addTestBucket(bucket: testBucket)
        }
        
        for pathIndex in 0..<pathChopper.pathCount {
            let testBucket = testBuckets[pathIndex]
            testBucket.purgeHealedSegments()
            testBucket.segmentCount = 0
        }
        
        // Loop through the entire path...
        for pathIndex in 0..<pathChopper.pathCount {
            
            // Test bucket : path
            // 1 : 1
            let testBucket = testBuckets[pathIndex]
            
            // We are going to loop
            // bucketIndex..<nextBucketIndex
            var bucketIndex = pathChopper.path[pathIndex]
            
            // Keep track of the original index...
            testBucket.originalIndex = bucketIndex
            
            // Move the x and y to original x and y
            testBucket.x = buckets[bucketIndex].x
            testBucket.y = buckets[bucketIndex].y
            
            // Reset the numberOfCombinedbuckets,
            // this will be computed in loop.
            testBucket.numberOfCombinedbuckets = 0
            
            // The next path index.
            let nextPathIndex: Int
            if pathIndex == (pathChopper.pathCount - 1) {
                nextPathIndex = 0
            } else {
                nextPathIndex = pathIndex + 1
            }
            
            // This will be the index of the last
            // "original" bucket to use.
            // path[pathIndex]..<finalBucketIndex
            let finalBucketIndex = pathChopper.path[nextPathIndex]
            
            while bucketIndex != finalBucketIndex {
                
                // "Combine" the number two buckets.
                testBucket.numberOfCombinedbuckets += buckets[bucketIndex].numberOfCombinedbuckets
                
                // "Combine" also the line segments.
                StochasticSplineReducerBucket.copyAllSegments(from: buckets[bucketIndex],
                                                              to: testBucket)
                
                // Loop around the end...
                bucketIndex += 1
                if bucketIndex == bucketCount {
                    bucketIndex = 0
                }
            }
        }
        
        return true
    }
    
    func loadUpTestBucketsFromPathBestPath() {
        
        
        _testBucketCount = chopperBestPathCount
        
        // Ensure we have enough test buckets for
        // the best chopper path. There should be a minimum
        // of a 1-1 mapping from path => testBuckets.......
        while _testBucketCapacity < chopperBestPathCount {
            let testBucket = StochasticSplineReducerPartsFactory.shared.withdrawBucket()
            addTestBucket(bucket: testBucket)
        }
        
        for pathIndex in 0..<chopperBestPathCount {
            let testBucket = testBuckets[pathIndex]
            testBucket.purgeHealedSegments()
            testBucket.segmentCount = 0
        }
        
        // Loop through the entire path...
        for pathIndex in 0..<chopperBestPathCount {
            
            // Test bucket : path
            // 1 : 1
            let testBucket = testBuckets[pathIndex]
            
            // We are going to loop
            // bucketIndex..<nextBucketIndex
            var bucketIndex = chopperBestPath[pathIndex]
            
            // Keep track of the original index...
            testBucket.originalIndex = bucketIndex
            
            // Move the x and y to original x and y
            testBucket.x = buckets[bucketIndex].x
            testBucket.y = buckets[bucketIndex].y
            
            // Reset the numberOfCombinedbuckets,
            // this will be computed in loop.
            testBucket.numberOfCombinedbuckets = 0
            
            // The next path index.
            let nextPathIndex: Int
            if pathIndex == (chopperBestPathCount - 1) {
                nextPathIndex = 0
            } else {
                nextPathIndex = pathIndex + 1
            }
            
            // This will be the index of the last
            // "original" bucket to use.
            // path[pathIndex]..<finalBucketIndex
            let finalBucketIndex = chopperBestPath[nextPathIndex]
            
            while bucketIndex != finalBucketIndex {
                
                // "Combine" the number two buckets.
                testBucket.numberOfCombinedbuckets += buckets[bucketIndex].numberOfCombinedbuckets
                
                // "Combine" also the line segments.
                StochasticSplineReducerBucket.copyAllSegments(from: buckets[bucketIndex],
                                                              to: testBucket)
                
                // Loop around the end...
                bucketIndex += 1
                if bucketIndex == bucketCount {
                    bucketIndex = 0
                }
            }
        }
    }
    
}

