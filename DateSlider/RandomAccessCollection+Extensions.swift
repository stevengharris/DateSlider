//
//  RandomAccessCollection+Extensions.swift
//  From: https://stackoverflow.com/a/35206907/8968411
//  DateSlider
//
//  Created by Steven Harris on 10/30/23.
//

import Foundation

extension RandomAccessCollection {
    
    public func bisectToFirstIndex(where predicate: (Element) throws -> Bool) rethrows -> Index? {
        var intervalStart = startIndex
        var intervalEnd = endIndex
        
        while intervalStart != intervalEnd {
            let intervalLength = distance(from: intervalStart, to: intervalEnd)
            
            guard intervalLength > 1 else {
                return try predicate(self[intervalStart]) ? intervalStart : nil
            }
            
            let testIndex = index(intervalStart, offsetBy: (intervalLength - 1) / 2)
            
            if try predicate(self[testIndex]) {
                intervalEnd = index(after: testIndex)
            }
            else {
                intervalStart = index(after: testIndex)
            }
        }
        
        return nil
    }
}
