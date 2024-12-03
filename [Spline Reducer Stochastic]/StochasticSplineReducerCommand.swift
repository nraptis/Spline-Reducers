//
//  StochasticSplineReducerCommand.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 12/3/24.
//

import Foundation

enum StochasticSplineReducerCommand {
    case reduceFrontAndBack(StochasticSplineReducerNeighborCommandData)
    case reduceBackOnly(StochasticSplineReducerNeighborCommandData)
}

struct StochasticSplineReducerNeighborCommandData {
    let tolerance: Float
    let tryCount: Int
    let maxCombinedPouches: Int
}
