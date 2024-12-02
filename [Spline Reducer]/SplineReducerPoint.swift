//
//  SplineReducerPoint.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 4/27/24.
//
//  Verified on 11/9/2024 by Nick Raptis
//

import Foundation

class SplineReducerPoint {
    
    typealias Point = Math.Point
    
    var x = Float(0.0)
    var y = Float(0.0)
    
    var point: Point {
        Point(x: x, y: y)
    }
    
    var tanDirection = Float(0.0)
    var tanMagnitudeIn = Float(0.0)
    var tanMagnitudeOut = Float(0.0)
    
}
