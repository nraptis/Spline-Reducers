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
    case chopper(StochasticSplineReducerChopperCommandData)
}

struct StochasticSplineReducerChopperCommandData {
    let tolerance: Float
    let minimumStep: Int
    let maximumStep: Int
    let tryCount: Int
    let dupeOrInvalidRetryCount: Int
}

struct StochasticSplineReducerNeighborCommandData {
    let tolerance: Float
    let tryCount: Int
    let maxCombinedPouches: Int
}
