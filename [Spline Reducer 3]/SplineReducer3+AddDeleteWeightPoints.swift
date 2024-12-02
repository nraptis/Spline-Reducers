//
//  SplineReducer3+AddDeleteWeightPoints.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension SplineReducer3 {
    
    func addWeightPoint(_ weightPoint: SplineReducer3WeightPoint) {
        while weightPoints.count <= weightPointCount {
            weightPoints.append(weightPoint)
        }
        weightPoints[weightPointCount] = weightPoint
        weightPointCount += 1
    }
    
    func purgeWeightPoints() {
        for weightPointIndex in 0..<weightPointCount {
            let weightPoint = weightPoints[weightPointIndex]
            SplineReducer3PartsFactory.shared.depositWeightPoint(weightPoint)
        }
        weightPointCount = 0
    }
    
}
