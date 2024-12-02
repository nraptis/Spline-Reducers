//
//  SplineReducerSegment.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 4/27/24.
//
//  Verified on 11/9/2024 by Nick Raptis
//

import Foundation

class SplineReducerSegment: PrecomputedLineSegment {
    
    var isIllegal = false
    
    var isBucketed = false
    
    var x1: Float = 0.0
    var y1: Float = 0.0
    var x2: Float = 0.0
    var y2: Float = 0.0
    
    //var isTagged: Bool = false
    
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

extension SplineReducerSegment: CustomStringConvertible {
    var description: String {
        return "SplineReducerSegment[\(p1.description), \(p2.description), n: \(normalX) \(normalY), d: \(directionX) \(directionY), l: \(length)]"
        
    }
}
