//
//  SplineReducer6+ReadInputSpline.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 12/2/24.
//

import Foundation

extension SplineReducer6 {
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func readInputSpline(inputSpline: ManualSpline,
                         numberOfPointsSampledForEachControlPoint: Int) {
        
        if numberOfPointsSampledForEachControlPoint < SplineReducer6.minNumberOfSamples { return }
        
        // We make a zipper pouch for each
        // control point on the input spline.
        let maxIndex = inputSpline.maxIndex
        
        // Did we underflow?
        if maxIndex < Self.minZipperPouchCount { return }
        
        for splineIndex in 0..<maxIndex {
            let zipperPouch = SplineReducer6PartsFactory.shared.withdrawZipperPouch()
            addZipperPouch(zipperPouch: zipperPouch)
            zipperPouch.x = inputSpline._x[splineIndex]
            zipperPouch.y = inputSpline._y[splineIndex]
        }
        
        // We're going to sample N points
        // for each control point........
        let testPointsCount1 = (numberOfPointsSampledForEachControlPoint - 1)
        let testPointsCount1f = Float(testPointsCount1)
        
        for zipperPouchIndex in 0..<zipperPouchCount {
            let zipperPouch = zipperPouches[zipperPouchIndex]
            
            // We have not combined with any
            // pouches, this is the initial state...
            zipperPouch.numberOfCombinedZipperPouches = 1
            
            // We loop N-1 times, adding the
            // line segments to each pouch...
            var testPointsIndex = 1
            var previousX = inputSpline._x[zipperPouchIndex]
            var previousY = inputSpline._y[zipperPouchIndex]
            for percentIndex in 1..<numberOfPointsSampledForEachControlPoint {
                let percent = Float(percentIndex) / testPointsCount1f
                let currentX = inputSpline.getX(index: zipperPouchIndex, percent: percent)
                let currentY = inputSpline.getY(index: zipperPouchIndex, percent: percent)
                
                let segment = SplineReducer6PartsFactory.shared.withdrawSegment()
                
                // This (spline reducer) retains the segment.
                addSegment(segment)
                
                // This (zipper pouch) holds a reference.
                zipperPouch.addSegment(segment)
                
                segment.x1 = previousX
                segment.y1 = previousY
                
                segment.x2 = currentX
                segment.y2 = currentY
                
                segment.precompute()
                
                previousX = currentX
                previousY = currentY
                
                testPointsIndex += 1
            }
        }
    }
}
