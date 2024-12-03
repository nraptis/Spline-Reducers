//
//  SplineReducer6+AddDeleteZipperPouches.swift
//  Jiggle3
//
//  Created by Nicky Taylor on 11/30/24.
//

import Foundation

extension SplineReducer6 {
    
    // @Precondition: index1 != index2
    // @Precondition: index1 in range 0..<zipperPouchCount
    // @Precondition: index2 in range 0..<zipperPouchCount
    // @Precondition: zipperPouchCount >= 2
    func removeZipperPouchTwo(index1: Int, index2: Int) {
        SplineReducer6PartsFactory.shared.depositZipperPouch(zipperPouches[index1])
        SplineReducer6PartsFactory.shared.depositZipperPouch(zipperPouches[index2])
        
        let lowerIndex = min(index1, index2)
        let higherIndex = max(index1, index2) - 1
        
        var zipperPouchIndex = lowerIndex
        while zipperPouchIndex < higherIndex {
            zipperPouches[zipperPouchIndex] = zipperPouches[zipperPouchIndex + 1]
            zipperPouchIndex += 1
        }
        
        let zipperPouchCount2 = zipperPouchCount - 2
        while zipperPouchIndex < zipperPouchCount2 {
            zipperPouches[zipperPouchIndex] = zipperPouches[zipperPouchIndex + 2]
            zipperPouchIndex += 1
        }
        zipperPouchCount -= 2
    }
    
    // @Precondition: index in range 0..<zipperPouchCount
    // @Precondition: zipperPouchCount >= 1
    func removeZipperPouchOne(index: Int) {
        SplineReducer6PartsFactory.shared.depositZipperPouch(zipperPouches[index])
        let zipperPouchCount1 = zipperPouchCount - 1
        var zipperPouchIndex = index
        while zipperPouchIndex < zipperPouchCount1 {
            zipperPouches[zipperPouchIndex] = zipperPouches[zipperPouchIndex + 1]
            zipperPouchIndex += 1
        }
        zipperPouchCount -= 1
    }
    
    func purgeZipperPouches() {
        for zipperPouchIndex in 0..<zipperPouchCount {
            let zipperPouch = zipperPouches[zipperPouchIndex]
            SplineReducer6PartsFactory.shared.depositZipperPouch(zipperPouch)
        }
        zipperPouchCount = 0
    }
    
    func addZipperPouch(zipperPouch: SplineReducer6ZipperPouch) {
        while zipperPouches.count <= zipperPouchCount {
            zipperPouches.append(zipperPouch)
        }
        zipperPouches[zipperPouchCount] = zipperPouch
        zipperPouchCount += 1
    }
    
    
    func addTempZipperPouch(zipperPouch: SplineReducer6ZipperPouch, zipperPouchIndex: Int) {
        while tempZipperPouches.count <= tempZipperPouchCount {
            tempZipperPouches.append(zipperPouch)
        }
        while tempZipperPouchIndices.count <= tempZipperPouchCount {
            tempZipperPouchIndices.append(zipperPouchIndex)
        }
        
        tempZipperPouches[tempZipperPouchCount] = zipperPouch
        tempZipperPouchIndices[tempZipperPouchCount] = zipperPouchIndex
        
        tempZipperPouchCount += 1
    }
    
}
