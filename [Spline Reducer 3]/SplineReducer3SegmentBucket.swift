//
//  SplineReducer3SegmentBucket.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

final class SplineReducer3SegmentBucket {
    
    private class SplineReducer3SegmentBucketNode {
        var splineReducerSegments = [SplineReducer3Segment]()
        var splineReducerSegmentCount = 0
        
        func remove(_ splineReducerSegment: SplineReducer3Segment) {
            for checkIndex in 0..<splineReducerSegmentCount {
                if splineReducerSegments[checkIndex] === splineReducerSegment {
                    remove(checkIndex)
                    return
                }
            }
        }
        
        func remove(_ index: Int) {
            if index >= 0 && index < splineReducerSegmentCount {
                let splineReducerSegmentCount1 = splineReducerSegmentCount - 1
                var splineReducerSegmentIndex = index
                while splineReducerSegmentIndex < splineReducerSegmentCount1 {
                    splineReducerSegments[splineReducerSegmentIndex] = splineReducerSegments[splineReducerSegmentIndex + 1]
                    splineReducerSegmentIndex += 1
                }
                splineReducerSegmentCount -= 1
            }
        }
        
        func add(_ splineReducerSegment: SplineReducer3Segment) {
            while splineReducerSegments.count <= splineReducerSegmentCount {
                splineReducerSegments.append(splineReducerSegment)
            }
            splineReducerSegments[splineReducerSegmentCount] = splineReducerSegment
            splineReducerSegmentCount += 1
        }
    }
    
    private static let countH = 24
    private static let countV = 24
    
    private var grid = [[SplineReducer3SegmentBucketNode]]()
    private var gridX: [Float]
    private var gridY: [Float]
    
    private(set) var splineReducerSegments: [SplineReducer3Segment]
    private(set) var splineReducerSegmentCount = 0
    
    init() {
        
        gridX = [Float](repeating: 0.0, count: Self.countH)
        gridY = [Float](repeating: 0.0, count: Self.countV)
        splineReducerSegments = [SplineReducer3Segment]()
        
        var x = 0
        while x < Self.countH {
            var column = [SplineReducer3SegmentBucketNode]()
            var y = 0
            while y < Self.countV {
                let node = SplineReducer3SegmentBucketNode()
                column.append(node)
                y += 1
            }
            grid.append(column)
            x += 1
        }
    }
    
    func reset() {
        var x = 0
        var y = 0
        while x < Self.countH {
            y = 0
            while y < Self.countV {
                grid[x][y].splineReducerSegmentCount = 0
                y += 1
            }
            x += 1
        }
        
        splineReducerSegmentCount = 0
    }
    
    func build(splineReducerSegments: [SplineReducer3Segment], splineReducerSegmentCount: Int) {
        
        reset()
        
        guard splineReducerSegmentCount > 0 else {
            return
        }
        
        let referenceSplineReducer3Segment = splineReducerSegments[0]
        
        var minX = min(referenceSplineReducer3Segment.x1, referenceSplineReducer3Segment.x2)
        var maxX = max(referenceSplineReducer3Segment.x1, referenceSplineReducer3Segment.x2)
        var minY = min(referenceSplineReducer3Segment.y1, referenceSplineReducer3Segment.y2)
        var maxY = max(referenceSplineReducer3Segment.y1, referenceSplineReducer3Segment.y2)
        
        var splineReducerSegmentIndex = 1
        while splineReducerSegmentIndex < splineReducerSegmentCount {
            let splineReducerSegment = splineReducerSegments[splineReducerSegmentIndex]
            minX = min(minX, splineReducerSegment.x1); minX = min(minX, splineReducerSegment.x2)
            maxX = max(maxX, splineReducerSegment.x1); maxX = max(maxX, splineReducerSegment.x2)
            minY = min(minY, splineReducerSegment.y1); minY = min(minY, splineReducerSegment.y2)
            maxY = max(maxY, splineReducerSegment.y1); maxY = max(maxY, splineReducerSegment.y2)
            splineReducerSegmentIndex += 1
        }
        
        minX -= 32.0
        maxX += 32.0
        minY -= 32.0
        maxY += 32.0
        
        var x = 0
        while x < Self.countH {
            let percent = Float(x) / Float(Self.countH - 1)
            gridX[x] = minX + (maxX - minX) * percent
            x += 1
        }
        
        var y = 0
        while y < Self.countV {
            let percent = Float(y) / Float(Self.countV - 1)
            gridY[y] = minY + (maxY - minY) * percent
            y += 1
        }
        
        for splineReducerSegmentIndex in 0..<splineReducerSegmentCount {
            let splineReducerSegment = splineReducerSegments[splineReducerSegmentIndex]
            
            let _minX = min(splineReducerSegment.x1, splineReducerSegment.x2)
            let _maxX = max(splineReducerSegment.x1, splineReducerSegment.x2)
            let _minY = min(splineReducerSegment.y1, splineReducerSegment.y2)
            let _maxY = max(splineReducerSegment.y1, splineReducerSegment.y2)
            
            let lowerBoundX = lowerBoundX(value: _minX)
            let upperBoundX = upperBoundX(value: _maxX)
            let lowerBoundY = lowerBoundY(value: _minY)
            let upperBoundY = upperBoundY(value: _maxY)
            
            x = lowerBoundX
            while x <= upperBoundX {
                y = lowerBoundY
                while y <= upperBoundY {
                    grid[x][y].add(splineReducerSegment)
                    y += 1
                }
                x += 1
            }
        }
    }
    
