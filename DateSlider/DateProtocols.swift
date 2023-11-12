//
//  DateProtocols.swift
//  DateSlider
//
//  Created by Steven Harris on 11/8/23.
//

import Foundation
import OrderedCollections

/// DatedObject protocol enforces the existence of the `date` property on anything that conforms to it,
/// which also must conform to Equatable.
///
/// Note that Date is extended to conform to DatedObject, so DateSlider also accepts
/// both Array<Date> and OrderedSet<Date>.
public protocol DatedObject {
    var date: Date { get }
}

public extension DatedObject where Self: Equatable {
    
    static func == (lhs: any DatedObject, rhs: any DatedObject) -> Bool {
        lhs.date == rhs.date
    }
    
}

extension Date: DatedObject {
    var date: Date { self }
}

/// A DatedObjectCollection is any RandomAccessCollection (e.g., like Array or OrderedSet) that contains DatedObjects as
/// Elements and is indexed by Int.
///
/// The extensions allow the DateSlider to accept both Array<DatedObject> and OrderedSet<DatedObject> , and
/// by extension of Date to conform to DatedObject, also Array<Date> and OrderedSet<Date>.
protocol DatedObjectCollection: RandomAccessCollection where Element: DatedObject, Index == Int, SubSequence: RandomAccessCollection {
}

extension OrderedSet: DatedObjectCollection where Element: DatedObject, SubSequence == OrderedSet.SubSequence {}

extension OrderedSet.SubSequence: DatedObjectCollection where Element: DatedObject {}

extension Array: DatedObjectCollection where Element: DatedObject, SubSequence == ArraySlice<Element> {}

extension ArraySlice: DatedObjectCollection where Element: DatedObject {}
