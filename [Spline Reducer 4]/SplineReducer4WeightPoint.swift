//
//  SplineReducer4WeightPoint.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer4WeightPoint {
    
    typealias Point = Math.Point
    
    var x = Float(0.0)
    var y = Float(0.0)
    
    var point: Point {
        Point(x: x, y: y)
    }
}
