//
//  SplineReducer2ControlPoint.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer2ControlPoint {
    var x = Float(0.0)
    var y = Float(0.0)
    
    
    var tanMagnitudeIn = Float(10.0)
    var tanMagnitudeOut = Float(10.0)
    
    
    var tanMagnitudeInOriginal = Float(10.0)
    var tanMagnitudeOutOriginal = Float(10.0)
    
    var tanDirX = Float(0.0)
    var tanDirY = Float(0.0)
    
    var inTanX = Float(0.0)
    var inTanY = Float(0.0)
    var outTanX = Float(0.0)
    var outTanY = Float(0.0)
    
    var coefXC = Float(0.0)
    var coefXD = Float(0.0)
    var coefYC = Float(0.0)
    var coefYD = Float(0.0)
    
    
    var testInTanX = Float(0.0)
    var testInTanY = Float(0.0)
    var testOutTanX = Float(0.0)
    var testOutTanY = Float(0.0)
    
    var testCoefXC = Float(0.0)
    var testCoefXD = Float(0.0)
    var testCoefYC = Float(0.0)
    var testCoefYD = Float(0.0)
    
    func compute(nextControlPoint: SplineReducer2ControlPoint) {
        coefXC = 3.0 * (nextControlPoint.x - x) - 2.0 * outTanX + nextControlPoint.inTanX
        coefXD = 2.0 * (x - nextControlPoint.x) + outTanX - nextControlPoint.inTanX
        coefYC = 3.0 * (nextControlPoint.y - y) - 2.0 * outTanY + nextControlPoint.inTanY
        coefYD = 2.0 * (y - nextControlPoint.y) + outTanY - nextControlPoint.inTanY
    }
    
    func getX(percent: Float) -> Float {
        return x + (((coefXD * percent) + coefXC) * percent + outTanX) * percent
    }
    
    func getY(percent: Float) -> Float {
        return y + (((coefYD * percent) + coefYC) * percent + outTanY) * percent
    }
    
    func computeTest(nextControlPoint: SplineReducer2ControlPoint) {
        testCoefXC = 3.0 * (nextControlPoint.x - x) - 2.0 * testOutTanX + nextControlPoint.testInTanX
        testCoefXD = 2.0 * (x - nextControlPoint.x) + testOutTanX - nextControlPoint.testInTanX
        testCoefYC = 3.0 * (nextControlPoint.y - y) - 2.0 * testOutTanY + nextControlPoint.testInTanY
        testCoefYD = 2.0 * (y - nextControlPoint.y) + testOutTanY - nextControlPoint.testInTanY
    }
    
    func getTestX(percent: Float) -> Float {
        return x + (((testCoefXD * percent) + testCoefXC) * percent + testOutTanX) * percent
    }
    
    func getTestY(percent: Float) -> Float {
        return y + (((testCoefYD * percent) + testCoefYC) * percent + testOutTanY) * percent
    }
}
