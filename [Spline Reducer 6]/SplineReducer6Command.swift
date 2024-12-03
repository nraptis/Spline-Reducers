//
//  SplineReducer6Command.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 12/3/24.
//

import Foundation

enum SplineReducer6Command {
    case reduceFrontAndBack(SplineReducer6CommandDataReduceNeighbors)
    case reduceBackOnly(SplineReducer6CommandDataReduceNeighbors)
}

struct SplineReducer6CommandDataReduceNeighbors {
    let tolerance: Float
    let tryCount: Int
    let maxCombinedPouches: Int
}
