//
//  SplineReducer5ControlPoint.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

class SplineReducer5ControlPoint {
    var x = Float(0.0)
    var y = Float(0.0)
    
    // This is false if:
    //  A.) the initial reading was false.
    //  B.) that's it, only that...
    var isValid = false
    
    // These will get used for the actual computtion... "compute"
    var inTanX = Float(0.0)
    var inTanY = Float(0.0)
    var outTanX = Float(0.0)
    var outTanY = Float(0.0)
    
    // These are stored to restore original state...
    var originalTanAngleIn = Float(0.0)
    var originalTanMagnitudeIn = Float(0.0)
    var originalTanDirectionInX = Float(0.0)
    var originalTanDirectionInY = Float(0.0)
    var originalTanAngleOut = Float(0.0)
    var originalTanMagnitudeOut = Float(0.0)
    var originalTanDirectionOutX = Float(0.0)
    var originalTanDirectionOutY = Float(0.0)
    var originalInTanX = Float(0.0)
    var originalInTanY = Float(0.0)
    var originalOutTanX = Float(0.0)
    var originalOutTanY = Float(0.0)
    
    var coefXC = Float(0.0)
    var coefXD = Float(0.0)
    var coefYC = Float(0.0)
    var coefYD = Float(0.0)
    
    func compute(nextControlPoint: SplineReducer5ControlPoint) {
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
    
    func readIn1(inTanX _inTanX: Float,
                inTanY _inTanY: Float,
                outTanX _outTanX: Float,
                outTanY _outTanY: Float) {
        
        originalInTanX = _inTanX
        originalInTanY = _inTanY
        originalOutTanX = _outTanX
        originalOutTanY = _outTanY
        
        inTanX = _inTanX
        inTanY = _inTanY
        outTanX = _outTanX
        outTanY = _outTanY
        
        var inDist = _inTanX * _inTanX + _inTanY * _inTanY
        var outDist = _outTanX * _outTanX + _outTanY * _outTanY
        
        let epsilon1 = Float(32.0 * 32.0)
        let epsilon2 = Float( 4.0 *  4.0)
        let epsilon3 = Float(0.1 * 0.1)
        
        var rotation = Float(0.0)
        var isValidReading = true
        
        if inDist > epsilon1 {
            rotation = Math.face(target: .init(x: -_inTanX, y: -_inTanY))
        } else if outDist > epsilon1 {
            rotation = Math.face(target: .init(x: _outTanX, y: _outTanY))
        } else if inDist > epsilon2 {
            rotation = Math.face(target: .init(x: -_inTanX, y: -_inTanY))
        } else if outDist > epsilon2 {
            rotation = Math.face(target: .init(x: _outTanX, y: _outTanY))
        } else if inDist > epsilon3 {
            rotation = Math.face(target: .init(x: -_inTanX, y: -_inTanY))
        } else if outDist > epsilon3 {
            rotation = Math.face(target: .init(x: _outTanX, y: _outTanY))
        } else {
            isValidReading = false
        }
        
        if inDist > Math.epsilon {
            inDist = sqrtf(inDist)
            originalTanMagnitudeIn = inDist
        } else {
            inDist = 0.0
            originalTanMagnitudeIn = 0.0
        }
        
        if outDist > Math.epsilon {
            outDist = sqrtf(outDist)
            originalTanMagnitudeOut = outDist
        } else {
            outDist = 0.0
            originalTanMagnitudeOut = 0.0
        }
        
        if isValidReading {
            originalTanAngleIn = rotation
            originalTanAngleOut = rotation
            originalTanDirectionOutX = sinf(rotation)
            originalTanDirectionOutY = -cosf(rotation)
            originalTanDirectionInX = -originalTanDirectionInX
            originalTanDirectionInY = -originalTanDirectionInY
            isValid = true
        } else {
            originalTanAngleIn = 0.0
            originalTanAngleOut = 0.0
            originalTanDirectionOutX = 0.0
            originalTanDirectionOutY = -1.0
            originalTanDirectionInX = 0.0
            originalTanDirectionInY = 1.0
            isValid = false
        }
    }
    
    func readIn2(inTanX _inTanX: Float,
                inTanY _inTanY: Float,
                outTanX _outTanX: Float,
                outTanY _outTanY: Float) {
        
        originalInTanX = _inTanX
        originalInTanY = _inTanY
        originalOutTanX = _outTanX
        originalOutTanY = _outTanY
        
        inTanX = _inTanX
        inTanY = _inTanY
        outTanX = _outTanX
        outTanY = _outTanY
        
        var inDist = _inTanX * _inTanX + _inTanY * _inTanY
        var outDist = _outTanX * _outTanX + _outTanY * _outTanY
        
        let epsilon1 = Float(32.0 * 32.0)
        let epsilon2 = Float( 4.0 *  4.0)
        let epsilon3 = Float(0.1 * 0.1)
        
        var rotation = Float(0.0)
        var isValidReading = true
        
        if inDist > epsilon1 {
            rotation = Math.face(target: .init(x: -_inTanX, y: -_inTanY))
        } else if outDist > epsilon1 {
            rotation = Math.face(target: .init(x: _outTanX, y: _outTanY))
        } else if inDist > epsilon2 {
            rotation = Math.face(target: .init(x: -_inTanX, y: -_inTanY))
        } else if outDist > epsilon2 {
            rotation = Math.face(target: .init(x: _outTanX, y: _outTanY))
        } else if inDist > epsilon3 {
            rotation = Math.face(target: .init(x: -_inTanX, y: -_inTanY))
        } else if outDist > epsilon3 {
            rotation = Math.face(target: .init(x: _outTanX, y: _outTanY))
        } else {
            isValidReading = false
        }
        
        if inDist > Math.epsilon {
            inDist = sqrtf(inDist)
            originalTanMagnitudeIn = inDist
        }
        
        
        if outDist > Math.epsilon {
            outDist = sqrtf(outDist)
            originalTanMagnitudeOut = outDist
        }
        
        if isValidReading {
            originalTanAngleIn = rotation
            originalTanAngleOut = rotation
            originalTanDirectionOutX = sinf(rotation)
            originalTanDirectionOutY = -cosf(rotation)
            originalTanDirectionInX = -originalTanDirectionInX
            originalTanDirectionInY = -originalTanDirectionInY
            isValid = true
        }
        
    }
}
