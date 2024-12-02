//
//  SplineReducer4ControlPoint.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer4ControlPoint {
    var x = Float(0.0)
    var y = Float(0.0)
    
    
    var isValid = false
    
    
    var tanMagnitudeInOriginal = Float(10.0)
    var tanMagnitudeOutOriginal = Float(10.0)
    var tanDirectionOriginal = Float(0.0)
    var inTanDirXOriginal = Float(0.0)
    var inTanDirYOriginal = Float(0.0)
    var outTanDirXOriginal = Float(0.0)
    var outTanDirYOriginal = Float(0.0)
    
    var tanMagnitudeIn = Float(10.0)
    var tanMagnitudeOut = Float(10.0)
    var tanDirection = Float(0.0)
    
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
    
    func compute(nextControlPoint: SplineReducer4ControlPoint) {
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
    
    func computeTest(nextControlPoint: SplineReducer4ControlPoint) {
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
    
    func readIn(inTanX: Float,
                inTanY: Float,
                outTanX: Float,
                outTanY: Float) {
        
        var inDist = inTanX * inTanX + inTanY * inTanY
        var outDist = outTanX * outTanX + outTanY * outTanY
        
        let epsilon1 = Float(32.0 * 32.0)
        let epsilon2 = Float( 4.0 *  4.0)
        let epsilon3 = Float(0.1 * 0.1)
        
        var rotation = Float(0.0)
        var isValidReading = true
        
        if inDist > epsilon1 {
            rotation = Math.face(target: .init(x: -inTanX, y: -inTanY))
        } else if outDist > epsilon1 {
            rotation = Math.face(target: .init(x: outTanX, y: outTanY))
        } else if inDist > epsilon2 {
            rotation = Math.face(target: .init(x: -inTanX, y: -inTanY))
        } else if outDist > epsilon2 {
            rotation = Math.face(target: .init(x: outTanX, y: outTanY))
        } else if inDist > epsilon3 {
            rotation = Math.face(target: .init(x: -inTanX, y: -inTanY))
        } else if outDist > epsilon3 {
            rotation = Math.face(target: .init(x: outTanX, y: outTanY))
        } else {
            isValidReading = false
        }
        
        if inDist > Math.epsilon {
            inDist = sqrtf(inDist)
        }
        
        if outDist > Math.epsilon {
            outDist = sqrtf(outDist)
        }
        
        tanMagnitudeInOriginal = inDist
        tanMagnitudeIn = inDist
        
        tanMagnitudeOut = outDist
        tanMagnitudeOutOriginal = outDist
        
        if isValidReading {
            tanDirectionOriginal = rotation
            tanDirection = rotation
            outTanDirXOriginal = sinf(rotation)
            outTanDirYOriginal = -cosf(rotation)
            inTanDirXOriginal = -outTanDirXOriginal
            inTanDirYOriginal = -outTanDirYOriginal
            
            self.inTanX = inTanDirXOriginal * tanMagnitudeInOriginal
            self.inTanY = inTanDirYOriginal * tanMagnitudeInOriginal
            self.outTanX = outTanDirXOriginal * tanMagnitudeOutOriginal
            self.outTanY = outTanDirYOriginal * tanMagnitudeOutOriginal
            
            isValid = true
        } else {
            tanDirectionOriginal = 0.0
            tanDirection = 0.0
            isValid = false
            self.inTanX = inTanX
            self.inTanY = inTanY
            self.outTanX = outTanX
            self.outTanY = outTanY
            
            
        }
    }
}