    func remove(splineReducerSegment: SplineReducer3Segment) {
        let _minX = min(splineReducerSegment.x1, splineReducerSegment.x2)
        let _maxX = max(splineReducerSegment.x1, splineReducerSegment.x2)
        let _minY = min(splineReducerSegment.y1, splineReducerSegment.y2)
        let _maxY = max(splineReducerSegment.y1, splineReducerSegment.y2)
        
        let lowerBoundX = lowerBoundX(value: _minX)
        let upperBoundX = upperBoundX(value: _maxX)
        let lowerBoundY = lowerBoundY(value: _minY)
        let upperBoundY = upperBoundY(value: _maxY)
        
        var x = 0
        var y = 0
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                grid[x][y].remove(splineReducerSegment)
                y += 1
            }
            x += 1
        }
    }
    
    func add(splineReducerSegment: SplineReducer3Segment) {
            
        let _minX = min(splineReducerSegment.x1, splineReducerSegment.x2)
        let _maxX = max(splineReducerSegment.x1, splineReducerSegment.x2)
        let _minY = min(splineReducerSegment.y1, splineReducerSegment.y2)
        let _maxY = max(splineReducerSegment.y1, splineReducerSegment.y2)
        
        let lowerBoundX = lowerBoundX(value: _minX)
        let upperBoundX = upperBoundX(value: _maxX)
        let lowerBoundY = lowerBoundY(value: _minY)
        let upperBoundY = upperBoundY(value: _maxY)
        
        var x = 0
        var y = 0
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                grid[x][y].add(splineReducerSegment)
                y += 1
            }
            x += 1
        }
    }
    
    func query(splineReducerSegment: SplineReducer3Segment) {
        let x1 = splineReducerSegment.x1
        let y1 = splineReducerSegment.y1
        let x2 = splineReducerSegment.x2
        let y2 = splineReducerSegment.y2
        query(minX: min(x1, x2),
              maxX: max(x1, x2),
              minY: min(y1, y2),
              maxY: max(y1, y2))
    }
    
    func query(splineReducerSegment: SplineReducer3Segment, padding: Float) {
        let x1 = splineReducerSegment.x1
        let y1 = splineReducerSegment.y1
        let x2 = splineReducerSegment.x2
        let y2 = splineReducerSegment.y2
        query(minX: min(x1, x2) - padding,
              maxX: max(x1, x2) + padding,
              minY: min(y1, y2) - padding,
              maxY: max(y1, y2) + padding)
    }
    
    func query(minX: Float, maxX: Float, minY: Float, maxY: Float) {
        
        splineReducerSegmentCount = 0
        
        let lowerBoundX = lowerBoundX(value: minX)
        var upperBoundX = upperBoundX(value: maxX)
        let lowerBoundY = lowerBoundY(value: minY)
        var upperBoundY = upperBoundY(value: maxY)
        
        if upperBoundX >= Self.countH {
            upperBoundX = Self.countH - 1
        }
        
        if upperBoundY >= Self.countV {
            upperBoundY = Self.countV - 1
        }
        
        var x = 0
        var y = 0
        
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                for splineReducerSegmentIndex in 0..<grid[x][y].splineReducerSegmentCount {
                    grid[x][y].splineReducerSegments[splineReducerSegmentIndex].isBucketed = false
                }
                y += 1
            }
            x += 1
        }
        
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                for splineReducerSegmentIndex in 0..<grid[x][y].splineReducerSegmentCount {
                    let splineReducerSegment = grid[x][y].splineReducerSegments[splineReducerSegmentIndex]
                    if splineReducerSegment.isBucketed == false {
                        splineReducerSegment.isBucketed = true
                        
                        while splineReducerSegments.count <= splineReducerSegmentCount {
                            splineReducerSegments.append(splineReducerSegment)
                        }
                        splineReducerSegments[splineReducerSegmentCount] = splineReducerSegment
                        splineReducerSegmentCount += 1
                    }
                }
                y += 1
            }
            x += 1
        }
    }
    
    private func lowerBoundX(value: Float) -> Int {
        var start = 0
        var end = Self.countH
        while start != end {
            let mid = (start + end) >> 1
            if value > gridX[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return start
    }
    
    private func upperBoundX(value: Float) -> Int {
        var start = 0
        var end = Self.countH
        while start != end {
            let mid = (start + end) >> 1
            if value >= gridX[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return min(start, Self.countH - 1)
    }
    
    func lowerBoundY(value: Float) -> Int {
        var start = 0
        var end = Self.countV
        while start != end {
            let mid = (start + end) >> 1
            if value > gridY[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return start
    }
    
    func upperBoundY(value: Float) -> Int {
        var start = 0
        var end = Self.countV
        while start != end {
            let mid = (start + end) >> 1
            if value >= gridY[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return min(start, Self.countV - 1)
    }
    
}
