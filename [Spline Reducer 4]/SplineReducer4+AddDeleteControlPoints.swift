//
//  SplineReducer4+AddDeleteControlPoints.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension SplineReducer4 {
    
    func removeControlPoint(_ controlPoint: SplineReducer4ControlPoint) {
        for checkIndex in 0..<controlPointCount {
            if controlPoints[checkIndex] === controlPoint {
                removeControlPoint(checkIndex)
                return
            }
        }
    }

    func removeControlPoint(_ index: Int) {
        if index >= 0 && index < controlPointCount {
            let controlPointCount1 = controlPointCount - 1
            var controlPointIndex = index
            while controlPointIndex < controlPointCount1 {
                controlPoints[controlPointIndex] = controlPoints[controlPointIndex + 1]
                controlPointIndex += 1
            }
            controlPointCount -= 1
        }
    }

    func addControlPoint(_ controlPoint: SplineReducer4ControlPoint) {
        while controlPoints.count <= controlPointCount {
            controlPoints.append(controlPoint)
        }
        controlPoints[controlPointCount] = controlPoint
        controlPointCount += 1
    }
    
    func purgeControlPoints() {
        for controlPointIndex in 0..<controlPointCount {
            let controlPoint = controlPoints[controlPointIndex]
            SplineReducer4PartsFactory.shared.depositControlPoint(controlPoint)
        }
        controlPointCount = 0
    }
    
}
