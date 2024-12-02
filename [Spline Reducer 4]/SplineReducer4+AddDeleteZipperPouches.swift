//
//  SplineReducer4+AddDeleteZipperPouches.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension SplineReducer4 {
    
    func removeZipperPouch(_ zipperPouch: SplineReducer4ZipperPouch) {
        for checkIndex in 0..<zipperPouchCount {
            if zipperPouches[checkIndex] === zipperPouch {
                removeZipperPouch(checkIndex)
                return
            }
        }
    }
    
    func removeZipperPouch(_ index: Int) {
        if index >= 0 && index < zipperPouchCount {
            let zipperPouchCount1 = zipperPouchCount - 1
            var zipperPouchIndex = index
            while zipperPouchIndex < zipperPouchCount1 {
                zipperPouches[zipperPouchIndex] = zipperPouches[zipperPouchIndex + 1]
                zipperPouchIndex += 1
            }
            zipperPouchCount -= 1
        }
    }
    
    func addZipperPouch(_ zipperPouch: SplineReducer4ZipperPouch) {
        while zipperPouches.count <= zipperPouchCount {
            zipperPouches.append(zipperPouch)
        }
        zipperPouches[zipperPouchCount] = zipperPouch
        zipperPouchCount += 1
    }
    
    func purgeZipperPouches() {
        for zipperPouchIndex in 0..<zipperPouchCount {
            let zipperPouch = zipperPouches[zipperPouchIndex]
            SplineReducer4PartsFactory.shared.depositZipperPouch(zipperPouch)
        }
        zipperPouchCount = 0
    }
    
}
