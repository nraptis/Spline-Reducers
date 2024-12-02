//
//  SplineReducer2LineSegment.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer2Segment: PrecomputedLineSegment {
    
    var isIllegal = false
    
    var isBucketed = false
    
    var isFlagged = false
    
    var x1: Float = 0.0
    var y1: Float = 0.0
    var x2: Float = 0.0
    var y2: Float = 0.0
    
    var centerX: Float = 0.0
    var centerY: Float = 0.0
    
    var directionX = Float(0.0)
    var directionY = Float(-1.0)
    
    var normalX = Float(1.0)
    var normalY = Float(0.0)
    
    var lengthSquared = Float(1.0)
    var length = Float(1.0)
    
    var directionAngle = Float(0.0)
    var normalAngle = Float(0.0)
}

extension SplineReducer2Segment: CustomStringConvertible {
    var description: String {
        return "SplineReducer2Segment[\(p1.description), \(p2.description), n: \(normalX) \(normalY), d: \(directionX) \(directionY), l: \(length)]"
        
    }
}
