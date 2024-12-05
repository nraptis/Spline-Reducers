//
//  StochasticSplineReducerResponse.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 12/4/24.
//

import Foundation

enum StochasticSplineReducerResponse {
    case validNewBestMatch(Float)
    case complex
    case overweight
    case failure
}
